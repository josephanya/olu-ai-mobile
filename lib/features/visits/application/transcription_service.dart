import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:http/http.dart' as http;

class TranscriptionService {
  sherpa.OfflineRecognizer? _recognizer;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final modelPath = await _getModelPath();

    final config = sherpa.OfflineRecognizerConfig(
      feat: const sherpa.FeatureConfig(
        sampleRate: 16000,
        featureDim: 80,
      ),
      model: sherpa.OfflineModelConfig(
        whisper: sherpa.OfflineWhisperModelConfig(
          encoder: '$modelPath/encoder.onnx',
          decoder: '$modelPath/decoder.onnx',
        ),
        tokens: '$modelPath/tokens.txt',
        numThreads: 1,
        debug: false,
      ),
    );

    _recognizer = sherpa.OfflineRecognizer(config);
    _isInitialized = true;
  }

  Future<String> transcribe(String audioPath) async {
    if (!_isInitialized) {
      await initialize();
    }

    final waveData = await _readWaveFile(audioPath);
    if (waveData == null) {
      return "Error: Could not read audio file.";
    }

    final stream = _recognizer!.createStream();
    stream.acceptWaveform(
        samples: Float32List.fromList(waveData), sampleRate: 16000);
    _recognizer!.decode(stream);
    final result = _recognizer!.getResult(stream);

    stream.free();
    return result.text;
  }

  Future<List<double>?> _readWaveFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    final samples = <double>[];
    for (var i = 44; i < bytes.length; i += 2) {
      if (i + 1 < bytes.length) {
        int sample = bytes[i] | (bytes[i + 1] << 8);
        if (sample > 32767) sample -= 65536;
        samples.add(sample / 32768.0);
      }
    }
    return samples;
  }

  Future<String> _getModelPath() async {
    final localDir = Directory('models/sherpa');
    if (await localDir.exists()) {
      final encoder = File('${localDir.path}/encoder.onnx');
      final decoder = File('${localDir.path}/decoder.onnx');
      final tokens = File('${localDir.path}/tokens.txt');

      if (await encoder.exists() &&
          await decoder.exists() &&
          await tokens.exists()) {
        return localDir.path;
      }
    }

    final docDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${docDir.path}/sherpa_model');

    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
      const hfUrl =
          'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny.en/resolve/main';

      if (!await File('${modelDir.path}/encoder.onnx').exists()) {
        await _downloadFile('$hfUrl/tiny.en-encoder.int8.onnx',
            '${modelDir.path}/encoder.onnx');
      }
      if (!await File('${modelDir.path}/decoder.onnx').exists()) {
        await _downloadFile('$hfUrl/tiny.en-decoder.int8.onnx',
            '${modelDir.path}/decoder.onnx');
      }
      if (!await File('${modelDir.path}/tokens.txt').exists()) {
        await _downloadFile(
            '$hfUrl/tiny.en-tokens.txt', '${modelDir.path}/tokens.txt');
      }
    }
    return modelDir.path;
  }

  Future<void> _downloadFile(String url, String savePath) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed to download file: $url');
    }
  }
}

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  return TranscriptionService();
});
