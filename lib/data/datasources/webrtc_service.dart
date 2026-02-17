/// AI Muse — WebRTC Service
/// Manages WebRTC peer connections for voice and video calls.
library;

import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants/api_constants.dart';

/// Callback types for WebRTC events.
typedef OnTrackCallback = void Function(RTCTrackEvent event);
typedef OnIceCandidateCallback = void Function(RTCIceCandidate candidate);
typedef OnConnectionStateCallback = void Function(
    RTCPeerConnectionState state);

/// Service for managing WebRTC peer connections.
class WebRTCService {
  RTCPeerConnection? _peerConnection;
  WebSocketChannel? _signalingChannel;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // Callbacks
  OnTrackCallback? onTrack;
  OnIceCandidateCallback? onIceCandidate;
  OnConnectionStateCallback? onConnectionState;

  /// Whether the connection is active.
  bool get isConnected =>
      _peerConnection?.connectionState ==
      RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  /// ICE server configuration for STUN/TURN.
  static const Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      // Add TURN servers for production:
      // {
      //   'urls': 'turn:turn.aimuse.app:3478',
      //   'username': 'user',
      //   'credential': 'pass',
      // },
    ],
  };

  /// Initialize WebRTC and connect to signaling server.
  Future<void> initialize({
    required String roomId,
    bool videoEnabled = false,
  }) async {
    // Create peer connection
    _peerConnection = await createPeerConnection(_iceConfig);

    // Handle remote track
    _peerConnection!.onTrack = (event) {
      _remoteStream = event.streams.first;
      onTrack?.call(event);
    };

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (candidate) {
      _sendSignalingMessage({
        'type': 'candidate',
        'candidate': candidate.toMap(),
      });
      onIceCandidate?.call(candidate);
    };

    // Handle connection state changes
    _peerConnection!.onConnectionState = (state) {
      onConnectionState?.call(state);
    };

    // Get local media stream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': videoEnabled
          ? {
              'facingMode': 'user',
              'width': {'ideal': 640},
              'height': {'ideal': 480},
            }
          : false,
    });

    // Add tracks to peer connection
    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    // Connect to signaling server
    _connectSignaling(roomId);
  }

  /// Connect to the WebSocket signaling server.
  void _connectSignaling(String roomId) {
    _signalingChannel = WebSocketChannel.connect(
      Uri.parse('${ApiConstants.signalingUrl}?room=$roomId'),
    );

    _signalingChannel!.stream.listen(
      (message) => _handleSignalingMessage(jsonDecode(message)),
      onError: (e) {
        // ignore: avoid_print
        print('WebRTC signaling error: $e');
      },
    );

    // Announce join
    _sendSignalingMessage({'type': 'join', 'room': roomId});
  }

  /// Handle incoming signaling messages.
  Future<void> _handleSignalingMessage(Map<String, dynamic> message) async {
    switch (message['type']) {
      case 'offer':
        final offer = RTCSessionDescription(
          message['sdp'],
          message['type'],
        );
        await _peerConnection!.setRemoteDescription(offer);
        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);
        _sendSignalingMessage({
          'type': 'answer',
          'sdp': answer.sdp,
        });
        break;

      case 'answer':
        final answer = RTCSessionDescription(
          message['sdp'],
          message['type'],
        );
        await _peerConnection!.setRemoteDescription(answer);
        break;

      case 'candidate':
        final candidate = RTCIceCandidate(
          message['candidate']['candidate'],
          message['candidate']['sdpMid'],
          message['candidate']['sdpMLineIndex'],
        );
        await _peerConnection!.addCandidate(candidate);
        break;

      case 'join':
        // Create offer when someone joins
        final offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);
        _sendSignalingMessage({
          'type': 'offer',
          'sdp': offer.sdp,
        });
        break;
    }
  }

  /// Send a message through the signaling channel.
  void _sendSignalingMessage(Map<String, dynamic> message) {
    _signalingChannel?.sink.add(jsonEncode(message));
  }

  /// Toggle local audio mute.
  void toggleMute(bool muted) {
    if (_localStream == null) return;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = !muted;
    }
  }

  /// Toggle local video.
  void toggleVideo(bool enabled) {
    if (_localStream == null) return;
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = enabled;
    }
  }

  /// Get the local media stream.
  MediaStream? get localStream => _localStream;

  /// Get the remote media stream.
  MediaStream? get remoteStream => _remoteStream;

  /// Clean up all resources.
  Future<void> dispose() async {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _remoteStream?.dispose();
    await _peerConnection?.close();
    await _signalingChannel?.sink.close();
  }
}
