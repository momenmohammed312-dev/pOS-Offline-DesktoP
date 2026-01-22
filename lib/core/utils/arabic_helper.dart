import 'arabic_reshaper/arabic_reshaper.dart';

class ArabicHelper {
  /// Enhanced Arabic text processing for PDF rendering with proper text shaping.
  /// This provides Arabic text reshaping and RTL support for PDF content.
  static String reshapedText(String text) {
    if (text.isEmpty) return text;

    try {
      // Use the actual ArabicReshaper to handle contextual forms and ligatures
      return ArabicReshaper.instance.reshape(text);
    } catch (e) {
      // Fallback to original text if reshaping fails
      return text;
    }
  }
}
