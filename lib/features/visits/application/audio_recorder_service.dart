import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<void> startRecording(String path) async {
    if (await hasPermission()) {
      await _audioRecorder.start(const RecordConfig(), path: path);
    } else {
      throw Exception('Microphone permission not granted');
    }
  }

  Future<Stream<Uint8List>> startAudioStream([String? path]) async {
    if (await hasPermission()) {
      if (path != null) {
        // We use the stream and write it to a file ourselves to support both
        final file = File(path);
        final sink = file.openWrite();
        final controller = StreamController<Uint8List>();

        final stream = await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );

        stream.listen(
          (data) {
            sink.add(data);
            controller.add(data);
          },
          onDone: () async {
            await sink.close();
            await controller.close();
          },
          onError: (e) {
            controller.addError(e);
          },
        );

        return controller.stream;
      } else {
        return await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );
      }
    } else {
      throw Exception('Microphone permission not granted');
    }
  }

  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }

  Future<void> dispose() async {
    _audioRecorder.dispose();
  }

  Future<String> generateRecordingPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/recording_$timestamp.m4a';
  }
}

final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  final service = AudioRecorderService();
  ref.onDispose(() => service.dispose());
  return service;
});
