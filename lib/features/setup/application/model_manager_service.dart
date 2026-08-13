import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:olu_ai/core/network/download_service.dart';

/// Describes a single model file that needs to exist on disk.
class ModelFile {
  final String url;
  final String localFileName;
  final String assetPath;

  const ModelFile({
    required this.url,
    required this.localFileName,
    required this.assetPath,
  });
}

/// Overall setup state exposed to the UI.
class SetupState {
  final SetupStatus status;
  final String message;
  final double overallProgress;
  final String progressDetail;
  final String? error;

  const SetupState({
    this.status = SetupStatus.checking,
    this.message = 'Checking models...',
    this.overallProgress = 0.0,
    this.progressDetail = '',
    this.error,
  });

  SetupState copyWith({
    SetupStatus? status,
    String? message,
    double? overallProgress,
    String? progressDetail,
    String? error,
  }) {
    return SetupState(
      status: status ?? this.status,
      message: message ?? this.message,
      overallProgress: overallProgress ?? this.overallProgress,
      progressDetail: progressDetail ?? this.progressDetail,
      error: error,
    );
  }
}

enum SetupStatus { checking, downloading, ready, error }

/// Orchestrates the download/setup of all AI models (Sherpa + LLM).
class ModelManagerService extends ChangeNotifier {
  final DownloadService _downloadService;

  SetupState _state = const SetupState();
  SetupState get state => _state;

  // ─── Sherpa model files ────────────────────────────────────
  static const String _sherpaBaseUrl =
      'https://huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-en-2023-06-26/resolve/main';

  static const List<ModelFile> _sherpaFiles = [
    ModelFile(
      url: '$_sherpaBaseUrl/encoder-epoch-99-avg-1-chunk-16-left-64.int8.onnx',
      localFileName: 'encoder-epoch-99-avg-1-chunk-16-left-64.int8.onnx',
      assetPath: 'models/sherpa/encoder-epoch-99-avg-1-chunk-16-left-64.int8.onnx',
    ),
    ModelFile(
      url: '$_sherpaBaseUrl/decoder-epoch-99-avg-1-chunk-16-left-64.int8.onnx',
      localFileName: 'decoder-epoch-99-avg-1-chunk-16-left-64.int8.onnx',
      assetPath: 'models/sherpa/decoder-epoch-99-avg-1-chunk-16-left-64.int8.onnx',
    ),
    ModelFile(
      url: '$_sherpaBaseUrl/joiner-epoch-99-avg-1-chunk-16-left-64.int8.onnx',
      localFileName: 'joiner-epoch-99-avg-1-chunk-16-left-64.int8.onnx',
      assetPath: 'models/sherpa/joiner-epoch-99-avg-1-chunk-16-left-64.int8.onnx',
    ),
    ModelFile(
      url: '$_sherpaBaseUrl/tokens.txt',
      localFileName: 'tokens.txt',
      assetPath: 'models/sherpa/tokens.txt',
    ),
  ];

  // ─── LLM model file ───────────────────────────────────────
  static const ModelFile _llmFile = ModelFile(
    url:
        'https://huggingface.co/alpha-ai/LLAMA3-3B-Medical-COT-GGUF/resolve/main/LLAMA3-3B-Medical-COT.Q4_K_M.gguf',
    localFileName: 'medical_llama.gguf',
    assetPath: 'models/llm/medical_llama.gguf',
  );

  ModelManagerService(this._downloadService);

  /// Returns true if all model files are present and ready.
  Future<bool> areModelsReady() async {
    final docDir = await getApplicationDocumentsDirectory();
    final sherpaDir = Directory('${docDir.path}/sherpa_online_model');
    final llmPath = '${docDir.path}/medical_llama.gguf';

    if (!await sherpaDir.exists()) return false;

    for (final f in _sherpaFiles) {
      if (!await File('${sherpaDir.path}/${f.localFileName}').exists()) {
        return false;
      }
    }

    if (!await File(llmPath).exists()) return false;

    return true;
  }

  /// Starts checking and downloading all required models.
  Future<void> ensureModelsReady() async {
    _updateState(const SetupState(
      status: SetupStatus.checking,
      message: 'Checking for AI models...',
    ));

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final sherpaDir = Directory('${docDir.path}/sherpa_online_model');
      final llmPath = '${docDir.path}/medical_llama.gguf';

      if (!await sherpaDir.exists()) {
        await sherpaDir.create(recursive: true);
      }

      // Collect files that need downloading
      final filesToDownload = <_PendingDownload>[];

      // Check Sherpa files
      for (final f in _sherpaFiles) {
        final localPath = '${sherpaDir.path}/${f.localFileName}';
        if (!await File(localPath).exists()) {
          // Try asset copy first
          final copied = await _tryCopyAsset(f.assetPath, localPath);
          if (!copied) {
            filesToDownload.add(_PendingDownload(url: f.url, savePath: localPath));
          }
        }
      }

      // Check LLM file
      if (!await File(llmPath).exists()) {
        final copied = await _tryCopyAsset(_llmFile.assetPath, llmPath);
        if (!copied) {
          filesToDownload.add(_PendingDownload(url: _llmFile.url, savePath: llmPath));
        }
      }

      if (filesToDownload.isEmpty) {
        _updateState(const SetupState(
          status: SetupStatus.ready,
          message: 'All models ready!',
          overallProgress: 1.0,
        ));
        return;
      }

      // Download missing files sequentially with progress
      _updateState(SetupState(
        status: SetupStatus.downloading,
        message: 'Downloading AI models...',
        progressDetail: '0 / ${filesToDownload.length} files',
      ));

      for (int i = 0; i < filesToDownload.length; i++) {
        final pending = filesToDownload[i];
        final fileName = pending.url.split('/').last;

        await _downloadService.downloadFile(
          url: pending.url,
          savePath: pending.savePath,
          onProgress: (progress) {
            final fileProgress = progress.fraction;
            final overallProgress =
                (i + fileProgress) / filesToDownload.length;

            _updateState(SetupState(
              status: SetupStatus.downloading,
              message: 'Downloading: $fileName',
              overallProgress: overallProgress.clamp(0.0, 1.0),
              progressDetail: progress.formattedProgress,
            ));
          },
        );
      }

      _updateState(const SetupState(
        status: SetupStatus.ready,
        message: 'All models ready!',
        overallProgress: 1.0,
      ));
    } catch (e) {
      _updateState(SetupState(
        status: SetupStatus.error,
        message: 'Download failed',
        error: e.toString(),
      ));
    }
  }

  Future<bool> _tryCopyAsset(String assetPath, String targetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(targetPath).writeAsBytes(bytes);
      debugPrint('Copied $assetPath from assets');
      return true;
    } catch (_) {
      return false;
    }
  }

  void _updateState(SetupState newState) {
    _state = newState;
    notifyListeners();
  }
}

class _PendingDownload {
  final String url;
  final String savePath;
  const _PendingDownload({required this.url, required this.savePath});
}

final modelManagerServiceProvider =
    ChangeNotifierProvider<ModelManagerService>((ref) {
  final downloadService = ref.watch(downloadServiceProvider);
  return ModelManagerService(downloadService);
});
