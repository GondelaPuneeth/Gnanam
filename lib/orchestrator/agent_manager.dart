import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../inference/llm_service.dart';

enum AgentTaskType {
  chat,
  quiz,
  document,
}

class AgentTask {
  final String id;
  final AgentTaskType type;
  final List<Map<String, String>> context;
  final Completer<String>? resultCompleter;
  final StreamController<String>? streamController;

  AgentTask({
    required this.id,
    required this.type,
    required this.context,
    this.resultCompleter,
    this.streamController,
  });
}

/// The AgentManager orchestrates access to the singleton LLM service.
/// It creates the illusion of parallel subagents (Chat, Quiz, Doc) by queuing 
/// requests and processing them sequentially without crashing the 8GB device.
class AgentManager {
  final LlmService _llmService;
  final List<AgentTask> _queue = [];
  bool _isProcessing = false;

  // Status mapping for the UI (e.g., to show a small chip "Quiz Agent is thinking...")
  final _statusController = StreamController<Map<AgentTaskType, String>>.broadcast();
  final Map<AgentTaskType, String> _statuses = {
    AgentTaskType.chat: 'Idle',
    AgentTaskType.quiz: 'Idle',
    AgentTaskType.document: 'Idle',
  };

  AgentManager(this._llmService) {
    _statusController.add(Map.from(_statuses));
  }

  Stream<Map<AgentTaskType, String>> get statusStream => _statusController.stream;
  Map<AgentTaskType, String> get currentStatuses => Map.unmodifiable(_statuses);

  void _updateStatus(AgentTaskType type, String status) {
    _statuses[type] = status;
    _statusController.add(Map.from(_statuses));
  }

  /// Check if a specific subagent is currently busy
  bool isAgentBusy(AgentTaskType type) {
    return _statuses[type] != 'Idle';
  }

  /// Submits a task that requires a full String response (like Quiz generation)
  Future<String> submitTask(AgentTaskType type, List<Map<String, String>> context) {
    final completer = Completer<String>();
    final task = AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      context: context,
      resultCompleter: completer,
    );
    _queue.add(task);
    _updateStatus(type, 'Queued...');
    _processQueue();
    return completer.future;
  }

  /// Submits a task that requires a streamed response (like Chat)
  Stream<String> submitStreamTask(AgentTaskType type, List<Map<String, String>> context) {
    final controller = StreamController<String>();
    final task = AgentTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      context: context,
      streamController: controller,
    );
    _queue.add(task);
    _updateStatus(type, 'Queued...');
    _processQueue();
    return controller.stream;
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      _updateStatus(task.type, 'Processing...');

      try {
        final stream = _llmService.generateStream(task.context);
        
        if (task.streamController != null) {
          await for (final chunk in stream) {
            if (!task.streamController!.isClosed) {
              task.streamController!.add(chunk);
            }
          }
          if (!task.streamController!.isClosed) {
            task.streamController!.close();
          }
        } else if (task.resultCompleter != null) {
          final buffer = StringBuffer();
          await for (final chunk in stream) {
            buffer.write(chunk);
          }
          task.resultCompleter!.complete(buffer.toString());
        }
      } catch (e) {
        if (task.streamController != null && !task.streamController!.isClosed) {
          task.streamController!.addError(e);
          task.streamController!.close();
        }
        if (task.resultCompleter != null && !task.resultCompleter!.isCompleted) {
          task.resultCompleter!.completeError(e);
        }
      } finally {
        _updateStatus(task.type, 'Idle');
      }
    }

    _isProcessing = false;
  }

  void dispose() {
    _statusController.close();
  }
}

final agentManagerProvider = Provider<AgentManager>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  return AgentManager(llmService);
});

final agentStatusProvider = StreamProvider<Map<AgentTaskType, String>>((ref) {
  final manager = ref.watch(agentManagerProvider);
  return manager.statusStream;
});
