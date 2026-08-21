import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/benchmark_runner.dart';

void main() {
  test(
      'computeWer uses substitutions insertions and deletions over reference words',
      () {
    final wer = computeWer(
      'patient has fever today',
      'patient had fever and chills today',
    );

    expect(wer.substitutions, 1);
    expect(wer.insertions, 2);
    expect(wer.deletions, 0);
    expect(wer.referenceWordCount, 4);
    expect(wer.rate, 0.75);
  });

  test('runner exports CSV and JSON rows from held-out clip manifest',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('benchmark_runner_test_');
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final manifest = File('${directory.path}/clips.json');
    await manifest.writeAsString(jsonEncode({
      'clips': [
        {
          'clipId': 'clip-001',
          'referenceTranscript': 'patient has fever',
          'languagePair': 'sw-en',
          'accentRegion': 'Nairobi',
          'noiseLevel': 'clinic',
          'device': 'Pixel 7',
          'captureMode': 'offline',
          'sherpaTranscript': 'patient has fever',
          'saharaTranscript': 'patient fever',
          'whisperTranscript': 'patient has a fever',
          'saharaLatencyMs': 2400,
        }
      ]
    }));

    final runner = BenchmarkRunner(
      options: BenchmarkRunnerOptions(
        clipsPath: manifest.path,
        outputDirectory: '${directory.path}/results',
        requireThirdModel: true,
      ),
    );

    final report = await runner.run();
    runner.close();

    expect(report.rows, hasLength(3));
    expect(report.warnings, isEmpty);
    expect(await File(report.csvPath).exists(), isTrue);
    expect(await File(report.jsonPath).exists(), isTrue);

    final csv = await File(report.csvPath).readAsString();
    expect(csv, contains('clip-001,,sahara_v2_benchmark,0.333333'));

    final jsonRows =
        jsonDecode(await File(report.jsonPath).readAsString()) as List;
    expect(
        jsonRows.singleWhere((row) => row['model'] == sourceSherpaLocal)['wer'],
        0);
    expect(
      jsonRows.singleWhere(
          (row) => row['model'] == sourceSaharaBenchmark)['latency_ms'],
      2400,
    );
  });
}
