/// Monitors memory usage and protects the offline LLM from Out-Of-Memory (OOM) crashes.
class MemoryGuardian {
  
  // A rough estimate of memory available. True RAM checks require platform channels.
  // For now, we enforce a strict upper limit on total token usage based on the device profile.
  static const int _maxSafeTokensLowRam = 1024;
  static const int _maxSafeTokensHighRam = 4096;

  final bool isLowRamDevice;

  MemoryGuardian({this.isLowRamDevice = false});

  /// Evaluates if the current context + projected new tokens will exceed safe memory limits.
  /// 
  /// Throws an [Exception] if memory limits are exceeded.
  void ensureSafeMemory(int currentTokens, int estimatedNewTokens) {
    final maxAllowed = isLowRamDevice ? _maxSafeTokensLowRam : _maxSafeTokensHighRam;
    final projected = currentTokens + estimatedNewTokens;

    if (projected > maxAllowed) {
      throw Exception(
        'OOM Risk Detected: Projected token count ($projected) exceeds safe limits ($maxAllowed). '
        'Context pruning required.',
      );
    }
  }

  /// Calculates a safe token limit for the current generation based on current context.
  int calculateSafeGenerationLimit(int currentTokens) {
    final maxAllowed = isLowRamDevice ? _maxSafeTokensLowRam : _maxSafeTokensHighRam;
    final available = maxAllowed - currentTokens;
    return available > 0 ? available : 0;
  }
}
