import 'dart:async';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:olu_ai/features/visits/application/transcription_service.dart';
import 'package:olu_ai/services/sahara_streaming_client.dart';

enum AsrSource { saharaStreaming, sherpaLocal, mixed }

enum AsrRouteStatus {
  starting,
  saharaStreaming,
  sherpaLocal,
  mixedSource,
  stopped,
}

class AsrRouteEvent {
  final AsrRouteStatus status;
  final AsrSource source;
  final String message;
  final Object? error;
  final DateTime occurredAt;

  AsrRouteEvent({
    required this.status,
    required this.source,
    required this.message,
    this.error,
    DateTime? occurredAt,
  }) : occurredAt = occurredAt ?? DateTime.now();
}

class AsrSession {
  AsrSession._({required AsrSource initialSource}) : _source = initialSource;

  final _transcriptController = StreamController<TranscriptSegment>.broadcast();
  final _transcriptTextController = StreamController<String>.broadcast();
  final _eventController = StreamController<AsrRouteEvent>.broadcast();
  final _disposeCallbacks = <FutureOr<void> Function()>[];

  AsrSource _source;
  String _committedTranscript = '';
  String _latestTranscriptText = '';
  bool _isStopped = false;

  Stream<TranscriptSegment> get liveTranscript => _transcriptController.stream;
  Stream<String> get transcriptText => _transcriptTextController.stream;
  Stream<AsrRouteEvent> get events => _eventController.stream;
  AsrSource get source => _source;
  String get latestTranscriptText => _latestTranscriptText;
  bool get isStopped => _isStopped;

  Future<void> stop() async {
    if (_isStopped) return;

    _isStopped = true;
    for (final callback in _disposeCallbacks.reversed) {
      await callback();
    }
    _eventController.add(AsrRouteEvent(
      status: AsrRouteStatus.stopped,
      source: _source,
      message: 'ASR session stopped.',
    ));
    await _transcriptController.close();
    await _transcriptTextController.close();
    await _eventController.close();
  }

  void _addTranscript(TranscriptSegment segment) {
    if (!_isStopped) {
      _updateTranscriptText(segment);
      _transcriptController.add(segment);
      _transcriptTextController.add(_latestTranscriptText);
    }
  }

  void _addEvent(AsrRouteEvent event) {
    if (!_isStopped) {
      _eventController.add(event);
    }
  }

  void _setSource(AsrSource source) {
    _source = source;
  }

  void _onDispose(FutureOr<void> Function() callback) {
    _disposeCallbacks.add(callback);
  }

  void _updateTranscriptText(TranscriptSegment segment) {
    if (segment.kind == TranscriptSegmentKind.committed) {
      _committedTranscript =
          _joinTranscript(_committedTranscript, segment.text);
      _latestTranscriptText = _committedTranscript;
      return;
    }

    if (segment.source == 'sherpa_local' && _source != AsrSource.mixed) {
      _latestTranscriptText = segment.text;
      return;
    }

    _latestTranscriptText = _joinTranscript(_committedTranscript, segment.text);
  }

  String _joinTranscript(String prefix, String suffix) {
    if (prefix.isEmpty) return suffix;
    if (suffix.isEmpty) return prefix;
    return '$prefix $suffix';
  }
}

class AsrRouter {
  AsrRouter({
    required TranscriptionService sherpaTranscriptionService,
    required SaharaStreamingClient saharaStreamingClient,
    Connectivity? connectivity,
  })  : _sherpaTranscriptionService = sherpaTranscriptionService,
        _saharaStreamingClient = saharaStreamingClient,
        _connectivity = connectivity ?? Connectivity();

  final TranscriptionService _sherpaTranscriptionService;
  final SaharaStreamingClient _saharaStreamingClient;
  final Connectivity _connectivity;

  AsrSession? _activeSession;

  Future<AsrSession> startEncounter({
    required Stream<Uint8List> audioStream,
    String? saharaApiKey,
    String languageCode = 'sw',
  }) async {
    if (_activeSession?.isStopped == false) {
      throw StateError('An ASR session is already active.');
    }

    final broadcastAudioStream = audioStream.asBroadcastStream();
    final session = AsrSession._(initialSource: AsrSource.sherpaLocal);
    _activeSession = session;
    session._onDispose(() {
      if (identical(_activeSession, session)) {
        _activeSession = null;
      }
    });

    session._addEvent(AsrRouteEvent(
      status: AsrRouteStatus.starting,
      source: session.source,
      message: 'Selecting ASR engine.',
    ));

    final online = await _hasNetworkConnection();
    final apiKey = saharaApiKey?.trim();

    if (!online || apiKey == null || apiKey.isEmpty) {
      _startSherpa(
        session: session,
        audioStream: broadcastAudioStream,
        message: online
            ? 'Missing Sahara API key; using local Sherpa ASR.'
            : 'No network connection; using local Sherpa ASR.',
      );
      return session;
    }

    await _startSahara(
      session: session,
      audioStream: broadcastAudioStream,
      apiKey: apiKey,
      languageCode: languageCode,
    );

    return session;
  }

  Future<bool> _hasNetworkConnection() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> _startSahara({
    required AsrSession session,
    required Stream<Uint8List> audioStream,
    required String apiKey,
    required String languageCode,
  }) async {
    var fallbackStarted = false;

    final transcriptSubscription = _saharaStreamingClient.liveTranscript.listen(
      session._addTranscript,
      onError: (Object error, StackTrace stackTrace) {
        if (!fallbackStarted) {
          fallbackStarted = true;
          _startSherpa(
            session: session,
            audioStream: audioStream,
            source: AsrSource.mixed,
            message:
                'Sahara transcript stream failed; using Sherpa for remaining audio.',
            error: error,
          );
        }
      },
    );

    final eventSubscription = _saharaStreamingClient.events.listen((event) {
      if (event.status == SaharaStreamingStatus.fallbackRequired &&
          !fallbackStarted) {
        fallbackStarted = true;
        final fallbackSource = session.source == AsrSource.saharaStreaming
            ? AsrSource.mixed
            : AsrSource.sherpaLocal;
        _startSherpa(
          session: session,
          audioStream: audioStream,
          source: fallbackSource,
          message: event.message ??
              'Sahara requested fallback; using Sherpa for remaining audio.',
          error: event.error,
        );
        return;
      }

      session._addEvent(AsrRouteEvent(
        status: _mapSaharaStatus(event.status),
        source: session.source,
        message: event.message ?? 'Sahara streaming status changed.',
        error: event.error,
        occurredAt: event.occurredAt,
      ));
    });

    session._onDispose(transcriptSubscription.cancel);
    session._onDispose(eventSubscription.cancel);
    session._onDispose(_saharaStreamingClient.stop);

    try {
      await _saharaStreamingClient.start(
        audioStream: audioStream,
        apiKey: apiKey,
        languageCode: languageCode,
      );
    } catch (error) {
      if (!fallbackStarted) {
        fallbackStarted = true;
        _startSherpa(
          session: session,
          audioStream: audioStream,
          message: 'Sahara failed to start; using local Sherpa ASR.',
          error: error,
        );
      }
      return;
    }

    session._setSource(AsrSource.saharaStreaming);
    session._addEvent(AsrRouteEvent(
      status: AsrRouteStatus.saharaStreaming,
      source: AsrSource.saharaStreaming,
      message: 'Using Sahara streaming ASR.',
    ));
  }

  void _startSherpa({
    required AsrSession session,
    required Stream<Uint8List> audioStream,
    required String message,
    AsrSource source = AsrSource.sherpaLocal,
    Object? error,
  }) {
    if (session.isStopped) return;

    session._setSource(source);
    session._addEvent(AsrRouteEvent(
      status: source == AsrSource.mixed
          ? AsrRouteStatus.mixedSource
          : AsrRouteStatus.sherpaLocal,
      source: source,
      message: message,
      error: error,
    ));

    final subscription = _sherpaTranscriptionService
        .transcribeStream(audioStream)
        .listen((transcript) {
      session._addTranscript(TranscriptSegment(
        text: transcript,
        kind: TranscriptSegmentKind.partial,
        receivedAt: DateTime.now(),
        sessionIndex: 0,
        source: 'sherpa_local',
      ));
    }, onError: (Object streamError, StackTrace stackTrace) {
      session._addEvent(AsrRouteEvent(
        status: source == AsrSource.mixed
            ? AsrRouteStatus.mixedSource
            : AsrRouteStatus.sherpaLocal,
        source: source,
        message: 'Sherpa ASR stream failed.',
        error: streamError,
      ));
    });

    session._onDispose(subscription.cancel);
  }

  AsrRouteStatus _mapSaharaStatus(SaharaStreamingStatus status) {
    switch (status) {
      case SaharaStreamingStatus.connecting:
      case SaharaStreamingStatus.reconnecting:
        return AsrRouteStatus.starting;
      case SaharaStreamingStatus.connected:
        return AsrRouteStatus.saharaStreaming;
      case SaharaStreamingStatus.fallbackRequired:
        return AsrRouteStatus.mixedSource;
      case SaharaStreamingStatus.closed:
        return AsrRouteStatus.stopped;
    }
  }
}

final asrRouterProvider = Provider<AsrRouter>((ref) {
  return AsrRouter(
    sherpaTranscriptionService: ref.watch(transcriptionServiceProvider),
    saharaStreamingClient: ref.watch(saharaStreamingClientProvider),
  );
});
