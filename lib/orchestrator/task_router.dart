import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'intent_classifier.dart';
import '../features/vision/vision_sensing_controller.dart';
import '../features/document/okf_parser.dart';
import '../inference/chat_controller.dart';

/// The TaskRouter acts as the central brain of the app, distributing work 
/// to the appropriate modules based on the classified intent.
class TaskRouter {
  final ChatController _chatController;
  final VisionSensingController _visionController;
  final OKFParser _okfParser;

  TaskRouter(this._chatController, this._visionController, this._okfParser);
  
  /// Routes the request to the correct handler.
  /// 
  /// Returns a boolean indicating if the routing was successfully initiated.
  Future<bool> routeRequest(TaskRequest request) async {
    switch (request.intent) {
      case TaskIntent.chat:
        return _handleChat(request);
      case TaskIntent.vision:
        return _handleVision(request);
      case TaskIntent.document:
        return _handleDocument(request);
    }
  }

  Future<bool> _handleChat(TaskRequest request) async {
    _chatController.sendMessage(request.textPrompt);
    return true;
  }

  Future<bool> _handleVision(TaskRequest request) async {
    if (request.attachment == null) return false;
    
    // Show a loading message or something via chat controller if we want,
    // but for now we just process and inject.
    final result = await _visionController.analyzeImage(request.attachment!);
    
    final prompt = '${result.toPromptContext()}\n\n${request.textPrompt}';
    _chatController.sendMessage(prompt);
    
    return true;
  }

  Future<bool> _handleDocument(TaskRequest request) async {
    if (request.documentPath == null) return false;
    
    final result = await _okfParser.parseFileToOKF(File(request.documentPath!));
    
    final prompt = "I have extracted the following document:\n\n$result\n\n${request.textPrompt}";
    _chatController.sendMessage(prompt);
    
    return true;
  }
}

final visionControllerProvider = Provider((ref) => VisionSensingController());
final okfParserProvider = Provider((ref) => OKFParser());

final taskRouterProvider = Provider<TaskRouter>((ref) {
  final chatController = ref.watch(chatControllerProvider.notifier);
  final visionController = ref.watch(visionControllerProvider);
  final okfParser = ref.watch(okfParserProvider);
  return TaskRouter(chatController, visionController, okfParser);
});
