import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:http/http.dart' as http;

class TranscriptionService {
  sherpa.OnlineRecognizer? _onlineRecognizer;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    sherpa.initBindings();
    final modelPath = await _getModelPath();

    final config = sherpa.OnlineRecognizerConfig(
      feat: const sherpa.FeatureConfig(
        sampleRate: 16000,
        featureDim: 80,
      ),
      model: sherpa.OnlineModelConfig(
        transducer: sherpa.OnlineTransducerModelConfig(
          encoder: '$modelPath/encoder-epoch-99-avg-1.int8.onnx',
          decoder: '$modelPath/decoder-epoch-99-avg-1.onnx',
          joiner: '$modelPath/joiner-epoch-99-avg-1.onnx',
        ),
        tokens: '$modelPath/tokens.txt',
        numThreads: 1,
        debug: false,
      ),
    );

    _onlineRecognizer = sherpa.OnlineRecognizer(config);
    _isInitialized = true;
  }

  Stream<String> transcribeStream(Stream<Uint8List> audioStream) async* {
    if (!_isInitialized) {
      await initialize();
    }

    final stream = _onlineRecognizer!.createStream();
    String lastText = "";

    await for (final chunk in audioStream) {
      final samples = _convertPcm16ToFloat32(chunk);
      stream.acceptWaveform(samples: samples, sampleRate: 16000);

      while (_onlineRecognizer!.isReady(stream)) {
        _onlineRecognizer!.decode(stream);
      }

      final result = _onlineRecognizer!.getResult(stream);
      if (result.text.isNotEmpty && result.text != lastText) {
        yield result.text;
        lastText = result.text;
      }
    }

    stream.free();
  }

  Float32List _convertPcm16ToFloat32(Uint8List bytes) {
    final samples = Float32List(bytes.length ~/ 2);
    final byteData =
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.length);
    for (var i = 0; i < samples.length; i++) {
      samples[i] = byteData.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return samples;
  }

  Future<String> transcribe(String audioPath) async {
    // Keep this for final processing if needed, but update to use online recognizer if necessary
    // or just leave as is if we want to support both.
    // For now, let's just make it return an empty string or implement via online recognizer.
    if (!_isInitialized) {
      await initialize();
    }

    final waveData = await _readWaveFile(audioPath);
    if (waveData == null) {
      return "Error: Could not read audio file.";
    }

    final stream = _onlineRecognizer!.createStream();
    final samples =
        Float32List.fromList(waveData.map((e) => e.toDouble()).toList());
    stream.acceptWaveform(samples: samples, sampleRate: 16000);
    stream.inputFinished();

    while (_onlineRecognizer!.isReady(stream)) {
      _onlineRecognizer!.decode(stream);
    }

    final result = _onlineRecognizer!.getResult(stream);
    stream.free();
    return result.text;
  }

  Future<List<double>?> _readWaveFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    final samples = <double>[];

    // If it's a .pcm file, it's raw 16-bit PCM. If .wav, skip the 44-byte header.
    final isRawPcm = path.endsWith('.pcm');
    final startByte = isRawPcm ? 0 : 44;

    for (var i = startByte; i < bytes.length; i += 2) {
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
      final encoder = File('${localDir.path}/encoder-epoch-99-avg-1.int8.onnx');
      final decoder = File('${localDir.path}/decoder-epoch-99-avg-1.onnx');
      final joiner = File('${localDir.path}/joiner-epoch-99-avg-1.onnx');
      final tokens = File('${localDir.path}/tokens.txt');

      if (await encoder.exists() &&
          await decoder.exists() &&
          await joiner.exists() &&
          await tokens.exists()) {
        return localDir.path;
      }
    }

    final docDir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${docDir.path}/sherpa_online_model');

    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);

      // Check if we bundled the models as assets (for local development)
      final bundled = await _tryCopyFromAssets(modelDir.path);

      if (!bundled) {
        debugPrint('Models not found in assets, starting download...');
        const hfUrl =
            'https://huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-en-2023-06-26/resolve/main';

        if (!await File('${modelDir.path}/encoder-epoch-99-avg-1.int8.onnx')
            .exists()) {
          await _downloadFile('$hfUrl/encoder-epoch-99-avg-1.int8.onnx',
              '${modelDir.path}/encoder-epoch-99-avg-1.int8.onnx');
        }
        if (!await File('${modelDir.path}/decoder-epoch-99-avg-1.onnx')
            .exists()) {
          await _downloadFile('$hfUrl/decoder-epoch-99-avg-1.onnx',
              '${modelDir.path}/decoder-epoch-99-avg-1.onnx');
        }
        if (!await File('${modelDir.path}/joiner-epoch-99-avg-1.onnx')
            .exists()) {
          await _downloadFile('$hfUrl/joiner-epoch-99-avg-1.onnx',
              '${modelDir.path}/joiner-epoch-99-avg-1.onnx');
        }
        if (!await File('${modelDir.path}/tokens.txt').exists()) {
          await _downloadFile(
              '$hfUrl/tokens.txt', '${modelDir.path}/tokens.txt');
        }
      }
    }
    return modelDir.path;
  }

  Future<bool> _tryCopyFromAssets(String targetPath) async {
    final files = [
      'encoder-epoch-99-avg-1.int8.onnx',
      'decoder-epoch-99-avg-1.onnx',
      'joiner-epoch-99-avg-1.onnx',
      'tokens.txt'
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
