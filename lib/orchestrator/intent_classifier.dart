import 'dart:io';

/// Defines the types of tasks the orchestrator can handle.
enum TaskIntent {
  chat,     // Standard text-based conversation
  vision,   // Image/Camera analysis
  document, // PDF, DOCX, TXT parsing to OKF
}

/// A generic task request structure.
class TaskRequest {
  final TaskIntent intent;
  final String textPrompt;
  final File? attachment;
  final String? documentPath;

  TaskRequest({
    required this.intent,
    required this.textPrompt,
    this.attachment,
    this.documentPath,
  });
}

/// Determines the intent of a user's action.
/// 
/// In an offline app, deterministic UI-based routing is faster and more reliable 
/// than asking the LLM to classify intent, though we could use the LLM as a fallback.
class IntentClassifier {
  
  /// Classifies the intent based on the presence of attachments or specific keywords.
  static TaskIntent classify(String text, {File? imageFile, String? docPath}) {
    // 1. Explicit attachments take highest precedence
    if (imageFile != null) {
      return TaskIntent.vision;
    }
    
    if (docPath != null && docPath.isNotEmpty) {
      return TaskIntent.document;
    }

    // 2. Keyword heuristics as fallback (e.g. if the user says "look at this" but forgot to attach)
    final lowerText = text.toLowerCase();
    if (lowerText.contains('look at') || lowerText.contains('what is in this picture') || lowerText.contains('scan this')) {
      // In a real app, this might trigger the UI to open the camera if no image is attached.
      // For now, we'll route to chat to ask for the image.
      return TaskIntent.chat; 
    }
    
    if (lowerText.contains('read this pdf') || lowerText.contains('summarize the document')) {
      return TaskIntent.chat; 
    }

    // 3. Default to standard chat
    return TaskIntent.chat;
  }
}
