import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Wraps [FlutterTts] to provide text-to-speech output for CHW live guidance.
///
/// Audio is configured to route to the active Bluetooth audio device (A2DP)
/// on Android automatically. On iOS, the shared audio session category is set
/// to [IosTextToSpeechAudioCategory.playback] with the
/// [IosTextToSpeechAudioCategoryOptions.allowBluetooth] option so that speech
/// is delivered through a paired Bluetooth earpiece.
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  String _lastSpokenText = '';

  Future<void> initialize() async {
    if (_isInitialized) return;

    // iOS: share the audio session and allow Bluetooth A2DP output.
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
      IosTextToSpeechAudioMode.defaultMode,
    );

    await _tts.setLanguage('en-US');

    // Slightly slower pace for clinical context — easier to follow while
    // simultaneously conducting a patient consultation.
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setErrorHandler((message) {
      debugPrint('TtsService error: $message');
    });

    _isInitialized = true;
    debugPrint('TtsService initialised');
  }

  /// Speaks [text] through the active audio output (Bluetooth earpiece / speaker).
  ///
  /// If [text] is identical to the last spoken suggestion, the call is a no-op
  /// so that the periodic guidance timer does not re-read the same hint on
  /// every tick.
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();

    final cleaned = text.trim();
    if (cleaned.isEmpty || cleaned == _lastSpokenText) return;

    // Cancel any in-progress speech before starting the new utterance.
    await _tts.stop();

    _lastSpokenText = cleaned;
    await _tts.speak(cleaned);
  }

  /// Stops any currently playing speech immediately.
  Future<void> stop() async {
    if (!_isInitialized) return;
    _lastSpokenText = '';
    await _tts.stop();
  }

  Future<void> dispose() async {
    await stop();
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(() => service.dispose());
  return service;
});
