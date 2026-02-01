import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olu_ai/core/database/database.dart';
import 'package:olu_ai/features/visits/application/audio_recorder_service.dart';
import 'package:olu_ai/features/visits/application/transcription_service.dart';
import 'package:olu_ai/features/visits/application/llm_service.dart';
import 'package:olu_ai/features/visits/data/visit_repository.dart';

class ActiveVisitScreen extends ConsumerStatefulWidget {
  final int patientId;

  const ActiveVisitScreen({super.key, required this.patientId});

  @override
  ConsumerState<ActiveVisitScreen> createState() => _ActiveVisitScreenState();
}

class _ActiveVisitScreenState extends ConsumerState<ActiveVisitScreen> {
  bool _isRecording = false;
  String _transcript = "";
  String? _audioPath;
  String? _aiAnalysis;

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
                _transcript.isEmpty
                    ? 'Start recording to see transcript...'
                    : _transcript,
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
                        _audioPath = path;
                      });

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
                      });
                    }
                  },
                  backgroundColor: _isRecording
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording
                        ? Colors.white
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (_transcript.isNotEmpty && !_isRecording)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final llm = ref.read(llmServiceProvider);
                  final analysis = await llm.analyzeVisit(_transcript);
                  setState(() {
                    _aiAnalysis = analysis;
                  });

                  if (context.mounted) {
                    Navigator.pop(context); // Hide loading
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.6,
                        minChildSize: 0.4,
                        maxChildSize: 0.9,
                        expand: false,
                        builder: (context, scrollController) =>
                            SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Analysis',
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              Text(analysis),
                              const SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: () async {
                                  final repository = await ref
                                      .read(visitRepositoryProvider.future);

                                  await repository
                                      .addVisit(VisitsCompanion.insert(
                                    patientId: widget.patientId,
                                    audioPath: drift.Value(_audioPath),
                                    transcript: drift.Value(_transcript),
                                    aiAnalysis: drift.Value(_aiAnalysis),
                                  ));

                                  if (context.mounted) {
                                    context.pop(); // Close bottom sheet
                                    context.pop(); // Go back to patient list
                                  }
                                },
                                child: const Text('Save Visit'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.analytics),
                label: const Text('Analyze Visit'),
              ),
            ),
        ],
      ),
    );
  }
}
