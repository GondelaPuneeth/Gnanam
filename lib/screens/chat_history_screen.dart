import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gnanam/core/database/app_database.dart';

class ChatHistoryScreen extends ConsumerStatefulWidget {
  final bool bookmarkedOnly;

  const ChatHistoryScreen({super.key, this.bookmarkedOnly = false});

  @override
  ConsumerState<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends ConsumerState<ChatHistoryScreen> {
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _searchController.addListener(_filterSessions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final db = AppDatabase();
    final sessions = await db.getSessions(limit: 100);
    setState(() {
      _sessions = sessions;
      _filterSessions();
      _loading = false;
    });
  }

  void _filterSessions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      var filtered = _sessions.where((s) {
        if (widget.bookmarkedOnly && s['is_bookmarked'] != 1) return false;
        if (query.isEmpty) return true;
        final title = (s['title'] as String? ?? '').toLowerCase();
        final subject = (s['subject'] as String? ?? '').toLowerCase();
        return title.contains(query) || subject.contains(query);
      }).toList();
      _filtered = filtered;
    });
  }

  String _timeAgo(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _groupLabel(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return 'Earlier';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(sessionDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This Week';
    return 'Earlier';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group sessions
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final session in _filtered) {
      final label = _groupLabel(session['updated_at'] as String? ?? '');
      grouped.putIfAbsent(label, () => []).add(session);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookmarkedOnly ? 'Saved Lessons' : 'Chat History'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Session list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.bookmarkedOnly ? Icons.bookmark_border : Icons.chat_bubble_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.bookmarkedOnly
                                  ? 'No saved lessons yet'
                                  : 'No conversations yet',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start chatting to see your history here!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _buildListItems(grouped).length,
                        itemBuilder: (context, index) {
                          final item = _buildListItems(grouped)[index];
                          if (item is String) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 8),
                              child: Text(
                                item,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            );
                          }
                          final session = item as Map<String, dynamic>;
                          return _buildSessionCard(session, theme);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _buildListItems(Map<String, List<Map<String, dynamic>>> grouped) {
    final items = <dynamic>[];
    final order = ['Today', 'Yesterday', 'This Week', 'Earlier'];
    for (final label in order) {
      if (grouped.containsKey(label)) {
        items.add(label);
        items.addAll(grouped[label]!);
      }
    }
    return items;
  }

  Widget _buildSessionCard(Map<String, dynamic> session, ThemeData theme) {
    final isBookmarked = session['is_bookmarked'] == 1;

    return Dismissible(
      key: Key(session['id'] as String),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Chat'),
            content: const Text('Are you sure you want to delete this conversation?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await AppDatabase().deleteSession(session['id'] as String);
        _loadSessions();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pop(context, session['id']);
          },
          onLongPress: () async {
            await AppDatabase().toggleBookmark(session['id'] as String);
            _loadSessions();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.chat_bubble_outline, color: theme.colorScheme.onPrimaryContainer, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              session['title'] as String? ?? 'New Chat',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isBookmarked)
                            Icon(Icons.bookmark, size: 18, color: theme.colorScheme.primary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (session['subject'] != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                session['subject'] as String,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '${session['message_count']} messages',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _timeAgo(session['updated_at'] as String? ?? ''),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
