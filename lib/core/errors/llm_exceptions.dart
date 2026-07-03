/// Custom exception hierarchy for LLM inference operations.
///
/// Provides typed exceptions for every failure mode the inference layer
/// can encounter, enabling precise error handling at the UI layer.
library;

/// Base exception for all LLM-related errors.
class LlmException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const LlmException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => 'LlmException: $message';
}

/// Thrown when a model file fails to load (corrupt, missing, wrong format).
class ModelLoadException extends LlmException {
  final String? modelPath;

  const ModelLoadException(
    super.message, {
    this.modelPath,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'ModelLoadException: $message${modelPath != null ? ' (path: $modelPath)' : ''}';
}

/// Thrown when inference (token generation) fails mid-stream.
class InferenceException extends LlmException {
  final int? tokensGenerated;

  const InferenceException(
    super.message, {
    this.tokensGenerated,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'InferenceException: $message${tokensGenerated != null ? ' (tokens generated: $tokensGenerated)' : ''}';
}

/// Thrown when a LoRA adapter fails to load, apply, or clear.
class LoraException extends LlmException {
  final String? loraPath;

  const LoraException(
    super.message, {
    this.loraPath,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'LoraException: $message${loraPath != null ? ' (path: $loraPath)' : ''}';
}

/// Thrown when the device runs out of memory during model operations.
class OutOfMemoryException extends LlmException {
  final int? availableMemoryMb;
  final int? requiredMemoryMb;

  const OutOfMemoryException(
    super.message, {
    this.availableMemoryMb,
    this.requiredMemoryMb,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'OutOfMemoryException: $message (available: ${availableMemoryMb ?? '?'} MB, required: ${requiredMemoryMb ?? '?'} MB)';
}

/// Thrown when a model download fails (network, checksum mismatch, disk space).
class ModelDownloadException extends LlmException {
  final String? url;
  final int? httpStatusCode;

  const ModelDownloadException(
    super.message, {
    this.url,
    this.httpStatusCode,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'ModelDownloadException: $message${url != null ? ' (url: $url)' : ''}';
}

/// Thrown when SHA-256 verification of a downloaded file fails.
class ChecksumMismatchException extends ModelDownloadException {
  final String? expectedHash;
  final String? actualHash;

  const ChecksumMismatchException(
    super.message, {
    this.expectedHash,
    this.actualHash,
    super.url,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'ChecksumMismatchException: $message (expected: ${expectedHash ?? '?'}, actual: ${actualHash ?? '?'})';
}

/// Thrown when content filtering blocks an input or output.
class ContentFilteredException extends LlmException {
  final String? category;

  const ContentFilteredException(
    super.message, {
    this.category,
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() =>
      'ContentFilteredException: $message${category != null ? ' (category: $category)' : ''}';
}
