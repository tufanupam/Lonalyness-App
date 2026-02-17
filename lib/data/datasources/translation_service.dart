/// AI Muse — Translation Service
/// Handles real-time translation between supported languages.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';

/// Service for translating text between Hindi, English, and Korean.
class TranslationService {
  /// Translate text from source language to target language.
  /// Uses the AI Muse backend which proxies to a translation API.
  Future<String> translate({
    required String text,
    required String fromLang,
    required String toLang,
  }) async {
    if (text.isEmpty || fromLang == toLang) return text;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.translateEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'source': fromLang,
          'target': toLang,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translatedText'] as String? ?? text;
      }

      return text; // Fallback to original text
    } catch (e) {
      // ignore: avoid_print
      print('Translation error: $e');
      return text; // Fallback to original text
    }
  }

  /// Translate if the detected language differs from the target.
  Future<String> translateIfNeeded({
    required String text,
    required String detectedLang,
    required String targetLang,
  }) async {
    if (detectedLang == targetLang) return text;
    return translate(text: text, fromLang: detectedLang, toLang: targetLang);
  }
}
