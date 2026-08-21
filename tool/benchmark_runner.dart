import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

const engineSherpa = 'sherpa_onnx';
const engineSahara = 'sahara_v2_file_upload';
const engineWhisper = 'whisper_api';

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
  try {
    final report = await runner.run();
    stdout.writeln(
      'Exported ${report.rows.length} benchmark clip rows to ${report.csvPath} and ${report.jsonPath}.',
    );
  } finally {
    runner.close();
  }
}

class BenchmarkRunnerOptions {
  final String clipsPath;
  final String outputDirectory;
  final String? saharaApiKey;
  final String? openAiApiKey;
  final String? sherpaCommand;
  final bool showHelp;

  const BenchmarkRunnerOptions({
    this.clipsPath = 'benchmark/manifest.json',
    this.outputDirectory = 'benchmark/results',
    this.saharaApiKey,
    this.openAiApiKey,
    this.sherpaCommand,
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

    var clipsPath = 'benchmark/manifest.json';
    var outputDirectory = 'benchmark/results';
    String? saharaApiKey = environment['SAHARA_API_KEY'];
    String? openAiApiKey = environment['OPENAI_API_KEY'];
    String? sherpaCommand;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '--help' || arg == '-h') {
        return const BenchmarkRunnerOptions(showHelp: true);
      }

      final clipsValue = readValue('--clips', i);
      final outputValue = readValue('--out', i);
      final saharaValue = readValue('--sahara-api-key', i);
      final openAiValue = readValue('--openai-api-key', i);
      final sherpaValue = readValue('--sherpa-command', i);

      if (clipsValue != null) {
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
      clipsPath: clipsPath,
      outputDirectory: outputDirectory,
      saharaApiKey: _blankToNull(saharaApiKey),
      openAiApiKey: _blankToNull(openAiApiKey),
      sherpaCommand: _blankToNull(sherpaCommand),
    );
  }

  static const _optionsWithValues = {
    '--clips',
    '--out',
    '--sahara-api-key',
    '--openai-api-key',
    '--sherpa-command',
  };

  static const usage = '''
Usage:
  dart run tool/benchmark_runner.dart \\
    --clips benchmark/manifest.json \\
    --out benchmark/results \\
    --sherpa-command "./scripts/run_sherpa.sh {audio}" \\
    --sahara-api-key <key> \\
    --openai-api-key <key>

Inputs:
  --clips              Dedicated benchmark manifest JSON. Defaults to benchmark/manifest.json.
  --out                Output directory. Defaults to benchmark/results.
  --sherpa-command     Local command used to transcribe each clip with Sherpa-ONNX.
                       Use {audio} as a placeholder for the audio path.
  --sahara-api-key     Sahara key. Defaults to SAHARA_API_KEY.
  --openai-api-key     Whisper API key. Defaults to OPENAI_API_KEY.

Manifest shape:
  {
    "clips": [
      {
        "clipId": "clip-001",
        "audioPath": "benchmark/audio/clip-001.wav",
        "referenceTranscript": "hand-written scripted reference text",
        "languagePair": "sw-en",
        "accentRegion": "Nairobi",
        "noiseLevel": "clinic",
        "device": "Pixel 7",
        "captureMode": "scripted_test_clip"
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
    _validateEngineInputs();

    final clips = await _loadClipManifest(options.clipsPath);
    final rows = <BenchmarkExportRow>[];
    for (final clip in clips) {
      final results = <String, TranscriptCandidate>{
        engineSherpa: await _runSherpaCommand(clip),
        engineSahara: await _runSaharaFileUpload(clip),
        engineWhisper: await _runWhisper(clip),
      };
      rows.add(BenchmarkExportRow.fromResults(clip, results));
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
    );
  }

  void close() {
    _httpClient.close();
  }

  void _validateEngineInputs() {
    final missing = <String>[];
    if (options.sherpaCommand == null) missing.add('--sherpa-command');
    if (options.saharaApiKey == null) {
      missing.add('--sahara-api-key or SAHARA_API_KEY');
    }
    if (options.openAiApiKey == null) {
      missing.add('--openai-api-key or OPENAI_API_KEY');
    }
    if (missing.isNotEmpty) {
      throw BenchmarkRunnerException(
        'Standalone benchmarks run all three engines fresh. Missing: ${missing.join(', ')}.',
      );
    }
  }

  Future<TranscriptCandidate> _runSherpaCommand(ClipMetadata clip) async {
    final command = options.sherpaCommand!.contains('{audio}')
        ? options.sherpaCommand!
            .replaceAll('{audio}', _shellQuote(clip.audioPath))
        : '${options.sherpaCommand!} ${_shellQuote(clip.audioPath)}';
    final startedAt = DateTime.now();
    final result = await Process.run('/bin/sh', ['-c', command]);
    final completedAt = DateTime.now();
    if (result.exitCode != 0) {
      throw BenchmarkRunnerException(
        'Sherpa command failed for ${clip.clipId}: ${result.stderr}',
      );
    }
    final transcript = result.stdout.toString().trim();
    if (transcript.isEmpty) {
      throw BenchmarkRunnerException(
        'Sherpa command returned an empty transcript for ${clip.clipId}.',
      );
    }
    return TranscriptCandidate(
      transcript: transcript,
      latencyMs: completedAt.difference(startedAt).inMilliseconds,
    );
  }

  Future<TranscriptCandidate> _runSaharaFileUpload(ClipMetadata clip) async {
    final startedAt = DateTime.now();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_saharaFileUploadEndpoint),
    )
      ..headers['Authorization'] = 'Bearer ${options.saharaApiKey}'
      ..fields['audio_file_name'] = p.basename(clip.audioPath)
      ..fields['use_language_asr_input'] = clip.languagePair ?? 'sw'
      ..files.add(await http.MultipartFile.fromPath(
        'audio_file_blob',
        clip.audioPath,
      ));

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
    final startedAt = DateTime.now();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_openAiTranscriptionEndpoint),
    )
      ..headers['Authorization'] = 'Bearer ${options.openAiApiKey}'
      ..fields['model'] = 'whisper-1'
      ..files.add(await http.MultipartFile.fromPath('file', clip.audioPath));

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
      transcript: transcript,
      latencyMs: completedAt.difference(startedAt).inMilliseconds,
    );
  }
}

class ClipMetadata {
  final String clipId;
  final String audioPath;
  final String referenceTranscript;
  final String? languagePair;
  final String? accentRegion;
  final String? noiseLevel;
  final String? device;
  final String? captureMode;

  const ClipMetadata({
    required this.clipId,
    required this.audioPath,
    required this.referenceTranscript,
    this.languagePair,
    this.accentRegion,
    this.noiseLevel,
    this.device,
    this.captureMode,
  });

  factory ClipMetadata.fromJson(Map<String, Object?> json) {
    final clipId = _stringValue(json, const ['clipId', 'clip_id', 'id']);
    if (clipId == null || clipId.isEmpty) {
      throw BenchmarkRunnerException('Clip is missing clipId.');
    }

    final audioPath = _stringValue(json, const ['audioPath', 'audio_path']);
    if (audioPath == null || audioPath.isEmpty) {
      throw BenchmarkRunnerException('Clip $clipId is missing audioPath.');
    }
    if (!File(audioPath).existsSync()) {
      throw BenchmarkRunnerException(
          'Clip $clipId audio file does not exist: $audioPath');
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
        'Clip $clipId is missing a hand-written reference transcript.',
      );
    }

    return ClipMetadata(
      clipId: clipId,
      audioPath: audioPath,
      referenceTranscript: referenceTranscript,
      languagePair: _stringValue(json, const ['languagePair', 'language_pair']),
      accentRegion: _stringValue(json, const ['accentRegion', 'accent_region']),
      noiseLevel: _stringValue(json, const ['noiseLevel', 'noise_level']),
      device: _stringValue(json, const ['device']),
      captureMode: _stringValue(json, const ['captureMode', 'capture_mode']),
    );
  }
}

class TranscriptCandidate {
  final String transcript;
  final int latencyMs;

  const TranscriptCandidate({
    required this.transcript,
    required this.latencyMs,
  });
}

class BenchmarkExportRow {
  final String clipId;
  final String audioPath;
  final String? languagePair;
  final String? accentRegion;
  final String? noiseLevel;
  final String? device;
  final String? captureMode;
  final String referenceTranscript;
  final String sherpaTranscript;
  final String saharaTranscript;
  final String whisperTranscript;
  final WerStats sherpaWer;
  final WerStats saharaWer;
  final WerStats whisperWer;
  final int sherpaLatencyMs;
  final int saharaLatencyMs;
  final int whisperLatencyMs;

  const BenchmarkExportRow({
    required this.clipId,
    required this.audioPath,
    required this.referenceTranscript,
    required this.sherpaTranscript,
    required this.saharaTranscript,
    required this.whisperTranscript,
    required this.sherpaWer,
    required this.saharaWer,
    required this.whisperWer,
    required this.sherpaLatencyMs,
    required this.saharaLatencyMs,
    required this.whisperLatencyMs,
    this.languagePair,
    this.accentRegion,
    this.noiseLevel,
    this.device,
    this.captureMode,
  });

  factory BenchmarkExportRow.fromResults(
    ClipMetadata clip,
    Map<String, TranscriptCandidate> results,
  ) {
    final sherpa = results[engineSherpa]!;
    final sahara = results[engineSahara]!;
    final whisper = results[engineWhisper]!;
    return BenchmarkExportRow(
      clipId: clip.clipId,
      audioPath: clip.audioPath,
      languagePair: clip.languagePair,
      accentRegion: clip.accentRegion,
      noiseLevel: clip.noiseLevel,
      device: clip.device,
      captureMode: clip.captureMode,
      referenceTranscript: clip.referenceTranscript,
      sherpaTranscript: sherpa.transcript,
      saharaTranscript: sahara.transcript,
      whisperTranscript: whisper.transcript,
      sherpaWer: computeWer(clip.referenceTranscript, sherpa.transcript),
      saharaWer: computeWer(clip.referenceTranscript, sahara.transcript),
      whisperWer: computeWer(clip.referenceTranscript, whisper.transcript),
      sherpaLatencyMs: sherpa.latencyMs,
      saharaLatencyMs: sahara.latencyMs,
      whisperLatencyMs: whisper.latencyMs,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'clip_id': clipId,
      'audio_path': audioPath,
      'language_pair': languagePair,
      'accent_region': accentRegion,
      'noise_level': noiseLevel,
      'device': device,
      'capture_mode': captureMode,
      'reference_transcript': referenceTranscript,
      'sherpa_wer': sherpaWer.rate,
      'sahara_wer': saharaWer.rate,
      'whisper_wer': whisperWer.rate,
      'sherpa_substitutions': sherpaWer.substitutions,
      'sahara_substitutions': saharaWer.substitutions,
      'whisper_substitutions': whisperWer.substitutions,
      'sherpa_insertions': sherpaWer.insertions,
      'sahara_insertions': saharaWer.insertions,
      'whisper_insertions': whisperWer.insertions,
      'sherpa_deletions': sherpaWer.deletions,
      'sahara_deletions': saharaWer.deletions,
      'whisper_deletions': whisperWer.deletions,
      'reference_word_count': sherpaWer.referenceWordCount,
      'sherpa_latency_ms': sherpaLatencyMs,
      'sahara_latency_ms': saharaLatencyMs,
      'whisper_latency_ms': whisperLatencyMs,
      'sherpa_transcript': sherpaTranscript,
      'sahara_transcript': saharaTranscript,
      'whisper_transcript': whisperTranscript,
    };
  }
}

class BenchmarkReport {
  final List<BenchmarkExportRow> rows;
  final String csvPath;
  final String jsonPath;

  const BenchmarkReport({
    required this.rows,
    required this.csvPath,
    required this.jsonPath,
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
    'audio_path',
    'language_pair',
    'accent_region',
    'noise_level',
    'device',
    'capture_mode',
    'reference_transcript',
    'sherpa_wer',
    'sahara_wer',
    'whisper_wer',
    'sherpa_substitutions',
    'sahara_substitutions',
    'whisper_substitutions',
    'sherpa_insertions',
    'sahara_insertions',
    'whisper_insertions',
    'sherpa_deletions',
    'sahara_deletions',
    'whisper_deletions',
    'reference_word_count',
    'sherpa_latency_ms',
    'sahara_latency_ms',
    'whisper_latency_ms',
    'sherpa_transcript',
    'sahara_transcript',
    'whisper_transcript',
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

Future<List<ClipMetadata>> _loadClipManifest(String clipsPath) async {
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
