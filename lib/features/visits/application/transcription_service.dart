import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:http/http.dart' as http;

class TranscriptionService {
  sherpa.OfflineRecognizer? _recognizer;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    sherpa.initBindings();
    final modelPath = await _getModelPath();

    final config = sherpa.OfflineRecognizerConfig(
      feat: const sherpa.FeatureConfig(
        sampleRate: 16000,
        featureDim: 80,
      ),
      model: sherpa.OfflineModelConfig(
        whisper: sherpa.OfflineWhisperModelConfig(
          encoder: '$modelPath/tiny.en-encoder.int8.onnx',
          decoder: '$modelPath/tiny.en-decoder.int8.onnx',
        ),
        tokens: '$modelPath/tiny-tokens.txt',
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
    // Check for local project directory.
    // This only works if the app has access to the project root (e.g. during local desktop development).
    final localDir = Directory('models/sherpa');
    if (await localDir.exists()) {
      final encoder = File('${localDir.path}/tiny.en-encoder.int8.onnx');
      final decoder = File('${localDir.path}/tiny.en-decoder.int8.onnx');
      final tokens = File('${localDir.path}/tiny-tokens.txt');

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

      // Check if we bundled the models as assets (for local development)
      final bundled = await _tryCopyFromAssets(modelDir.path);

      if (!bundled) {
        debugPrint('Models not found in assets, starting download...');
        const hfUrl =
            'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny.en/resolve/main';

        if (!await File('${modelDir.path}/tiny.en-encoder.int8.onnx')
            .exists()) {
          await _downloadFile('$hfUrl/tiny.en-encoder.int8.onnx',
              '${modelDir.path}/tiny.en-encoder.int8.onnx');
        }
        if (!await File('${modelDir.path}/tiny.en-decoder.int8.onnx')
            .exists()) {
          await _downloadFile('$hfUrl/tiny.en-decoder.int8.onnx',
              '${modelDir.path}/tiny.en-decoder.int8.onnx');
        }
        if (!await File('${modelDir.path}/tiny-tokens.txt').exists()) {
          await _downloadFile(
              '$hfUrl/tiny-tokens.txt', '${modelDir.path}/tiny-tokens.txt');
        }
      }
    }
    return modelDir.path;
  }

  Future<bool> _tryCopyFromAssets(String targetPath) async {
    final files = [
      'tiny.en-encoder.int8.onnx',
      'tiny.en-decoder.int8.onnx',
      'tiny-tokens.txt'
    ];

    try {
      for (final fileName in files) {
        // We use a try-catch because rootBundle.load throws if asset is missing
        final data = await rootBundle.load('models/sherpa/$fileName');
        final bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File('$targetPath/$fileName').writeAsBytes(bytes);
        debugPrint('Copied $fileName from assets');
      }
      return true;
    } catch (e) {
      debugPrint('Models not bundled in assets.');
      return false;
    }
  }

  Future<void> _downloadFile(String url, String savePath) async {
    debugPrint('File downoad started');
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
