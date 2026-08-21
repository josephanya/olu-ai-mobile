import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

  test('runner exports one standalone benchmark row per scripted clip',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('benchmark_runner_test_');
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    final audio = File('${directory.path}/clip-001.wav');
    await audio.writeAsBytes(const [0, 1, 2, 3]);

    final manifest = File('${directory.path}/manifest.json');
    await manifest.writeAsString(jsonEncode({
      'clips': [
        {
          'clipId': 'clip-001',
          'audioPath': audio.path,
          'referenceTranscript': 'patient has fever',
          'languagePair': 'sw-en',
          'accentRegion': 'Nairobi',
          'noiseLevel': 'clinic',
          'device': 'Pixel 7',
          'captureMode': 'scripted_test_clip',
        }
      ]
    }));

    final runner = BenchmarkRunner(
      options: BenchmarkRunnerOptions(
        clipsPath: manifest.path,
        outputDirectory: '${directory.path}/results',
        sherpaCommand: 'printf "patient has fever"',
        saharaApiKey: 'sahara-key',
        openAiApiKey: 'openai-key',
      ),
      httpClient: MockClient((request) async {
        if (request.url.host == 'infer.voice.intron.io' &&
            request.url.path.endsWith('/upload')) {
          expect(request.headers['Authorization'], 'Bearer sahara-key');
          return http.Response(jsonEncode({'file_id': 'file-001'}), 200);
        }
        if (request.url.host == 'infer.voice.intron.io' &&
            request.url.path.endsWith('/status/file-001')) {
          return http.Response(
            jsonEncode({
              'status': 'FILE_TRANSCRIBED',
              'transcript': 'patient fever',
            }),
            200,
          );
        }
        if (request.url.host == 'api.openai.com') {
          expect(request.headers['Authorization'], 'Bearer openai-key');
          return http.Response(
              jsonEncode({'text': 'patient has a fever'}), 200);
        }
        return http.Response('unexpected request: ${request.url}', 500);
      }),
    );

    final report = await runner.run();
    runner.close();

    expect(report.rows, hasLength(1));
    expect(await File(report.csvPath).exists(), isTrue);
    expect(await File(report.jsonPath).exists(), isTrue);

    final row = report.rows.single;
    expect(row.sherpaWer.rate, 0);
    expect(row.saharaWer.rate, 1 / 3);
    expect(row.whisperWer.rate, 1 / 3);

    final csv = await File(report.csvPath).readAsString();
    expect(csv, contains('sherpa_wer,sahara_wer,whisper_wer'));
    expect(csv, contains('clip-001'));

    final jsonRows =
        jsonDecode(await File(report.jsonPath).readAsString()) as List;
    expect(jsonRows.single['sahara_wer'], 1 / 3);
    expect(jsonRows.single['whisper_transcript'], 'patient has a fever');
  });

  test('runner requires all three fresh engine inputs', () {
    final runner = BenchmarkRunner(
      options: const BenchmarkRunnerOptions(),
    );

    expect(
      runner.run,
      throwsA(isA<BenchmarkRunnerException>()),
    );
    runner.close();
  });
}
