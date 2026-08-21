import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

const sourceSherpaLocal = 'sherpa_local';
const sourceSaharaBenchmark = 'sahara_v2_benchmark';
const sourceWhisper = 'whisper_api';

const _saharaFileUploadEndpoint =
    'https://infer.voice.intron.io/file/v1/upload';
const _saharaFileStatusEndpoint =
    'https://infer.voice.intron.io/file/v1/status';
const _openAiTranscriptionEndpoint =
    'https://api.openai.com/v1/audio/transcriptions';

Future<void> main(List<String> args) async {
  final options = BenchmarkRunnerOptions.parse(args, Platform.environment);
  if (options.showHelp) {
    stdout.writeln(BenchmarkRunnerOptions.usage);
    return;
  }

  final runner = BenchmarkRunner(options: options);
  final report = await runner.run();
  stdout.writeln(
    'Exported ${report.rows.length} benchmark rows to ${report.csvPath} and ${report.jsonPath}.',
  );
  for (final warning in report.warnings) {
    stderr.writeln('warning: $warning');
  }
}

class BenchmarkRunnerOptions {
  final String? databasePath;
  final String? clipsPath;
  final String outputDirectory;
  final String? saharaApiKey;
  final String? openAiApiKey;
  final String? sherpaCommand;
  final bool requireThirdModel;
  final bool showHelp;

  const BenchmarkRunnerOptions({
    this.databasePath,
    this.clipsPath,
    this.outputDirectory = 'benchmark/results',
    this.saharaApiKey,
    this.openAiApiKey,
    this.sherpaCommand,
    this.requireThirdModel = false,
    this.showHelp = false,
  });

  factory BenchmarkRunnerOptions.parse(
    List<String> args, [
    Map<String, String> environment = const {},
  ]) {
    String? readValue(String option, int index) {
      final prefix = '$option=';
      final current = args[index];
      if (current.startsWith(prefix)) return current.substring(prefix.length);
      if (current == option && index + 1 < args.length) return args[index + 1];
      return null;
    }

    var outputDirectory = 'benchmark/results';
    String? databasePath;
    String? clipsPath;
    String? saharaApiKey = environment['SAHARA_API_KEY'];
    String? openAiApiKey = environment['OPENAI_API_KEY'];
    String? sherpaCommand;
    var requireThirdModel = false;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '--help' || arg == '-h') {
        return const BenchmarkRunnerOptions(showHelp: true);
      }
      if (arg == '--require-third-model') {
        requireThirdModel = true;
        continue;
      }

      final databaseValue = readValue('--database', i);
      final clipsValue = readValue('--clips', i);
      final outputValue = readValue('--out', i);
      final saharaValue = readValue('--sahara-api-key', i);
      final openAiValue = readValue('--openai-api-key', i);
      final sherpaValue = readValue('--sherpa-command', i);

      if (databaseValue != null) {
        databasePath = databaseValue;
      } else if (clipsValue != null) {
        clipsPath = clipsValue;
      } else if (outputValue != null) {
        outputDirectory = outputValue;
      } else if (saharaValue != null) {
        saharaApiKey = saharaValue;
      } else if (openAiValue != null) {
        openAiApiKey = openAiValue;
      } else if (sherpaValue != null) {
        sherpaCommand = sherpaValue;
      }

      if (!arg.contains('=') && _optionsWithValues.contains(arg)) i++;
    }

    return BenchmarkRunnerOptions(
      databasePath: databasePath,
      clipsPath: clipsPath,
      outputDirectory: outputDirectory,
      saharaApiKey: _blankToNull(saharaApiKey),
      openAiApiKey: _blankToNull(openAiApiKey),
      sherpaCommand: _blankToNull(sherpaCommand),
      requireThirdModel: requireThirdModel,
    );
  }

  static const _optionsWithValues = {
    '--database',
    '--clips',
    '--out',
    '--sahara-api-key',
    '--openai-api-key',
    '--sherpa-command',
  };

  static const usage = '''
Usage:
  dart run tool/benchmark_runner.dart \\
    --database /path/to/db.sqlite \\
    --clips benchmark/clips.json \\
    --out benchmark/results \\
    --openai-api-key <key>

Inputs:
  --database           Optional Olu AI SQLite database. Rows are exported only
                       when both sherpa_local and sahara_v2_benchmark transcripts exist.
  --clips              Optional held-out benchmark manifest JSON.
  --out                Output directory. Defaults to benchmark/results.
  --sahara-api-key     Sahara key. Defaults to SAHARA_API_KEY.
  --openai-api-key     Whisper API key. Defaults to OPENAI_API_KEY.
  --sherpa-command     Optional local command for missing Sherpa transcripts.
                       Use {audio} as a placeholder for the audio path.
  --require-third-model Fails if no Whisper row can be produced for a clip.

Manifest shape:
  {
    "clips": [
      {
        "clipId": "clip-001",
        "visitId": 12,
        "audioPath": "benchmark/audio/clip-001.wav",
        "referenceTranscript": "hand transcribed text",
        "languagePair": "sw-en",
        "accentRegion": "Nairobi",
        "noiseLevel": "clinic",
        "device": "Pixel 7",
        "captureMode": "offline",
        "sherpaTranscript": "optional precomputed text",
        "saharaTranscript": "optional precomputed text",
        "whisperTranscript": "optional precomputed text"
      }
    ]
  }
''';
}

class BenchmarkRunner {
  final BenchmarkRunnerOptions options;
  final http.Client _httpClient;

  BenchmarkRunner({
    required this.options,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Future<BenchmarkReport> run() async {
    final warnings = <String>[];
    final clips = await _loadClipManifest(options.clipsPath);
    final clipsByVisitId = {
      for (final clip in clips.where((clip) => clip.visitId != null))
        clip.visitId!: clip,
    };
    final rows = <BenchmarkExportRow>[];
    final emitted = <String>{};

    if (options.databasePath != null) {
      rows.addAll(_loadDatabaseRows(
        databasePath: options.databasePath!,
        referencesByVisitId: clipsByVisitId,
        warnings: warnings,
      ));
      emitted.addAll(rows.map((row) => '${row.clipId}:${row.model}'));
    }

    for (final clip in clips) {
      final candidates = await _transcriptsForClip(clip, warnings);
      for (final candidate in candidates) {
        final key = '${clip.clipId}:${candidate.model}';
        if (!emitted.add(key)) continue;
        rows.add(BenchmarkExportRow.fromCandidate(clip, candidate));
      }
    }

    final whisperClipIds = rows
        .where((row) => row.model == sourceWhisper)
        .map((row) => row.clipId)
        .toSet();
    if (options.requireThirdModel) {
      final missing = clips
          .where((clip) => !whisperClipIds.contains(clip.clipId))
          .map((clip) => clip.clipId)
          .toList();
      if (missing.isNotEmpty) {
        throw BenchmarkRunnerException(
          'Missing Whisper baseline rows for: ${missing.join(', ')}',
        );
      }
    } else if (clips.isNotEmpty && whisperClipIds.length < clips.length) {
      warnings.add(
        'Whisper baseline missing for ${clips.length - whisperClipIds.length} clip(s). '
        'Provide whisperTranscript values, OPENAI_API_KEY, or --openai-api-key.',
      );
    }

    final outputDirectory = Directory(options.outputDirectory);
    await outputDirectory.create(recursive: true);
    final csvPath = p.join(outputDirectory.path, 'asr_benchmark.csv');
    final jsonPath = p.join(outputDirectory.path, 'asr_benchmark.json');
    await File(csvPath).writeAsString(toCsv(rows));
    await File(jsonPath).writeAsString(toPrettyJson(rows));
    return BenchmarkReport(
      rows: rows,
      csvPath: csvPath,
      jsonPath: jsonPath,
      warnings: warnings,
    );
  }

  void close() {
    _httpClient.close();
  }

  List<BenchmarkExportRow> _loadDatabaseRows({
    required String databasePath,
    required Map<int, ClipMetadata> referencesByVisitId,
    required List<String> warnings,
  }) {
    final databaseFile = File(databasePath);
    if (!databaseFile.existsSync()) {
      throw BenchmarkRunnerException('Database does not exist: $databasePath');
    }

    final database = sqlite3.open(databasePath);
    try {
      final result = database.select('''
        SELECT
          v.id AS visit_id,
          v.audio_path AS audio_path,
          v.language_code AS language_code,
          MAX(CASE WHEN t.source = ? THEN t.transcript END) AS sherpa_transcript,
          MAX(CASE WHEN t.source = ? THEN t.transcript END) AS sahara_transcript,
          MAX(CASE WHEN t.source = ? THEN t.processing_latency_ms END) AS sahara_latency_ms
        FROM visits v
        INNER JOIN transcriptions t ON t.visit_id = v.id
        GROUP BY v.id
        HAVING sherpa_transcript IS NOT NULL
          AND sahara_transcript IS NOT NULL
          AND LENGTH(sherpa_transcript) > 0
          AND LENGTH(sahara_transcript) > 0
      ''', [sourceSherpaLocal, sourceSaharaBenchmark, sourceSaharaBenchmark]);

      final rows = <BenchmarkExportRow>[];
      for (final row in result) {
        final visitId = row['visit_id'] as int;
        final clip = referencesByVisitId[visitId];
        if (clip == null) {
          warnings.add(
            'Visit $visitId has both stored transcripts but no hand reference in the clip manifest.',
          );
          continue;
        }

        final audioPath = row['audio_path'] as String? ?? clip.audioPath;
        final languagePair =
            clip.languagePair ?? row['language_code'] as String?;
        final enrichedClip = clip.copyWith(
          audioPath: audioPath,
          languagePair: languagePair,
        );
        rows
          ..add(BenchmarkExportRow.fromCandidate(
            enrichedClip,
            TranscriptCandidate(
              model: sourceSherpaLocal,
              transcript: row['sherpa_transcript'] as String,
            ),
          ))
          ..add(BenchmarkExportRow.fromCandidate(
            enrichedClip,
            TranscriptCandidate(
              model: sourceSaharaBenchmark,
              transcript: row['sahara_transcript'] as String,
              latencyMs: row['sahara_latency_ms'] as int?,
            ),
          ));
      }
      return rows;
    } finally {
      database.dispose();
    }
  }

  Future<List<TranscriptCandidate>> _transcriptsForClip(
    ClipMetadata clip,
    List<String> warnings,
  ) async {
    final candidates = <TranscriptCandidate>[];
    final sherpaTranscript = clip.transcriptFor(sourceSherpaLocal);
    if (sherpaTranscript != null) {
      candidates.add(TranscriptCandidate(
        model: sourceSherpaLocal,
        transcript: sherpaTranscript,
        latencyMs: clip.latencyFor(sourceSherpaLocal),
      ));
    } else if (options.sherpaCommand != null && clip.audioPath != null) {
      candidates.add(await _runSherpaCommand(clip));
    }

    final saharaTranscript = clip.transcriptFor(sourceSaharaBenchmark);
    if (saharaTranscript != null) {
      candidates.add(TranscriptCandidate(
        model: sourceSaharaBenchmark,
        transcript: saharaTranscript,
        latencyMs: clip.latencyFor(sourceSaharaBenchmark),
      ));
    } else if (options.saharaApiKey != null && clip.audioPath != null) {
      candidates.add(await _runSaharaFileUpload(clip));
    }

    final whisperTranscript = clip.transcriptFor(sourceWhisper);
    if (whisperTranscript != null) {
      candidates.add(TranscriptCandidate(
        model: sourceWhisper,
        transcript: whisperTranscript,
        latencyMs: clip.latencyFor(sourceWhisper),
      ));
    } else if (options.openAiApiKey != null && clip.audioPath != null) {
      candidates.add(await _runWhisper(clip));
    }

    if (candidates.isEmpty) {
      warnings.add('No transcripts available for clip ${clip.clipId}.');
    }
    return candidates;
  }

  Future<TranscriptCandidate> _runSherpaCommand(ClipMetadata clip) async {
    final audioPath = clip.audioPath;
    if (audioPath == null) {
      throw BenchmarkRunnerException('Clip ${clip.clipId} has no audioPath.');
    }

    final command = options.sherpaCommand!.contains('{audio}')
        ? options.sherpaCommand!.replaceAll('{audio}', _shellQuote(audioPath))
        : '${options.sherpaCommand!} ${_shellQuote(audioPath)}';
    final startedAt = DateTime.now();
    final result = await Process.run('/bin/sh', ['-c', command]);
    final completedAt = DateTime.now();
    if (result.exitCode != 0) {
      throw BenchmarkRunnerException(
        'Sherpa command failed for ${clip.clipId}: ${result.stderr}',
      );
    }
    return TranscriptCandidate(
      model: sourceSherpaLocal,
      transcript: result.stdout.toString().trim(),
      latencyMs: completedAt.difference(startedAt).inMilliseconds,
    );
  }

  Future<TranscriptCandidate> _runSaharaFileUpload(ClipMetadata clip) async {
    final audioPath = clip.audioPath;
    if (audioPath == null) {
      throw BenchmarkRunnerException('Clip ${clip.clipId} has no audioPath.');
    }

    final startedAt = DateTime.now();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_saharaFileUploadEndpoint),
    )
      ..headers['Authorization'] = 'Bearer ${options.saharaApiKey}'
      ..fields['audio_file_name'] = p.basename(audioPath)
      ..fields['use_language_asr_input'] = clip.languagePair ?? 'sw'
      ..files
          .add(await http.MultipartFile.fromPath('audio_file_blob', audioPath));

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BenchmarkRunnerException(
        'Sahara upload failed for ${clip.clipId} with HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final fileId = _extractString(_decodeObject(response.body), const [
      'file_id',
      'fileId',
      'id',
    ]);
    if (fileId == null || fileId.isEmpty) {
      throw BenchmarkRunnerException('Sahara upload returned no file id.');
    }

    final transcript = await _pollSahara(fileId, clip.clipId);
    final completedAt = DateTime.now();
    return TranscriptCandidate(
      model: sourceSaharaBenchmark,
      transcript: transcript,
      latencyMs: completedAt.difference(startedAt).inMilliseconds,
    );
  }

  Future<String> _pollSahara(String fileId, String clipId) async {
    for (var attempt = 0; attempt < 60; attempt++) {
      final response = await _httpClient.get(
        Uri.parse('$_saharaFileStatusEndpoint/$fileId'),
        headers: {'Authorization': 'Bearer ${options.saharaApiKey}'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BenchmarkRunnerException(
          'Sahara poll failed for $clipId with HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final data = _decodeObject(response.body);
      final status = _extractString(data, const ['status', 'state']);
      if (status == 'FILE_TRANSCRIBED') {
        final transcript = _extractTranscript(data);
        if (transcript == null || transcript.isEmpty) {
          throw BenchmarkRunnerException(
              'Sahara returned an empty transcript.');
        }
        return transcript;
      }
      if (status == 'FILE_PROCESSING_FAILED') {
        throw BenchmarkRunnerException('Sahara processing failed for $clipId.');
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    throw BenchmarkRunnerException('Sahara polling timed out for $clipId.');
  }

  Future<TranscriptCandidate> _runWhisper(ClipMetadata clip) async {
    final audioPath = clip.audioPath;
    if (audioPath == null) {
      throw BenchmarkRunnerException('Clip ${clip.clipId} has no audioPath.');
    }

    final startedAt = DateTime.now();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_openAiTranscriptionEndpoint),
    )
      ..headers['Authorization'] = 'Bearer ${options.openAiApiKey}'
      ..fields['model'] = 'whisper-1'
      ..files.add(await http.MultipartFile.fromPath('file', audioPath));

    final response =
        await http.Response.fromStream(await _httpClient.send(request));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BenchmarkRunnerException(
        'Whisper failed for ${clip.clipId} with HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final transcript =
        _extractString(_decodeObject(response.body), const ['text']);
    if (transcript == null || transcript.isEmpty) {
      throw BenchmarkRunnerException('Whisper returned an empty transcript.');
    }
    final completedAt = DateTime.now();
    return TranscriptCandidate(
      model: sourceWhisper,
      transcript: transcript,
      latencyMs: completedAt.difference(startedAt).inMilliseconds,
    );
  }
}

class ClipMetadata {
  final String clipId;
  final int? visitId;
  final String? audioPath;
  final String referenceTranscript;
  final String? languagePair;
  final String? accentRegion;
  final String? noiseLevel;
  final String? device;
  final String? captureMode;
  final Map<String, Object?> raw;

  const ClipMetadata({
    required this.clipId,
    required this.referenceTranscript,
    this.visitId,
    this.audioPath,
    this.languagePair,
    this.accentRegion,
    this.noiseLevel,
    this.device,
    this.captureMode,
    this.raw = const {},
  });

  factory ClipMetadata.fromJson(Map<String, Object?> json) {
    final clipId = _stringValue(json, const ['clipId', 'clip_id', 'id']);
    if (clipId == null || clipId.isEmpty) {
      throw BenchmarkRunnerException('Clip is missing clipId.');
    }

    final referenceTranscript = _stringValue(json, const [
          'referenceTranscript',
          'reference_transcript',
          'reference',
        ]) ??
        _readTextPath(_stringValue(json, const [
          'referenceTranscriptPath',
          'reference_transcript_path',
          'referencePath',
        ]));
    if (referenceTranscript == null || referenceTranscript.trim().isEmpty) {
      throw BenchmarkRunnerException(
        'Clip $clipId is missing a hand-transcribed reference.',
      );
    }

    return ClipMetadata(
      clipId: clipId,
      visitId: _intValue(json['visitId'] ?? json['visit_id']),
      audioPath: _stringValue(json, const ['audioPath', 'audio_path']),
      referenceTranscript: referenceTranscript,
      languagePair: _stringValue(json, const ['languagePair', 'language_pair']),
      accentRegion: _stringValue(json, const ['accentRegion', 'accent_region']),
      noiseLevel: _stringValue(json, const ['noiseLevel', 'noise_level']),
      device: _stringValue(json, const ['device']),
      captureMode: _stringValue(json, const ['captureMode', 'capture_mode']),
      raw: json,
    );
  }

  ClipMetadata copyWith({
    String? audioPath,
    String? languagePair,
  }) {
    return ClipMetadata(
      clipId: clipId,
      visitId: visitId,
      audioPath: audioPath ?? this.audioPath,
      referenceTranscript: referenceTranscript,
      languagePair: languagePair ?? this.languagePair,
      accentRegion: accentRegion,
      noiseLevel: noiseLevel,
      device: device,
      captureMode: captureMode,
      raw: raw,
    );
  }

  String? transcriptFor(String source) {
    return switch (source) {
      sourceSherpaLocal => _stringValue(raw, const [
            'sherpaTranscript',
            'sherpa_transcript',
          ]) ??
          _readTextPath(_stringValue(raw, const [
            'sherpaTranscriptPath',
            'sherpa_transcript_path',
          ])),
      sourceSaharaBenchmark => _stringValue(raw, const [
            'saharaTranscript',
            'sahara_transcript',
          ]) ??
          _readTextPath(_stringValue(raw, const [
            'saharaTranscriptPath',
            'sahara_transcript_path',
          ])),
      sourceWhisper => _stringValue(raw, const [
            'whisperTranscript',
            'whisper_transcript',
          ]) ??
          _readTextPath(_stringValue(raw, const [
            'whisperTranscriptPath',
            'whisper_transcript_path',
          ])),
      _ => null,
    };
  }

  int? latencyFor(String source) {
    final value = switch (source) {
      sourceSherpaLocal => raw['sherpaLatencyMs'] ?? raw['sherpa_latency_ms'],
      sourceSaharaBenchmark =>
        raw['saharaLatencyMs'] ?? raw['sahara_latency_ms'],
      sourceWhisper => raw['whisperLatencyMs'] ?? raw['whisper_latency_ms'],
      _ => null,
    };
    return _intValue(value);
  }
}

class TranscriptCandidate {
  final String model;
  final String transcript;
  final int? latencyMs;

  const TranscriptCandidate({
    required this.model,
    required this.transcript,
    this.latencyMs,
  });
}

class BenchmarkExportRow {
  final String clipId;
  final int? visitId;
  final String model;
  final double wer;
  final int substitutions;
  final int insertions;
  final int deletions;
  final int referenceWordCount;
  final int? latencyMs;
  final String? languagePair;
  final String? accentRegion;
  final String? noiseLevel;
  final String? device;
  final String? captureMode;
  final String referenceTranscript;
  final String hypothesisTranscript;

  const BenchmarkExportRow({
    required this.clipId,
    required this.model,
    required this.wer,
    required this.substitutions,
    required this.insertions,
    required this.deletions,
    required this.referenceWordCount,
    required this.referenceTranscript,
    required this.hypothesisTranscript,
    this.visitId,
    this.latencyMs,
    this.languagePair,
    this.accentRegion,
    this.noiseLevel,
    this.device,
    this.captureMode,
  });

  factory BenchmarkExportRow.fromCandidate(
    ClipMetadata clip,
    TranscriptCandidate candidate,
  ) {
    final wer = computeWer(clip.referenceTranscript, candidate.transcript);
    return BenchmarkExportRow(
      clipId: clip.clipId,
      visitId: clip.visitId,
      model: candidate.model,
      wer: wer.rate,
      substitutions: wer.substitutions,
      insertions: wer.insertions,
      deletions: wer.deletions,
      referenceWordCount: wer.referenceWordCount,
      latencyMs: candidate.latencyMs,
      languagePair: clip.languagePair,
      accentRegion: clip.accentRegion,
      noiseLevel: clip.noiseLevel,
      device: clip.device,
      captureMode: clip.captureMode,
      referenceTranscript: clip.referenceTranscript,
      hypothesisTranscript: candidate.transcript,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'clip_id': clipId,
      'visit_id': visitId,
      'model': model,
      'wer': wer,
      'substitutions': substitutions,
      'insertions': insertions,
      'deletions': deletions,
      'reference_word_count': referenceWordCount,
      'latency_ms': latencyMs,
      'language_pair': languagePair,
      'accent_region': accentRegion,
      'noise_level': noiseLevel,
      'device': device,
      'capture_mode': captureMode,
      'reference_transcript': referenceTranscript,
      'hypothesis_transcript': hypothesisTranscript,
    };
  }
}

class BenchmarkReport {
  final List<BenchmarkExportRow> rows;
  final String csvPath;
  final String jsonPath;
  final List<String> warnings;

  const BenchmarkReport({
    required this.rows,
    required this.csvPath,
    required this.jsonPath,
    required this.warnings,
  });
}

class WerStats {
  final int substitutions;
  final int insertions;
  final int deletions;
  final int referenceWordCount;

  const WerStats({
    required this.substitutions,
    required this.insertions,
    required this.deletions,
    required this.referenceWordCount,
  });

  double get rate {
    if (referenceWordCount == 0) {
      return insertions == 0 ? 0 : 1;
    }
    return (substitutions + insertions + deletions) / referenceWordCount;
  }
}

class BenchmarkRunnerException implements Exception {
  final String message;

  const BenchmarkRunnerException(this.message);

  @override
  String toString() => 'BenchmarkRunnerException: $message';
}

WerStats computeWer(String reference, String hypothesis) {
  final referenceWords = _tokenize(reference);
  final hypothesisWords = _tokenize(hypothesis);
  final rows = referenceWords.length + 1;
  final columns = hypothesisWords.length + 1;
  final cost = List.generate(rows, (_) => List.filled(columns, 0));

  for (var i = 0; i < rows; i++) {
    cost[i][0] = i;
  }
  for (var j = 0; j < columns; j++) {
    cost[0][j] = j;
  }

  for (var i = 1; i < rows; i++) {
    for (var j = 1; j < columns; j++) {
      if (referenceWords[i - 1] == hypothesisWords[j - 1]) {
        cost[i][j] = cost[i - 1][j - 1];
      } else {
        cost[i][j] = 1 +
            math.min(
              cost[i - 1][j - 1],
              math.min(cost[i - 1][j], cost[i][j - 1]),
            );
      }
    }
  }

  var i = referenceWords.length;
  var j = hypothesisWords.length;
  var substitutions = 0;
  var insertions = 0;
  var deletions = 0;

  while (i > 0 || j > 0) {
    if (i > 0 &&
        j > 0 &&
        referenceWords[i - 1] == hypothesisWords[j - 1] &&
        cost[i][j] == cost[i - 1][j - 1]) {
      i--;
      j--;
    } else if (i > 0 && j > 0 && cost[i][j] == cost[i - 1][j - 1] + 1) {
      substitutions++;
      i--;
      j--;
    } else if (j > 0 && cost[i][j] == cost[i][j - 1] + 1) {
      insertions++;
      j--;
    } else {
      deletions++;
      i--;
    }
  }

  return WerStats(
    substitutions: substitutions,
    insertions: insertions,
    deletions: deletions,
    referenceWordCount: referenceWords.length,
  );
}

String toCsv(List<BenchmarkExportRow> rows) {
  final buffer = StringBuffer();
  const headers = [
    'clip_id',
    'visit_id',
    'model',
    'wer',
    'substitutions',
    'insertions',
    'deletions',
    'reference_word_count',
    'latency_ms',
    'language_pair',
    'accent_region',
    'noise_level',
    'device',
    'capture_mode',
    'reference_transcript',
    'hypothesis_transcript',
  ];
  buffer.writeln(headers.join(','));
  for (final row in rows) {
    final values = row.toJson();
    buffer
        .writeln(headers.map((header) => _csvEscape(values[header])).join(','));
  }
  return buffer.toString();
}

String toPrettyJson(List<BenchmarkExportRow> rows) {
  const encoder = JsonEncoder.withIndent('  ');
  return '${encoder.convert(rows.map((row) => row.toJson()).toList())}\n';
}

Future<List<ClipMetadata>> _loadClipManifest(String? clipsPath) async {
  if (clipsPath == null) return const [];
  final file = File(clipsPath);
  if (!await file.exists()) {
    throw BenchmarkRunnerException('Clip manifest does not exist: $clipsPath');
  }

  final decoded = jsonDecode(await file.readAsString());
  final clipsJson = decoded is List
      ? decoded
      : decoded is Map<String, Object?>
          ? decoded['clips']
          : null;
  if (clipsJson is! List) {
    throw const BenchmarkRunnerException(
      'Clip manifest must be a JSON array or an object with a clips array.',
    );
  }
  return clipsJson.map((entry) {
    if (entry is! Map<String, Object?>) {
      throw const BenchmarkRunnerException('Clip entries must be objects.');
    }
    return ClipMetadata.fromJson(entry);
  }).toList(growable: false);
}

List<String> _tokenize(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9'\s]+"), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
}

Map<String, dynamic> _decodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) return decoded;
  throw BenchmarkRunnerException('Expected JSON object: $body');
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

String? _stringValue(Map<String, Object?> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _readTextPath(String? path) {
  if (path == null) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  return file.readAsStringSync().trim();
}

String? _blankToNull(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return value.trim();
}

String _csvEscape(Object? value) {
  if (value == null) return '';
  final text = value is double ? value.toStringAsFixed(6) : value.toString();
  if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
    return text;
  }
  return '"${text.replaceAll('"', '""')}"';
}

String _shellQuote(String value) {
  return "'${value.replaceAll("'", "'\\''")}'";
}
