import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _saharaStreamingEndpoint = 'wss://infer.voice.intron.io/stt/v1/stream';
const _defaultSampleRate = 16000;
const _defaultBitRate = 16;
const _defaultChannels = 1;
const _minChunkBytes = 1024;
const _maxChunkBytes = 32 * 1024;
const _idleLimit = Duration(seconds: 60);
const _rollingReconnectAt = Duration(seconds: 270);

enum TranscriptSegmentKind { partial, committed }

enum SaharaStreamingStatus {
  connecting,
  connected,
  reconnecting,
  fallbackRequired,
  closed,
}

class TranscriptSegment {
  final String text;
  final TranscriptSegmentKind kind;
  final DateTime receivedAt;
  final int sessionIndex;
  final String source;

  const TranscriptSegment({
    required this.text,
    required this.kind,
    required this.receivedAt,
    required this.sessionIndex,
    this.source = 'sahara_streaming',
  });
}

class SaharaStreamingEvent {
  final SaharaStreamingStatus status;
  final String? message;
  final Object? error;
  final DateTime occurredAt;

  SaharaStreamingEvent({
    required this.status,
    this.message,
    this.error,
    DateTime? occurredAt,
  }) : occurredAt = occurredAt ?? DateTime.now();
}

class SaharaStreamingException implements Exception {
  final String message;
  final Object? cause;

  const SaharaStreamingException(this.message, [this.cause]);

  @override
  String toString() => cause == null
      ? 'SaharaStreamingException: $message'
      : 'SaharaStreamingException: $message ($cause)';
}

typedef SaharaChannelFactory = WebSocketChannel Function(
  Uri uri,
  Map<String, dynamic> headers,
);

class SaharaStreamingClient {
  SaharaStreamingClient({
    SaharaChannelFactory? channelFactory,
    this.sessionReconnectAt = _rollingReconnectAt,
    this.idleReconnectAfter = _idleLimit,
  }) : _channelFactory = channelFactory ?? _connectChannel;

  final SaharaChannelFactory _channelFactory;
  final Duration sessionReconnectAt;
  final Duration idleReconnectAfter;

  final _transcriptController = StreamController<TranscriptSegment>.broadcast();
  final _eventController = StreamController<SaharaStreamingEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription? _socketSubscription;
  StreamSubscription<Uint8List>? _audioSubscription;
  Timer? _sessionTimer;
  Timer? _idleTimer;
  String? _apiKey;
  String _languageCode = 'sw';
  Uint8List _pendingAudio = Uint8List(0);
  int _sessionIndex = 0;
  bool _isActive = false;
  bool _isReconnecting = false;
  bool _fallbackRequired = false;

  Stream<TranscriptSegment> get liveTranscript => _transcriptController.stream;
  Stream<SaharaStreamingEvent> get events => _eventController.stream;
  bool get fallbackRequired => _fallbackRequired;

  Future<void> start({
    required Stream<Uint8List> audioStream,
    required String apiKey,
    String languageCode = 'sw',
  }) async {
    if (_isActive) {
      throw const SaharaStreamingException('Streaming session already active.');
    }

    _apiKey = apiKey;
    _languageCode = languageCode;
    _pendingAudio = Uint8List(0);
    _isActive = true;
    _fallbackRequired = false;

    try {
      await _openSession();
    } catch (error) {
      _requireFallback('Unable to establish Sahara streaming session.', error);
      rethrow;
    }

    _audioSubscription = audioStream.listen(
      _sendAudioChunk,
      onError: (Object error, StackTrace stackTrace) {
        _requireFallback('Audio stream failed.', error);
      },
      onDone: () => stop(),
      cancelOnError: false,
    );
  }

  Future<void> stop() async {
    if (!_isActive) return;

    _isActive = false;
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    _flushPendingAudio();
    await _commitCurrentSession();
    await _closeSocket();
    _eventController.add(SaharaStreamingEvent(
      status: SaharaStreamingStatus.closed,
      message: 'Sahara streaming session closed.',
    ));
  }

  Future<void> dispose() async {
    await stop();
    await _transcriptController.close();
    await _eventController.close();
  }

  Future<void> _openSession() async {
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw const SaharaStreamingException('Missing Sahara API key.');
    }

    _eventController.add(SaharaStreamingEvent(
      status: _sessionIndex == 0
          ? SaharaStreamingStatus.connecting
          : SaharaStreamingStatus.reconnecting,
      message: 'Opening Sahara streaming session.',
    ));

    final uri = Uri.parse(_saharaStreamingEndpoint).replace(
      queryParameters: {
        'sample_rate': '$_defaultSampleRate',
        'bit_rate': '$_defaultBitRate',
        'num_channels': '$_defaultChannels',
        'use_language_asr_input': _languageCode,
      },
    );

    final channel = _channelFactory(uri, {
      'Authorization': 'Bearer $apiKey',
    });

    _channel = channel;
    _socketSubscription = channel.stream.listen(
      _handleSocketMessage,
      onError: (Object error, StackTrace stackTrace) {
        _handleSocketError(error);
      },
      onDone: _handleSocketDone,
      cancelOnError: false,
    );

    _sessionIndex++;
    _scheduleSessionReconnect();
    _scheduleIdleReconnect();
  }

  void _sendAudioChunk(Uint8List chunk) {
    if (!_isActive || _channel == null || _fallbackRequired) return;

    final bytes = _appendPendingAudio(chunk);
    var offset = 0;

    while (bytes.length - offset >= _minChunkBytes) {
      final remaining = bytes.length - offset;
      final chunkSize = remaining > _maxChunkBytes ? _maxChunkBytes : remaining;
      _sendEncodedAudio(
          Uint8List.sublistView(bytes, offset, offset + chunkSize));
      offset += chunkSize;
    }

    _pendingAudio = Uint8List.sublistView(bytes, offset);
    _scheduleIdleReconnect();
  }

  Uint8List _appendPendingAudio(Uint8List chunk) {
    if (_pendingAudio.isEmpty) return chunk;

    final bytes = Uint8List(_pendingAudio.length + chunk.length);
    bytes.setRange(0, _pendingAudio.length, _pendingAudio);
    bytes.setRange(_pendingAudio.length, bytes.length, chunk);
    return bytes;
  }

  void _flushPendingAudio() {
    if (_pendingAudio.isEmpty || _channel == null || _fallbackRequired) return;

    _sendEncodedAudio(_pendingAudio);
    _pendingAudio = Uint8List(0);
  }

  void _sendEncodedAudio(Uint8List chunk) {
    _channel!.sink.add(jsonEncode({
      'type': 'INPUT_AUDIO_CHUNK',
      'audio': base64Encode(chunk),
    }));
  }

  void _handleSocketMessage(dynamic message) {
    if (message is! String) return;

    final data = jsonDecode(message);
    if (data is! Map<String, dynamic>) return;

    final type = data['type']?.toString();
    switch (type) {
      case 'SESSION_CREATED':
        _eventController.add(SaharaStreamingEvent(
          status: SaharaStreamingStatus.connected,
          message: 'Sahara streaming session created.',
        ));
      case 'PARTIAL_TRANSCRIPT':
        _emitTranscript(data, TranscriptSegmentKind.partial);
      case 'COMMITTED_TRANSCRIPT':
        _emitTranscript(data, TranscriptSegmentKind.committed);
      case 'AUDIO_CHUCK_ACK':
      case 'AUDIO_CHUNK_ACK':
        break;
      case 'AUTHENTICATION_ERROR':
      case 'QUOTA_EXCEEDED':
      case 'RESOURCE_EXHAUSTED':
      case 'SESSION_TIME_LIMIT_EXCEEDED':
        _requireFallback('Sahara returned $type.', data);
      default:
        if (type != null && type.endsWith('ERROR')) {
          _requireFallback('Sahara returned $type.', data);
        } else {
          debugPrint('Unhandled Sahara streaming message: $data');
        }
    }
  }

  void _emitTranscript(
    Map<String, dynamic> data,
    TranscriptSegmentKind kind,
  ) {
    final transcript = _extractTranscript(data);
    if (transcript == null || transcript.isEmpty) return;

    _transcriptController.add(TranscriptSegment(
      text: transcript,
      kind: kind,
      receivedAt: DateTime.now(),
      sessionIndex: _sessionIndex,
    ));
  }

  String? _extractTranscript(Map<String, dynamic> data) {
    for (final key in const ['transcript', 'text', 'result']) {
      final value = data[key];
      if (value is String) return value;
    }
    return null;
  }

  Future<void> _reconnect() async {
    if (!_isActive || _isReconnecting || _fallbackRequired) return;

    _isReconnecting = true;
    try {
      await _commitCurrentSession();
      await _closeSocket();
      await _openSession();
    } catch (error) {
      _requireFallback('Failed to reconnect Sahara streaming session.', error);
    } finally {
      _isReconnecting = false;
    }
  }

  Future<void> _commitCurrentSession() async {
    final channel = _channel;
    if (channel == null) return;

    channel.sink.add(jsonEncode({'type': 'COMMIT'}));
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  Future<void> _closeSocket() async {
    _sessionTimer?.cancel();
    _idleTimer?.cancel();
    _sessionTimer = null;
    _idleTimer = null;

    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  void _handleSocketError(Object error) {
    _requireFallback('Sahara streaming socket failed.', error);
  }

  void _handleSocketDone() {
    if (_isActive && !_isReconnecting && !_fallbackRequired) {
      _requireFallback('Sahara streaming socket closed unexpectedly.');
    }
  }

  void _requireFallback(String message, [Object? error]) {
    if (_fallbackRequired) return;

    _fallbackRequired = true;
    _eventController.add(SaharaStreamingEvent(
      status: SaharaStreamingStatus.fallbackRequired,
      message: message,
      error: error,
    ));
    unawaited(_closeSocket());
  }

  void _scheduleSessionReconnect() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(sessionReconnectAt, _reconnect);
  }

  void _scheduleIdleReconnect() {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleReconnectAfter, _reconnect);
  }

  static WebSocketChannel _connectChannel(
    Uri uri,
    Map<String, dynamic> headers,
  ) {
    return IOWebSocketChannel.connect(uri, headers: headers);
  }
}

final saharaStreamingClientProvider = Provider<SaharaStreamingClient>((ref) {
  final client = SaharaStreamingClient();
  ref.onDispose(() => client.dispose());
  return client;
});
