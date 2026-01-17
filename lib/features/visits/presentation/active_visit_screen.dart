import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olu_ai/features/visits/application/audio_recorder_service.dart';
import 'package:olu_ai/features/visits/application/transcription_service.dart';

class ActiveVisitScreen extends ConsumerStatefulWidget {
  final int patientId;

  const ActiveVisitScreen({super.key, required this.patientId});

  @override
  ConsumerState<ActiveVisitScreen> createState() => _ActiveVisitScreenState();
}

class _ActiveVisitScreenState extends ConsumerState<ActiveVisitScreen> {
  bool _isRecording = false;
  String _transcript = "";
  String? _currentRecordingPath;

  @override
  Widget build(BuildContext context) {
    final recorder = ref.watch(audioRecorderServiceProvider);
    final transcriber = ref.watch(transcriptionServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Visit'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _transcript.isEmpty ? 'Start recording to see transcript...' : _transcript,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.large(
                  onPressed: () async {
                    if (_isRecording) {
                      final path = await recorder.stopRecording();
                      setState(() {
                        _isRecording = false;
                      });
                      
                      // Trigger transcription (mock for now as we don't have real-time stream yet)
                      if (path != null) {
                         final text = await transcriber.transcribe(path);
                         setState(() {
                           _transcript += "\n$text";
                         });
                      }
                    } else {
                      final path = await recorder.generateRecordingPath();
                      await recorder.startRecording(path);
                      setState(() {
                        _isRecording = true;
                        _currentRecordingPath = path;
                      });
                    }
                  },
                  backgroundColor: _isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording ? Colors.white : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
