import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/llm_exceptions.dart' as errors;
import 'model_downloader.dart';

/// Abstract service for LLM inference operations.
abstract class LlmService {
  /// Initializes the AI engine.
  Future<void> initialize({String? hfToken});

  /// Installs and loads the model from a network URL.
  Future<void> installModel();

  /// Loads a LoRA adapter from the given [loraPath].
  Future<void> loadLora(String loraPath);

  /// Clears the currently loaded LoRA adapter.
  Future<void> clearLora();

  /// Streams the response from the LLM based on the given [context].
  Stream<String> generateStream(List<Map<String, String>> context, {double temperature = 0.7});

  /// Unloads the model and frees memory.
  Future<void> dispose();
  
  /// Returns whether a base model is currently loaded.
  bool get isModelLoaded;
  
  /// Returns whether a LoRA adapter is currently loaded.
  bool get isLoraLoaded;

  /// Returns model download progress stream.
  Stream<double> get downloadProgress;
}

/// Concrete implementation of [LlmService] using flutter_gemma (on-device).
class FlutterGemmaService implements LlmService {
  bool _isModelLoaded = false;
  bool _isLoraLoaded = false;
  final _downloadProgressController = StreamController<double>.broadcast();

  /// Gemma 2 2B IT model — optimized for MediaPipe on mobile devices.
  static const String _modelUrl =
      'https://huggingface.co/litert-community/Gemma2-2B-IT/resolve/main/gemma2_q8_multi-prefill-seq_ekv1280.task';

  String? _hfToken;

  @override
  bool get isModelLoaded => _isModelLoaded;
  
  @override
  bool get isLoraLoaded => _isLoraLoaded;

  @override
  Stream<double> get downloadProgress => _downloadProgressController.stream;

  @override
  Future<void> initialize({String? hfToken}) async {
    try {
      _hfToken = hfToken;
      await FlutterGemma.initialize(
        inferenceEngines: [const MediaPipeEngine()],
        huggingFaceToken: (hfToken != null && hfToken.isNotEmpty) ? hfToken : null,
      );
    } catch (e) {
      throw errors.ModelLoadException(
        'Failed to initialize FlutterGemma engine: $e',
        modelPath: 'MediaPipeEngine',
        cause: e,
      );
    }
  }

  @override
  Future<void> installModel() async {
    try {
      final modelFilename = _modelUrl.split('/').last;
      const loraUrl =
          'https://huggingface.co/Puneeth200500/gemmaedge-ncert-lora/resolve/main/ncert_lora_gpu.bin';

      // flutter_gemma expects exact filenames (based on its internal checks)
      final isBaseInstalled = await FlutterGemma.isModelInstalled(modelFilename);
      final isLoraInstalled =
          await FlutterGemma.isModelInstalled('ncert_lora_gpu.bin');

      if (isBaseInstalled && isLoraInstalled) {
        _downloadProgressController.add(100.0);
        // Continue to install/activate the model instead of returning early
      }

      final dir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory('${dir.path}/models');
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }
      final modelFile = File('${modelsDir.path}/$modelFilename');
      final loraFile = File('${modelsDir.path}/ncert_lora_gpu.bin');

      final downloader = ModelDownloader();
      final headers = (_hfToken != null && _hfToken!.isNotEmpty) 
          ? {'Authorization': 'Bearer ${_hfToken!.trim()}'} 
          : null;

      try {
        // Download Base Model if needed (supports resume for interrupted downloads)
        if (!isBaseInstalled) {
          _downloadProgressController.add(0.0);
          await downloader.downloadModel(
            url: _modelUrl,
            filename: modelFilename,
            headers: headers,
            onProgress: (progress) {
              _downloadProgressController.add(progress * 50); // first 50% for base model
            },
          );
        }

        // Download LoRA if needed (supports resume for interrupted downloads)
        if (!isLoraInstalled) {
          await downloader.downloadModel(
            url: loraUrl,
            filename: 'ncert_lora_gpu.bin',
            headers: headers,
            onProgress: (progress) {
              _downloadProgressController.add(50 + (progress * 50)); // next 50% for LoRA
            },
          );
        }
      } catch (e) {
        // Don't delete partial files — they enable resume on next attempt
        rethrow;
      }

      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromFile(modelFile.path)
          .withLoraFromFile(loraFile.path)
          .install();

      _isModelLoaded = true;
      _isLoraLoaded = true;
      _downloadProgressController.add(100.0);
    } catch (e) {
      _isModelLoaded = false;
      _isLoraLoaded = false;
      throw errors.ModelLoadException(
        'Failed to install Gemma model with NCERT LoRA: $e',
        modelPath: _modelUrl,
        cause: e,
      );
    }
  }

  @override
  Future<void> loadLora(String loraPath) async {
    // LoRA is supported by flutter_gemma but requires separate setup
    _isLoraLoaded = false;
  }

  @override
  Future<void> clearLora() async {
    _isLoraLoaded = false;
  }

  @override
  Stream<String> generateStream(List<Map<String, String>> context, {double temperature = 0.7}) {
    if (!_isModelLoaded) {
      throw const errors.InferenceException('Cannot generate: model not loaded');
    }

    final controller = StreamController<String>();

    // Build the prompt from context
    // flutter_gemma handles chat templates internally for .task files
    final messages = <Message>[];
    
    for (final msg in context) {
      final role = msg['role'] ?? 'user';
      final content = msg['content'] ?? '';
      
      if (role == 'system') {
        // Prepend system prompt as the first user message for context
        messages.add(Message(text: '[System Instructions]\n$content', isUser: true));
        messages.add(const Message(text: 'Understood. I will follow these instructions.', isUser: false));
      } else if (role == 'user') {
        messages.add(Message(text: content, isUser: true));
      } else if (role == 'assistant' || role == 'model') {
        messages.add(Message(text: content, isUser: false));
      }
    }

    try {
      // Create a background async stream processor
      // using the modern API: getActiveModel -> createChat -> generateChatResponseStream
      () async {
        try {
          final model = await FlutterGemma.getActiveModel(
            maxTokens: 2048,
          );
          
          final chatSession = await model.createChat();
          
          // Get the last user message as the current prompt
          final lastUserMsg = messages.lastWhere(
            (m) => m.isUser,
            orElse: () => const Message(text: '', isUser: true),
          );

          // Set chat history (all messages except the last user message)
          final history = messages.sublist(0, messages.isNotEmpty ? messages.length - 1 : 0);
          for (final msg in history) {
            await chatSession.addQueryChunk(msg);
          }

          // Add the final user query chunk
          await chatSession.addQueryChunk(lastUserMsg);

          // Stream the response
          final stream = chatSession.generateChatResponseAsync();
          
          await for (final response in stream) {
            if (response is TextResponse && response.token.isNotEmpty) {
              controller.add(response.token);
            }
          }
          controller.close();
        } catch (e) {
          controller.addError(
            errors.InferenceException('Failed during stream generation: $e', cause: e),
          );
          controller.close();
        }
      }();
    } catch (e) {
      controller.addError(
        errors.InferenceException('Failed to start generation: $e', cause: e),
      );
      controller.close();
    }
    
    return controller.stream;
  }

  @override
  Future<void> dispose() async {
    _isModelLoaded = false;
    _isLoraLoaded = false;
    await _downloadProgressController.close();
  }
}

/// Provider for the LlmService (on-device Gemma)
final llmServiceProvider = Provider<LlmService>((ref) {
  return FlutterGemmaService();
});
