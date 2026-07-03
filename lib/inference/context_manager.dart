

/// Manages a sliding window of conversation context within a fixed token budget.
///
/// The context manager tracks conversation turns, estimates token counts,
/// and automatically triggers summarization when the context approaches
/// the token limit. This ensures the LLM always receives a coherent,
/// bounded context without exceeding the 2048-token window.
class ContextManager {
  /// Maximum tokens the context window can hold.
  final int maxTokens;

  /// Threshold (fraction of maxTokens) at which summarization triggers.
  final double summarizationThreshold;

  /// Current conversation turns stored in the window.
  final List<ConversationTurn> _turns = [];

  /// Running estimate of total tokens in the context.
  int _estimatedTokens = 0;

  /// The most recent summary of pruned conversation history.
  String? _summary;

  /// System prompt tokens (counted once, always present).
  int _systemPromptTokens = 0;

  /// The active system prompt.
  String _systemPrompt = '';

  ContextManager({
    this.maxTokens = 2048,
    this.summarizationThreshold = 0.80,
  });

  /// Sets the system prompt. Called once when grade/tier changes.
  void setSystemPrompt(String prompt) {
    _systemPrompt = prompt;
    _systemPromptTokens = _estimateTokens(prompt);
  }

  /// Returns the current system prompt.
  String get systemPrompt => _systemPrompt;

  /// Adds a user message to the context.
  void addUserMessage(String message) {
    final tokens = _estimateTokens(message);
    _turns.add(ConversationTurn(
      role: 'user',
      content: message,
      estimatedTokens: tokens,
    ));
    _estimatedTokens += tokens;
    _pruneIfNeeded();
  }

  /// Adds an assistant response to the context.
  void addAssistantMessage(String message) {
    final tokens = _estimateTokens(message);
    _turns.add(ConversationTurn(
      role: 'assistant',
      content: message,
      estimatedTokens: tokens,
    ));
    _estimatedTokens += tokens;
    _pruneIfNeeded();
  }

  /// Returns the full context as a list of message maps ready for the LLM.
  ///
  /// Format: [{"role": "system", "content": "..."}, {"role": "user", ...}, ...]
  List<Map<String, String>> buildContext() {
    final context = <Map<String, String>>[];

    // System prompt always goes first
    if (_systemPrompt.isNotEmpty) {
      var systemContent = _systemPrompt;
      // Prepend summary of pruned history if available
      if (_summary != null) {
        systemContent +=
            '\n\n[Previous conversation summary: $_summary]';
      }
      context.add({'role': 'system', 'content': systemContent});
    }

    // Add all remaining turns
    for (final turn in _turns) {
      context.add({'role': turn.role, 'content': turn.content});
    }

    return context;
  }

  /// Returns the estimated total token count of the current context.
  int get estimatedTokenCount => _estimatedTokens + _systemPromptTokens;

  /// Returns the number of conversation turns in the window.
  int get turnCount => _turns.length;

  /// Returns true if the context needs summarization.
  bool get needsSummarization =>
      estimatedTokenCount > (maxTokens * summarizationThreshold);

  /// Clears all conversation history (but keeps the system prompt).
  void clearHistory() {
    _turns.clear();
    _estimatedTokens = 0;
    _summary = null;
  }

  /// Clears everything, including the system prompt.
  void reset() {
    clearHistory();
    _systemPrompt = '';
    _systemPromptTokens = 0;
  }

  /// Forces a summary of the oldest turns and removes them.
  ///
  /// In production, this would call the LLM to produce a summary.
  /// For now, it creates a mechanical summary by concatenating key points.
  String pruneTurns(int turnsToRemove) {
    if (turnsToRemove <= 0 || turnsToRemove > _turns.length) return '';

    final removedTurns = _turns.sublist(0, turnsToRemove);
    final summaryParts = <String>[];

    for (final turn in removedTurns) {
      final prefix = turn.role == 'user' ? 'Student asked' : 'Tutor answered';
      // Truncate long messages for the summary
      final truncated = turn.content.length > 100
          ? '${turn.content.substring(0, 100)}...'
          : turn.content;
      summaryParts.add('$prefix: $truncated');
    }

    final newSummary = summaryParts.join('; ');

    // Merge with existing summary if present
    if (_summary != null) {
      _summary = '$_summary; $newSummary';
      // Keep summary itself bounded
      if (_summary!.length > 500) {
        _summary = '${_summary!.substring(0, 500)}...';
      }
    } else {
      _summary = newSummary;
    }

    // Remove the pruned turns and recalculate tokens
    final removedTokens =
        removedTurns.fold<int>(0, (sum, t) => sum + t.estimatedTokens);
    _turns.removeRange(0, turnsToRemove);
    _estimatedTokens -= removedTokens;

    return _summary!;
  }

  /// Prune oldest turns if we're over the summarization threshold.
  void _pruneIfNeeded() {
    if (!needsSummarization) return;

    // Remove oldest quarter of turns
    final turnsToRemove = (_turns.length * 0.25).ceil().clamp(1, _turns.length);
    pruneTurns(turnsToRemove);
  }

  /// Rough token estimation: ~4 characters per token for English text.
  /// This is deliberately conservative to avoid overflowing the real context.
  int _estimateTokens(String text) {
    // Average 4 chars per token for English, ~3 for code/math
    return (text.length / 3.5).ceil();
  }
}

/// A single turn in the conversation history.
class ConversationTurn {
  final String role;
  final String content;
  final int estimatedTokens;
  final DateTime timestamp;

  ConversationTurn({
    required this.role,
    required this.content,
    required this.estimatedTokens,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
