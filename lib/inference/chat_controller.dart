import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../orchestrator/agent_manager.dart';
import 'context_manager.dart';
import 'package:gnanam/core/database/app_database.dart';

/// Represents a single message in the chat
class ChatMessage {
  final String id;
  final String role; // 'user' or 'model'
  final String content;
  final bool isStreaming;
  final bool isError;
  final DateTime timestamp;

  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    this.isStreaming = false,
    this.isError = false,
    DateTime? timestamp,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';

  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    bool? isStreaming,
    bool? isError,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}


/// Provider for the ContextManager
final contextManagerProvider = Provider<ContextManager>((ref) {
  // Using 2048 window
  return ContextManager(maxTokens: 2048);
});

/// Provider tracking the current session ID
final currentSessionIdProvider = StateProvider<String?>((ref) => null);

/// StateNotifier that manages the list of chat messages and interactions with the LLM
class ChatController extends StateNotifier<List<ChatMessage>> {
  final AgentManager _agentManager;
  final ContextManager _contextManager;
  final Ref _ref;
  bool _isGenerating = false;
  String? _sessionId;

  ChatController(this._agentManager, this._contextManager, this._ref) : super([
    ChatMessage(
      role: 'model',
      content: 'Hello! I\'m your AI tutor. What would you like to learn today?',
    )
  ]);

  bool get isGenerating => _isGenerating;
  String? get sessionId => _sessionId;

  /// Initialize or set the current session
  Future<void> _ensureSession() async {
    if (_sessionId != null) return;
    final db = AppDatabase();
    _sessionId = await db.createSession(grade: 1);
    _ref.read(currentSessionIdProvider.notifier).state = _sessionId;
  }

  /// Load a previous session from the database
  Future<void> loadSession(String sessionId) async {
    final db = AppDatabase();
    final messages = await db.getMessages(sessionId);
    _sessionId = sessionId;
    _ref.read(currentSessionIdProvider.notifier).state = _sessionId;

    _contextManager.clearHistory();
    final loadedMessages = <ChatMessage>[];
    for (final msg in messages) {
      final role = msg['role'] as String;
      final content = msg['content'] as String;
      loadedMessages.add(ChatMessage(
        id: msg['id'] as String,
        role: role,
        content: content,
        isError: msg['is_error'] == 1,
        timestamp: DateTime.tryParse(msg['timestamp'] as String? ?? '') ?? DateTime.now(),
      ));
      // Rebuild context manager
      if (role == 'user') {
        _contextManager.addUserMessage(content);
      } else {
        _contextManager.addAssistantMessage(content);
      }
    }
    state = loadedMessages.isEmpty
        ? [ChatMessage(role: 'model', content: 'Resuming your previous conversation...')]
        : loadedMessages;
  }

  /// Sends a message to the LLM and updates state with streaming response
  Future<void> sendMessage(String text) async {
    if (_isGenerating || text.trim().isEmpty) return;

    await _ensureSession();

    // 1. Add user message to UI state and context manager
    final userMessage = ChatMessage(role: 'user', content: text.trim());
    state = [...state, userMessage];
    _contextManager.addUserMessage(text.trim());

    // Persist user message
    final db = AppDatabase();
    await db.insertMessage(
      sessionId: _sessionId!,
      id: userMessage.id,
      role: 'user',
      content: text.trim(),
    );

    // Auto-title session from first user message
    if (state.where((m) => m.isUser).length == 1) {
      final title = text.trim().length > 50 ? '${text.trim().substring(0, 50)}...' : text.trim();
      await db.updateSessionTitle(_sessionId!, title);
    }

    // Record study activity
    await db.recordStudyActivity(messagesSent: 1);

    // 2. Add an empty model message to start streaming into
    final modelMsg = ChatMessage(role: 'model', content: '', isStreaming: true);
    state = [...state, modelMsg];
    _isGenerating = true;

    try {
      // 3. Fetch pruned/summarized context window for generation
      final context = _contextManager.buildContext();
      
      // 4. Start streaming
      final stream = _agentManager.submitStreamTask(AgentTaskType.chat, context);
      
      final StringBuffer responseBuffer = StringBuffer();

      await for (final chunk in stream) {
        responseBuffer.write(chunk);
        
        // Update the last message (the model's response) with new chunk
        state = [
          ...state.sublist(0, state.length - 1),
          state.last.copyWith(content: responseBuffer.toString()),
        ];
      }

      // 5. Finalize the message when done
      final finalContent = responseBuffer.toString();
      state = [
        ...state.sublist(0, state.length - 1),
        state.last.copyWith(isStreaming: false, content: finalContent),
      ];

      // 6. Save the model's full response into the context manager
      _contextManager.addAssistantMessage(finalContent);

      // Persist model response
      await db.insertMessage(
        sessionId: _sessionId!,
        id: state.last.id,
        role: 'model',
        content: finalContent,
      );

    } catch (e) {
      // Handle generation error
      final errorContent = 'Error: Failed to generate response.\n$e';
      state = [
        ...state.sublist(0, state.length - 1),
        state.last.copyWith(
          content: errorContent,
          isStreaming: false,
          isError: true,
        ),
      ];

      // Persist error message too
      await db.insertMessage(
        sessionId: _sessionId!,
        id: state.last.id,
        role: 'model',
        content: errorContent,
        isError: true,
      );
    } finally {
      _isGenerating = false;
    }
  }

  /// Clears the chat history and starts a new session
  void clearChat() {
    _sessionId = null;
    _ref.read(currentSessionIdProvider.notifier).state = null;
    state = [
      ChatMessage(
        role: 'model',
        content: 'Hello! I\'m your AI tutor. What would you like to learn today?',
      )
    ];
    _contextManager.clearHistory();
  }
}

/// The provider for the ChatController used by the UI
final chatControllerProvider = StateNotifierProvider<ChatController, List<ChatMessage>>((ref) {
  final agentManager = ref.watch(agentManagerProvider);
  final contextManager = ref.watch(contextManagerProvider);
  return ChatController(agentManager, contextManager, ref);
});
