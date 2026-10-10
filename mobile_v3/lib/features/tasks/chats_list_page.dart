import 'package:flutter/material.dart';
import '../../main.dart' show CrmData, CrmTask;
import 'task_chat_page.dart';

class ChatsListPage extends StatefulWidget {
  const ChatsListPage({
    super.key,
    required this.data,
    required this.apiBaseUrl,
    required this.onRefresh,
  });

  final CrmData data;
  final String apiBaseUrl;
  final Future<void> Function() onRefresh;

  @override
  State<ChatsListPage> createState() => _ChatsListPageState();
}

class _ChatsListPageState extends State<ChatsListPage> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await widget.onRefresh();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    // اجمع المهام التي فيها تعليقات + رتّبها بالأحدث
    final list = <MapEntry<CrmTask, Map<String, dynamic>>>[];
    for (final t in data.tasks) {
      final info = data.taskLastComment[t.id];
      if (info != null) list.add(MapEntry(t, info));
    }

    list.sort((a, b) {
      final ta = a.value['time']?.toString() ?? '';
      final tb = b.value['time']?.toString() ?? '';
      return tb.compareTo(ta);
    });

    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? _emptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final entry = list[i];
                    return _chatCard(entry.key, entry.value);
                  },
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('لا توجد محادثات بعد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'افتح أي مهمة واضغط على أيقونة 💬 لبدء محادثة',
              style: TextStyle(color: Colors.black54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatCard(CrmTask task, Map<String, dynamic> info) {
    final unread = widget.data.taskCommentCounts[task.id] ?? 0;
    final text = info['text']?.toString() ?? '';
    final author = info['author']?.toString() ?? '';
    final time = _formatTime(info['time']?.toString() ?? '');

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final session = widget.data.session;
          if (session == null) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskChatPage(
                apiBaseUrl: widget.apiBaseUrl,
                token: session.accessToken,
                taskId: task.id,
                taskTitle: task.title,
                currentUserId: session.user['id']?.toString() ?? '',
              ),
            ),
          );
          // بعد الرجوع، حدّث الأعداد
          await _load();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.chat, color: Colors.white, size: 20),
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
                            task.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$author: $text',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                  child: Center(
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'قبل ${diff.inMinutes} د';
      if (diff.inHours < 24) return 'قبل ${diff.inHours} س';
      if (diff.inDays < 7) return 'قبل ${diff.inDays} ي';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
