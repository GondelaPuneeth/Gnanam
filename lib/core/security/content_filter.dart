/// Implements strict child-safety content filtering.
class ContentFilter {
  
  // A simple hardcoded blocklist. In production, this can be loaded from the assets JSON.
  static const List<String> _blockedKeywords = [
    'violence',
    'gore',
    'explicit',
    'self-harm',
    'suicide',
    // ... extensive list of banned educational terms
  ];

  /// Checks if the user's input violates safety policies.
  static bool isSafeInput(String text) {
    final lowerText = text.toLowerCase();
    for (final keyword in _blockedKeywords) {
      if (lowerText.contains(keyword)) {
        return false;
      }
    }
    return true;
  }

  /// Checks if the LLM's generated output violates safety policies.
  /// Usually required for completely uncensored models, but Gemma base models 
  /// have some inherent safety. We still filter just in case.
  static bool isSafeOutput(String text) {
    return isSafeInput(text);
  }
}
