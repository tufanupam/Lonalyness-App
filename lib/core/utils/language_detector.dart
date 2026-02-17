/// AI Muse — Language Detector
/// Auto-detects input language using character range heuristics.
library;

/// Detects the language of input text.
/// Supports English, Hindi (Devanagari), and Korean (Hangul).
class LanguageDetector {
  LanguageDetector._();

  /// Detect the primary language of the given text.
  /// Returns language code: 'en', 'hi', or 'ko'.
  static String detect(String text) {
    if (text.isEmpty) return 'en';

    int hindiCount = 0;
    int koreanCount = 0;
    int totalAlpha = 0;

    for (final codeUnit in text.runes) {
      // Devanagari script (Hindi): U+0900 - U+097F
      if (codeUnit >= 0x0900 && codeUnit <= 0x097F) {
        hindiCount++;
        totalAlpha++;
      }
      // Hangul (Korean): U+AC00 - U+D7AF (syllables) 
      // + U+1100 - U+11FF (jamo)
      // + U+3130 - U+318F (compatibility jamo)
      else if ((codeUnit >= 0xAC00 && codeUnit <= 0xD7AF) ||
          (codeUnit >= 0x1100 && codeUnit <= 0x11FF) ||
          (codeUnit >= 0x3130 && codeUnit <= 0x318F)) {
        koreanCount++;
        totalAlpha++;
      }
      // ASCII letters
      else if ((codeUnit >= 0x41 && codeUnit <= 0x5A) ||
          (codeUnit >= 0x61 && codeUnit <= 0x7A)) {
        totalAlpha++;
      }
    }

    if (totalAlpha == 0) return 'en';

    // If > 30% of characters are Devanagari, it's Hindi
    if (hindiCount / totalAlpha > 0.3) return 'hi';

    // If > 30% of characters are Hangul, it's Korean
    if (koreanCount / totalAlpha > 0.3) return 'ko';

    // Default to English
    return 'en';
  }

  /// Get the display name for a language code.
  static String getLanguageName(String code) {
    switch (code) {
      case 'hi':
        return 'Hindi';
      case 'ko':
        return 'Korean';
      case 'en':
      default:
        return 'English';
    }
  }

  /// Get STT locale for a language code.
  static String getSttLocale(String code) {
    switch (code) {
      case 'hi':
        return 'hi_IN';
      case 'ko':
        return 'ko_KR';
      case 'en':
      default:
        return 'en_US';
    }
  }
}
