import 'dart:async';
import 'dart:ui';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:olu_ai/core/database/database.dart';
import 'package:olu_ai/core/theme/app_theme.dart';
import 'package:olu_ai/features/visits/application/audio_recorder_service.dart';
import 'package:olu_ai/features/visits/application/transcription_service.dart';
import 'package:olu_ai/features/visits/application/llm_service.dart';
import 'package:olu_ai/features/visits/application/tts_service.dart';
import 'package:olu_ai/features/visits/data/visit_repository.dart';

class ActiveVisitScreen extends ConsumerStatefulWidget {
  final int patientId;

  const ActiveVisitScreen({super.key, required this.patientId});

  @override
  ConsumerState<ActiveVisitScreen> createState() => _ActiveVisitScreenState();
}

class _ActiveVisitScreenState extends ConsumerState<ActiveVisitScreen>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  String _transcript = "";
  String? _audioPath;
  String? _aiAnalysis;
  String _liveGuidance = "";
  String _lastSpokenGuidance = "";
  StreamSubscription? _transcriptionSubscription;
  Timer? _guidanceTimer;
  Timer? _durationTimer;
  int _recordingSeconds = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _transcriptionSubscription?.cancel();
    _guidanceTimer?.cancel();
    _durationTimer?.cancel();
    _pulseController.dispose();
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
          final tts = ref.read(ttsServiceProvider);
          if (guidance != _lastSpokenGuidance) {
            _lastSpokenGuidance = guidance;
            await tts.speak(guidance);
          }
        }
      }
    });
  }

  void _startDurationTimer() {
    _recordingSeconds = 0;
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _recordingSeconds++);
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final recorder = ref.watch(audioRecorderServiceProvider);
    final transcriber = ref.watch(transcriptionServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Active Visit'),
        actions: [
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  // Pulsing red dot
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.4, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: value),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                    onEnd: () {},
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_recordingSeconds),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.redAccent,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── Live Insight Card ─────────────────────────────
          if (_isRecording && _liveGuidance.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            theme.colorScheme.tertiary.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: theme.colorScheme.tertiary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Clinical Insight',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInsightSection(
                          theme: theme,
                          title: 'Possibilities',
                          icon: Icons.analytics_outlined,
                          content: _parseInsight(_liveGuidance, 'DIFFERENTIAL'),
                        ),
                        const SizedBox(height: 8),
                        _buildInsightSection(
                          theme: theme,
                          title: 'Next Steps',
                          icon: Icons.checklist_rtl_rounded,
                          content: _parseInsight(_liveGuidance, 'NEXT STEPS'),
                        ),
                        const SizedBox(height: 8),
                        _buildInsightSection(
                          theme: theme,
                          title: 'Probing Questions',
                          icon: Icons.contact_support_outlined,
                          content: _parseInsight(_liveGuidance, 'GUIDANCE'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ─── Transcript Area ───────────────────────────────
          Expanded(
            child: _transcript.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isRecording
                              ? Icons.hearing_rounded
                              : Icons.mic_none_rounded,
                          size: 56,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isRecording
                              ? 'Listening...'
                              : 'Tap the mic to start recording',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        _transcript,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.7,
                        ),
                      ),
                    ),
                  ),
          ),

          // ─── Bottom Controls ───────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mic button
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale:
                            _isRecording ? _pulseAnimation.value : 1.0,
                        child: child,
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring when recording
                        if (_isRecording)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOut,
                            builder: (context, value, _) {
                              return Container(
                                width: 88 + (16 * value),
                                height: 88 + (16 * value),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.redAccent
                                        .withValues(alpha: 0.3 * (1 - value)),
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                            onEnd: () {},
                          ),
                        // Main button
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: FloatingActionButton.large(
                            heroTag: 'record_fab',
                            onPressed: () async {
                              if (_isRecording) {
                                _pulseController.stop();
                                _durationTimer?.cancel();
                                await _transcriptionSubscription?.cancel();
                                _guidanceTimer?.cancel();
                                final path = await recorder.stopRecording();
                                await ref.read(ttsServiceProvider).stop();
                                setState(() {
                                  _isRecording = false;
                                  _audioPath = path;
                                  _liveGuidance = "";
                                  _lastSpokenGuidance = "";
                                });
                              } else {
                                final path =
                                    await recorder.generateRecordingPath();
                                setState(() {
                                  _transcript = "";
                                  _liveGuidance = "";
                                  _audioPath = path;
                                });

                                final audioStream =
                                    await recorder.startAudioStream(path);
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
                                _startDurationTimer();
                                _pulseController.repeat(reverse: true);

                                setState(() {
                                  _isRecording = true;
                                });
                              }
                            },
                            backgroundColor: _isRecording
                                ? Colors.redAccent
                                : theme.colorScheme.primary,
                            shape: const CircleBorder(),
                            elevation: _isRecording ? 8 : 4,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _isRecording ? Icons.stop_rounded : Icons.mic,
                                key: ValueKey(_isRecording),
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isRecording ? 'Tap to stop' : 'Tap to record',
                  style: theme.textTheme.bodySmall,
                ),

                // Analyze button
                if (_transcript.isNotEmpty && !_isRecording) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _analyzeVisit(context),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                      label: const Text('Analyze Visit'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeVisit(BuildContext context) async {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text('Analyzing visit...', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );

    final llm = ref.read(llmServiceProvider);
    final analysis = await llm.analyzeVisit(_transcript);
    setState(() {
      _aiAnalysis = analysis;
    });

    if (context.mounted) {
      Navigator.pop(context); // Hide loading
      _showAnalysisSheet(context, analysis);
    }
  }

  void _showAnalysisSheet(BuildContext context, String analysis) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFF003D36),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI Analysis',
                          style: theme.textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Analysis content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        analysis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.7,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final repository = await ref
                              .read(visitRepositoryProvider.future);

                          await repository.addVisit(VisitsCompanion.insert(
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
                        icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 20),
                        label: const Text('Save Visit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required String content,
  }) {
    if (content.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 14,
            color: theme.colorScheme.tertiary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _parseInsight(String fullText, String tag) {
    try {
      final tagPattern = '$tag:';
      if (!fullText.contains(tagPattern)) return "";

      final start = fullText.indexOf(tagPattern) + tagPattern.length;
      final remaining = fullText.substring(start);

      // Find the next tag to stop at
      final nextTagIndex = remaining.indexOf(RegExp(r'[A-Z ]+:'));
      final content = nextTagIndex != -1
          ? remaining.substring(0, nextTagIndex)
          : remaining;

      return content.trim();
    } catch (e) {
      return "";
    }
  }
}
