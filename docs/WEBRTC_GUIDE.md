# AI Muse — WebRTC Integration Guide

## Architecture Overview

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│  Flutter App  │◄─────►│  Signaling   │◄─────►│ AI Backend   │
│  (WebRTC)     │       │  Server      │       │ (STT → GPT   │
│               │       │  (Socket.IO) │       │  → TTS)       │
└──────────────┘       └──────────────┘       └──────────────┘
       ▲                                              │
       │            STUN/TURN                         │
       └──────────── ICE Candidates ──────────────────┘
```

## Voice Call Flow

1. **User initiates call** → VoiceCallScreen opens
2. **WebRTC setup** → WebRTCService connects to signaling server
3. **ICE negotiation** → STUN/TURN servers help establish P2P connection
4. **Audio stream** → User's mic audio → STT → text → AI
5. **AI response** → GPT generates text → TTS → audio stream to user
6. **Real-time loop** → Continuous conversation with natural interruption

## Video Call Flow

Same as voice, plus:
1. **Camera stream** → User's camera feed displayed in PiP
2. **AI avatar** → Generated avatar rendered on full screen
3. **Lip sync** → TTS audio drives lip animation on avatar
4. **Emotions** → AI emotional state maps to avatar expressions

## Implementation

### WebRTCService (`lib/data/datasources/webrtc_service.dart`)

```dart
// Initialize
final webrtc = WebRTCService();
await webrtc.initialize(roomId: 'call-$userId-$personaId', videoEnabled: true);

// Handle events
webrtc.onTrack = (event) => /* render remote stream */;
webrtc.onConnectionState = (state) => /* update UI */;

// Controls
webrtc.toggleMute(true);
webrtc.toggleVideo(false);

// Cleanup
await webrtc.dispose();
```

### SpeechService (`lib/data/datasources/speech_service.dart`)

```dart
// Initialize
final speech = SpeechService();
await speech.initialize();
await speech.setVoice(persona.voiceId);

// Text-to-Speech
await speech.speak("Hello! How are you?");

// Speech-to-Text
await speech.startListening(onResult: (text, isFinal) {
  if (isFinal) sendToAI(text);
});

// Natural interruption
await speech.interrupt(onResult: (text, isFinal) { ... });
```

### Signaling Server (`server/signaling.js`)

The signaling server uses Socket.IO for:
- Room management (join/leave)
- SDP offer/answer relay
- ICE candidate exchange
- Connection state tracking

---

## STUN/TURN Configuration

For production, add TURN servers for NAT traversal:

```dart
static const Map<String, dynamic> _iceConfig = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    {
      'urls': 'turn:turn.yourdomain.com:3478',
      'username': 'your-username',
      'credential': 'your-password',
    },
  ],
};
```

Recommended TURN providers:
- **Twilio** — Network Traversal Service
- **Cloudflare** — TURN service
- **Self-hosted** — coturn on Linux VPS

---

## Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>Camera is required for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone is required for voice and video calls</string>
