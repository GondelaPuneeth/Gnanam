import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gnanam/providers/grade_provider.dart';
import 'package:gnanam/screens/drawer_menu.dart';
import 'package:gnanam/screens/chat_history_screen.dart';
import 'package:gnanam/theme/app_theme.dart';
import 'package:gnanam/inference/chat_controller.dart';
import 'package:gnanam/orchestrator/task_router.dart';
import 'package:gnanam/orchestrator/intent_classifier.dart';
import 'package:gnanam/widgets/chat_message.dart';
import 'package:gnanam/orchestrator/agent_manager.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _attachedFilePath;
  String? _attachedFileName;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty && _attachedFilePath == null) return;
    
    final message = _textController.text;
    _textController.clear();

    if (_attachedFilePath != null) {
      _sendWithAttachment(message);
    } else {
      ref.read(chatControllerProvider.notifier).sendMessage(message);
    }

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  Future<void> _sendWithAttachment(String prompt) async {
    final path = _attachedFilePath!;
    final ext = path.split('.').last.toLowerCase();
    final isVision = ['jpg', 'jpeg', 'png'].contains(ext);

    final request = TaskRequest(
      intent: isVision ? TaskIntent.vision : TaskIntent.document,
      textPrompt: prompt.isEmpty ? 'Analyze this file' : prompt,
      attachment: isVision ? File(path) : null,
      documentPath: !isVision ? path : null,
    );

    setState(() {
      _attachedFilePath = null;
      _attachedFileName = null;
    });

    ref.read(taskRouterProvider).routeRequest(request);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showAttachmentOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('Attach File', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: const Icon(Icons.camera_alt_outlined, color: Colors.blue),
                ),
                title: const Text('Camera'),
                subtitle: const Text('Take a photo of text or problems'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final photo = await picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    setState(() {
                      _attachedFilePath = photo.path;
                      _attachedFileName = photo.name;
                    });
                  }
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  child: const Icon(Icons.image_outlined, color: Colors.green),
                ),
                title: const Text('Gallery'),
                subtitle: const Text('Pick an image'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final photo = await picker.pickImage(source: ImageSource.gallery);
                  if (photo != null) {
                    setState(() {
                      _attachedFilePath = photo.path;
                      _attachedFileName = photo.name;
                    });
                  }
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
                ),
                title: const Text('PDF Document'),
                subtitle: const Text('Upload a PDF file'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );
                  if (result != null && result.files.single.path != null) {
                    setState(() {
                      _attachedFilePath = result.files.single.path!;
                      _attachedFileName = result.files.single.name;
                    });
                  }
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  child: const Icon(Icons.description_outlined, color: Colors.purple),
                ),
                title: const Text('DOCX / Text'),
                subtitle: const Text('Upload a Word document or text file'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['docx', 'txt'],
                  );
                  if (result != null && result.files.single.path != null) {
                    setState(() {
                      _attachedFilePath = result.files.single.path!;
                      _attachedFileName = result.files.single.name;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grade = ref.watch(gradeProvider) ?? 1;
    final primaryColor = AppTheme.getPrimaryColorForGrade(grade);
    final messages = ref.watch(chatControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            const Text('Gnanam'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Grade $grade',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.subject_outlined),
            onSelected: (String subject) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Switched to $subject context')),
              );
            },
            itemBuilder: (BuildContext context) {
              return ['Math', 'Science', 'English', 'History']
                  .map((String subject) => PopupMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      ))
                  .toList();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Chat History',
            onPressed: () async {
              final sessionId = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
              );
              if (sessionId != null) {
                ref.read(chatControllerProvider.notifier).loadSession(sessionId);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New Chat',
            onPressed: () {
              ref.read(chatControllerProvider.notifier).clearChat();
            },
          ),
        ],
      ),
      drawer: const DrawerMenu(),
      body: Column(
        children: [
          _buildAgentStatusBanner(context, ref),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                return ChatMessageWidget(
                  message: message,
                  onRegenerate: () {
                    // Handle regenerate
                  },
                );
              },
            ),
          ),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildAgentStatusBanner(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(agentStatusProvider).value ?? ref.read(agentManagerProvider).currentStatuses;
    
    final activeAgents = statuses.entries.where((e) => e.key != AgentTaskType.chat && e.value != 'Idle').toList();
    
    if (activeAgents.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: activeAgents.map((e) {
          final agentName = e.key == AgentTaskType.quiz ? 'Quiz Agent' : 'Doc Agent';
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  '$agentName: ${e.value}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attached file chip
          if (_attachedFilePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFileIcon(_attachedFileName ?? ''),
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _attachedFileName ?? 'File attached',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => setState(() {
                        _attachedFilePath = null;
                        _attachedFileName = null;
                      }),
                      child: Icon(Icons.close, size: 16, color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file_outlined),
                onPressed: _showAttachmentOptions,
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: _attachedFilePath != null
                        ? 'Ask about this file...'
                        : 'Ask anything...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_outlined),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return Icons.picture_as_pdf_outlined;
      case 'docx': case 'doc': return Icons.description_outlined;
      case 'jpg': case 'jpeg': case 'png': return Icons.image_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }
}