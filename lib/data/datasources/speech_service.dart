/// AI Muse — Speech Service
/// Wraps speech-to-text and text-to-speech for voice interactions.
library;

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Service for bidirectional voice communication with AI.
class SpeechService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeaking = false;

  /// Whether the STT engine is currently listening.
  bool get isListening => _isListening;

  /// Whether the TTS engine is currently speaking.
  bool get isSpeaking => _isSpeaking;

  /// Initialize both TTS and STT engines.
  Future<void> initialize() async {
    // TTS setup
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);

    // STT setup
    await _stt.initialize();
  }

  /// Set the TTS voice by voice ID (mapped from persona config).
  Future<void> setVoice(String voiceId) async {
    // Map persona voiceId to system TTS voice
    // This is a simplified mapping — production apps would use
    // a more sophisticated voice selection system
    final voices = await _tts.getVoices;
    if (voices != null && voices is List && voices.isNotEmpty) {
      // Try to find a matching voice, otherwise use default
      await _tts.setVoice({'name': voiceId, 'locale': 'en-US'});
    }
  }

  /// Set the language for both TTS and STT.
  Future<void> setLanguage(String langCode) async {
    String ttsLang;
    switch (langCode) {
      case 'hi':
        ttsLang = 'hi-IN';
        break;
      case 'ko':
        ttsLang = 'ko-KR';
        break;
      default:
        ttsLang = 'en-US';
    }
    await _tts.setLanguage(ttsLang);
  }

  /// Speak the given text using TTS.
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _tts.speak(text);
  }

  /// Stop speaking.
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  /// Start listening for speech input.
  /// Returns recognized text via the [onResult] callback.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String locale = 'en_US',
  }) async {
    if (_isListening) return;

    _isListening = true;
    await _stt.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      localeId: locale,
      listenMode: stt.ListenMode.dictation,
      cancelOnError: false,
      partialResults: true,
    );
  }

  /// Stop listening for speech input.
  Future<void> stopListening() async {
    if (!_isListening) return;
    await _stt.stop();
    _isListening = false;
  }

  /// Natural interruption: stop TTS and start listening.
  Future<void> interrupt({
    required void Function(String text, bool isFinal) onResult,
    String locale = 'en_US',
  }) async {
    await stopSpeaking();
    await startListening(onResult: onResult, locale: locale);
  }

  /// Clean up resources.
  Future<void> dispose() async {
    await stopSpeaking();
    await stopListening();
  }
}
