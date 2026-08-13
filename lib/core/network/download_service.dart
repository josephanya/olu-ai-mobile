import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Represents the current state of a single file download.
class DownloadProgress {
  final String fileName;
  final int bytesReceived;
  final int totalBytes;
  final DownloadStatus status;
  final String? error;

  const DownloadProgress({
    required this.fileName,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.status = DownloadStatus.idle,
    this.error,
  });

  double get fraction =>
      totalBytes > 0 ? (bytesReceived / totalBytes).clamp(0.0, 1.0) : 0.0;

  String get formattedProgress {
    final receivedMB = (bytesReceived / (1024 * 1024)).toStringAsFixed(1);
    final totalMB = totalBytes > 0
        ? (totalBytes / (1024 * 1024)).toStringAsFixed(1)
        : '?';
    return '$receivedMB / $totalMB MB';
  }

  DownloadProgress copyWith({
    String? fileName,
    int? bytesReceived,
    int? totalBytes,
    DownloadStatus? status,
    String? error,
  }) {
    return DownloadProgress(
      fileName: fileName ?? this.fileName,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

enum DownloadStatus { idle, downloading, completed, error }

/// A service that downloads files with chunked streaming and progress tracking.
///
/// Uses `http.Client().send()` to stream bytes to disk instead of loading
/// the entire file into memory (which would OOM on the ~2 GB LLM model).
class DownloadService {
  final http.Client _client = http.Client();

  /// Downloads a file from [url] to [savePath], reporting progress via [onProgress].
  ///
  /// Supports resuming partial downloads. If a partial file exists at [savePath],
  /// the download will resume from where it left off using HTTP Range headers.
  Future<void> downloadFile({
    required String url,
    required String savePath,
    required ValueChanged<DownloadProgress> onProgress,
  }) async {
    final fileName = url.split('/').last;
    final tempPath = '$savePath.part';
    final tempFile = File(tempPath);

    int startByte = 0;

    // Resume support: check for partial downloads
    if (await tempFile.exists()) {
      startByte = await tempFile.length();
      debugPrint('Resuming $fileName from byte $startByte');
    }

    try {
      final request = http.Request('GET', Uri.parse(url));

      if (startByte > 0) {
        request.headers['Range'] = 'bytes=$startByte-';
      }

      onProgress(DownloadProgress(
        fileName: fileName,
        bytesReceived: startByte,
        status: DownloadStatus.downloading,
      ));

      final response = await _client.send(request);

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception(
            'Download failed: HTTP ${response.statusCode} for $url');
      }

      final totalBytes = startByte +
          (response.contentLength ?? 0);

      final sink = tempFile.openWrite(mode: startByte > 0 ? FileMode.append : FileMode.write);
      int received = startByte;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;

        onProgress(DownloadProgress(
          fileName: fileName,
          bytesReceived: received,
          totalBytes: totalBytes,
          status: DownloadStatus.downloading,
        ));
      }

      await sink.flush();
      await sink.close();

      // Move temp file to final path
      await tempFile.rename(savePath);

      onProgress(DownloadProgress(
        fileName: fileName,
        bytesReceived: totalBytes,
        totalBytes: totalBytes,
        status: DownloadStatus.completed,
      ));

      debugPrint('Download complete: $fileName ($totalBytes bytes)');
    } catch (e) {
      onProgress(DownloadProgress(
        fileName: fileName,
        bytesReceived: startByte,
        status: DownloadStatus.error,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  /// Checks if a file already exists at the given path.
  Future<bool> fileExists(String path) => File(path).exists();

  void dispose() {
    _client.close();
  }
}

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final service = DownloadService();
  ref.onDispose(() => service.dispose());
  return service;
});
