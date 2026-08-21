import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:olu_ai/core/database/database.dart';
import 'package:olu_ai/features/visits/data/visit_repository.dart';

const _saharaFileUploadEndpoint =
    'https://infer.voice.intron.io/file/v1/upload';
const _saharaFileStatusEndpoint =
    'https://infer.voice.intron.io/file/v1/status';
const _defaultPollInterval = Duration(seconds: 2);
const _defaultMaxPollAttempts = 60;
const _pcmSampleRate = 16000;
const _pcmChannels = 1;
const _pcmBitsPerSample = 16;

class BenchmarkSyncSummary {
  final int attempted;
  final int synced;
  final int failed;
  final int skipped;

  const BenchmarkSyncSummary({
    required this.attempted,
    required this.synced,
    required this.failed,
    required this.skipped,
  });
}

class SaharaBenchmarkException implements Exception {
  final String message;
  final Object? cause;

  const SaharaBenchmarkException(this.message, [this.cause]);

  @override
  String toString() => cause == null
      ? 'SaharaBenchmarkException: $message'
      : 'SaharaBenchmarkException: $message ($cause)';
}

class BenchmarkSyncWorker {
  BenchmarkSyncWorker({
    required VisitRepository visitRepository,
    http.Client? httpClient,
    Connectivity? connectivity,
    Duration pollInterval = _defaultPollInterval,
    int maxPollAttempts = _defaultMaxPollAttempts,
  })  : _visitRepository = visitRepository,
        _httpClient = httpClient ?? http.Client(),
        _connectivity = connectivity ?? Connectivity(),
        _pollInterval = pollInterval,
        _maxPollAttempts = maxPollAttempts;

  final VisitRepository _visitRepository;
  final http.Client _httpClient;
  final Connectivity _connectivity;
  final Duration _pollInterval;
  final int _maxPollAttempts;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  Future<void> startAutoSync({
    required String saharaApiKey,
  }) async {
    final apiKey = saharaApiKey.trim();
    if (apiKey.isEmpty || _connectivitySubscription != null) return;

    if (await _hasNetworkConnection()) {
      unawaited(syncPending(saharaApiKey: apiKey));
    }

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        if (_hasAnyNetworkConnection(results)) {
          unawaited(syncPending(saharaApiKey: apiKey));
        }
      },
    );
  }

  Future<BenchmarkSyncSummary> syncPending({
    required String saharaApiKey,
  }) async {
    if (_isSyncing) {
      return const BenchmarkSyncSummary(
        attempted: 0,
        synced: 0,
        failed: 0,
        skipped: 0,
      );
    }

    final apiKey = saharaApiKey.trim();
    if (apiKey.isEmpty || !await _hasNetworkConnection()) {
      return const BenchmarkSyncSummary(
        attempted: 0,
        synced: 0,
        failed: 0,
        skipped: 0,
      );
    }

    _isSyncing = true;
    var attempted = 0;
    var synced = 0;
    var failed = 0;
    var skipped = 0;

    try {
      final visits = await _visitRepository.getPendingBenchmarkVisits();
      for (final visit in visits) {
        if (!_shouldBenchmark(visit)) {
          skipped++;
          await _visitRepository.updateBenchmarkSyncStatus(
            visitId: visit.id,
            status: benchmarkStatusNotApplicable,
          );
          continue;
        }

        attempted++;
        try {
          await _syncVisit(visit: visit, apiKey: apiKey);
          synced++;
        } catch (error) {
          failed++;
          await _markFailed(visit, error);
        }
      }
    } finally {
      _isSyncing = false;
    }

    return BenchmarkSyncSummary(
      attempted: attempted,
      synced: synced,
      failed: failed,
      skipped: skipped,
    );
  }

  void dispose() {
    unawaited(_connectivitySubscription?.cancel());
    _httpClient.close();
  }

  bool _shouldBenchmark(Visit visit) {
    return visit.asrSource == asrSourceSherpaLocal ||
        visit.asrSource == asrSourceMixed;
  }

  Future<void> _syncVisit({
    required Visit visit,
    required String apiKey,
  }) async {
    final audioPath = visit.audioPath;
    if (audioPath == null || audioPath.isEmpty) {
      throw const SaharaBenchmarkException('Visit has no recorded audio path.');
    }

    final uploadFile = await _prepareUploadFile(File(audioPath), visit.id);
    final startedAt = DateTime.now();
    final fileId = await _uploadAudioFile(
      file: uploadFile,
      visit: visit,
      apiKey: apiKey,
    );
    final transcript = await _pollForTranscript(fileId: fileId, apiKey: apiKey);
    final completedAt = DateTime.now();

    await _visitRepository.addTranscription(TranscriptionsCompanion.insert(
      visitId: visit.id,
      source: transcriptionSourceSaharaBenchmark,
      transcript: transcript,
      languageCode: Value(visit.languageCode),
      completedAt: completedAt,
      processingLatencyMs:
          Value(completedAt.difference(startedAt).inMilliseconds),
      usedForClinicalPipeline: false,
    ));
    await _visitRepository.updateBenchmarkSyncStatus(
      visitId: visit.id,
      status: benchmarkStatusSynced,
    );
  }

  Future<File> _prepareUploadFile(File sourceFile, int visitId) async {
    if (!await sourceFile.exists()) {
      throw SaharaBenchmarkException(
        'Recorded audio file does not exist.',
        sourceFile.path,
      );
    }

    final extension = p.extension(sourceFile.path).toLowerCase();
    if (extension == '.pcm') {
      return _wrapPcmAsWav(sourceFile, visitId);
    }

    const supportedExtensions = {
      '.wav',
      '.mp3',
      '.mp4',
      '.m4a',
      '.ogg',
      '.webm',
      '.flac',
    };
    if (!supportedExtensions.contains(extension)) {
      throw SaharaBenchmarkException('Unsupported audio format: $extension');
    }

    return sourceFile;
  }

  Future<File> _wrapPcmAsWav(File pcmFile, int visitId) async {
    final pcmBytes = await pcmFile.readAsBytes();
    final directory = await getTemporaryDirectory();
    final wavFile = File(p.join(directory.path, 'visit_$visitId.wav'));
    await wavFile.writeAsBytes(_buildWavBytes(pcmBytes), flush: true);
    return wavFile;
  }

  Uint8List _buildWavBytes(Uint8List pcmBytes) {
    final byteRate = _pcmSampleRate * _pcmChannels * _pcmBitsPerSample ~/ 8;
    final blockAlign = _pcmChannels * _pcmBitsPerSample ~/ 8;
    final bytes = Uint8List(44 + pcmBytes.length);
    final data = ByteData.sublistView(bytes);

    bytes.setRange(0, 4, ascii.encode('RIFF'));
    data.setUint32(4, 36 + pcmBytes.length, Endian.little);
    bytes.setRange(8, 12, ascii.encode('WAVE'));
    bytes.setRange(12, 16, ascii.encode('fmt '));
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, _pcmChannels, Endian.little);
    data.setUint32(24, _pcmSampleRate, Endian.little);
    data.setUint32(28, byteRate, Endian.little);
    data.setUint16(32, blockAlign, Endian.little);
    data.setUint16(34, _pcmBitsPerSample, Endian.little);
    bytes.setRange(36, 40, ascii.encode('data'));
    data.setUint32(40, pcmBytes.length, Endian.little);
    bytes.setRange(44, bytes.length, pcmBytes);
    return bytes;
  }

  Future<String> _uploadAudioFile({
    required File file,
    required Visit visit,
    required String apiKey,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_saharaFileUploadEndpoint),
    )
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['audio_file_name'] = p.basename(file.path)
      ..fields['use_language_asr_input'] = visit.languageCode
      ..files.add(await http.MultipartFile.fromPath(
        'audio_file_blob',
        file.path,
      ));

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SaharaBenchmarkException(
        'Sahara upload failed with HTTP ${response.statusCode}.',
        response.body,
      );
    }

    final data = _decodeJsonObject(response.body);
    final fileId = _extractString(data, const ['file_id', 'fileId', 'id']);
    if (fileId == null || fileId.isEmpty) {
      throw SaharaBenchmarkException(
        'Sahara upload response did not include a file id.',
        response.body,
      );
    }
    return fileId;
  }

  Future<String> _pollForTranscript({
    required String fileId,
    required String apiKey,
  }) async {
    for (var attempt = 0; attempt < _maxPollAttempts; attempt++) {
      final response = await _httpClient.get(
        Uri.parse('$_saharaFileStatusEndpoint/$fileId'),
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      if (response.statusCode == 429) {
        await Future<void>.delayed(_retryAfter(response) ?? _pollInterval);
        continue;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SaharaBenchmarkException(
          'Sahara status poll failed with HTTP ${response.statusCode}.',
          response.body,
        );
      }

      final data = _decodeJsonObject(response.body);
      final status = _extractString(data, const ['status', 'state']);
      if (status == 'FILE_TRANSCRIBED') {
        final transcript = _extractTranscript(data);
        if (transcript == null || transcript.isEmpty) {
          throw SaharaBenchmarkException(
            'Sahara completed without a transcript.',
            response.body,
          );
        }
        return transcript;
      }

      if (status == 'FILE_PROCESSING_FAILED') {
        throw SaharaBenchmarkException('Sahara file processing failed.', data);
      }

      await Future<void>.delayed(_retryAfter(response) ?? _pollInterval);
    }

    throw SaharaBenchmarkException(
      'Sahara transcription did not complete after $_maxPollAttempts polls.',
    );
  }

  Future<void> _markFailed(Visit visit, Object error) async {
    await _visitRepository.addTranscription(TranscriptionsCompanion.insert(
      visitId: visit.id,
      source: transcriptionSourceSaharaBenchmark,
      transcript: '',
      languageCode: Value(visit.languageCode),
      completedAt: DateTime.now(),
      errorMessage: Value(error.toString()),
      usedForClinicalPipeline: false,
    ));
    await _visitRepository.updateBenchmarkSyncStatus(
      visitId: visit.id,
      status: benchmarkStatusFailed,
    );
  }

  Future<bool> _hasNetworkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _hasAnyNetworkConnection(results);
  }

  bool _hasAnyNetworkConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    final value = jsonDecode(body);
    if (value is Map<String, dynamic>) return value;
    throw SaharaBenchmarkException('Expected JSON object.', body);
  }

  String? _extractTranscript(Map<String, dynamic> data) {
    for (final key in const ['transcript', 'text', 'result']) {
      final value = data[key];
      if (value is String) return value;
    }

    final result = data['result'];
    if (result is Map<String, dynamic>) {
      return _extractString(result, const ['transcript', 'text']);
    }
    return null;
  }

  String? _extractString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String) return value;
    }
    return null;
  }

  Duration? _retryAfter(http.Response response) {
    final header = response.headers['retry-after'];
    if (header == null) return null;

    final seconds = int.tryParse(header);
    if (seconds != null) return Duration(seconds: seconds);

    final retryAt = HttpDate.parse(header);
    final delay = retryAt.difference(DateTime.now().toUtc());
    return delay.isNegative ? Duration.zero : delay;
  }
}

final benchmarkSyncWorkerProvider = Provider<BenchmarkSyncWorker>((ref) {
  final worker = BenchmarkSyncWorker(
    visitRepository: VisitRepository(ref.watch(databaseProvider)),
  );
  ref.onDispose(worker.dispose);
  return worker;
});
