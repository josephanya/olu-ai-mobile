import 'dart:async';
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
  String _liveGuidance = "";
  StreamSubscription? _transcriptionSubscription;
  Timer? _guidanceTimer;

  @override
  void dispose() {
    _transcriptionSubscription?.cancel();
    _guidanceTimer?.cancel();
    super.dispose();
  }

  void _startGuidanceTimer() {
    _guidanceTimer?.cancel();
    _guidanceTimer = Timer.periodic(const Duration(seconds: 8), (timer) async {
      if (_transcript.isNotEmpty && _isRecording) {
        final llm = ref.read(llmServiceProvider);
        final guidance = await llm.getLiveGuidance(_transcript);
        if (guidance.isNotEmpty && mounted) {
          setState(() {
            _liveGuidance = guidance;
          });
        }
      }
    });
  }

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
          if (_isRecording && _liveGuidance.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Insight',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                  ),
                            ),
                            Text(_liveGuidance),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                      await _transcriptionSubscription?.cancel();
                      _guidanceTimer?.cancel();
                      final path = await recorder.stopRecording();
                      setState(() {
                        _isRecording = false;
                        _audioPath = path;
                        _liveGuidance = "";
                      });
                    } else {
                      final path = await recorder.generateRecordingPath();
                      setState(() {
                        _transcript = "";
                        _liveGuidance = "";
                        _audioPath = path;
                      });

                      final audioStream = await recorder.startAudioStream(path);
                      final transcriptStream =
                          transcriber.transcribeStream(audioStream);

                      _transcriptionSubscription =
                          transcriptStream.listen((text) {
                        if (mounted) {
                          setState(() {
                            _transcript = text;
                          });
                        }
                      });

                      _startGuidanceTimer();

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
