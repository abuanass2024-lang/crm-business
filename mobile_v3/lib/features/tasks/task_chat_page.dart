import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class TaskChatPage extends StatefulWidget {
  const TaskChatPage({
    super.key,
    required this.apiBaseUrl,
    required this.token,
    required this.taskId,
    required this.taskTitle,
    required this.currentUserId,
  });

  final String apiBaseUrl;
  final String token;
  final String taskId;
  final String taskTitle;
  final String currentUserId;

  @override
  State<TaskChatPage> createState() => _TaskChatPageState();
}

class _TaskChatPageState extends State<TaskChatPage> {
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _poll;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _base => widget.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final client = HttpClient();
      try {
        final req = await client.getUrl(
          Uri.parse('$_base/tasks/${widget.taskId}/comments'),
        );
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${widget.token}');
        final res = await req.close();
        final txt = await res.transform(utf8.decoder).join();
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw Exception('HTTP ${res.statusCode}');
        }
        final decoded = jsonDecode(txt);
        if (decoded is List) {
          setState(() {
            _comments = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            _loading = false;
            _error = null;
          });
          _scrollToBottom();
        }
      } finally {
        client.close(force: true);
      }
    } catch (e) {
      if (!silent) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final client = HttpClient();
      try {
        final req = await client.postUrl(
          Uri.parse('$_base/tasks/${widget.taskId}/comments'),
        );
        req.headers.contentType = ContentType.json;
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${widget.token}');
        req.write(jsonEncode({'message': text}));
        final res = await req.close();
        final body = await res.transform(utf8.decoder).join();
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw Exception('فشل الإرسال (${res.statusCode})');
        }
        _controller.clear();
        await _load(silent: true);
      } finally {
        client.close(force: true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('المحادثة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
              Text(widget.taskTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _buildBody()),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('تعذر تحميل المحادثة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_error ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => _load(), child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }
    if (_comments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('لا توجد تعليقات بعد', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 4),
            Text('اكتب أول تعليق', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _comments.length,
      itemBuilder: (context, i) => _buildComment(_comments[i]),
    );
  }

  Widget _buildComment(Map<String, dynamic> c) {
    final user = c['user'] as Map? ?? {};
    final userId = user['id']?.toString() ?? '';
    final isMine = userId == widget.currentUserId;
    final name = user['name']?.toString() ?? '';
    final empId = user['employeeId']?.toString() ?? '';
    final role = user['role']?.toString() ?? '';
    final message = c['message']?.toString() ?? '';
    final createdAt = c['createdAt']?.toString() ?? '';

    final roleColor = _roleColor(role);
    final roleLabel = _roleAr(role);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(maxWidth: 320),
              decoration: BoxDecoration(
                color: isMine ? const Color(0xFFDCF8C6) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: roleColor,
                        child: Text(
                          empId.isNotEmpty ? empId.substring(0, 1) : '؟',
                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        name.isEmpty ? empId : name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(fontSize: 9, color: roleColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(message, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(createdAt),
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'اكتب تعليقًا...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleAr(String r) {
    return {
      'GENERAL_MANAGER': 'مدير عام',
      'REGIONAL_MANAGER': 'مدير فروع',
      'BRANCH_MANAGER': 'مدير فرع',
      'HALL_MANAGER': 'مشرف',
      'SUPERVISOR': 'مشرف',
      'CUSTOMER_SERVICE': 'خدمة عملاء',
      'OWNER': 'مالك',
      'ADMIN': 'مدير نظام',
      'MANAGER': 'مدير',
      'SALES': 'مبيعات',
      'VIEWER': 'مشاهد',
    }[r] ?? r;
  }

  Color _roleColor(String r) {
    switch (r) {
      case 'GENERAL_MANAGER':
      case 'OWNER':
        return Colors.red.shade700;
      case 'REGIONAL_MANAGER':
      case 'BRANCH_MANAGER':
        return Colors.orange.shade700;
      case 'HALL_MANAGER':
      case 'SUPERVISOR':
        return Colors.blue.shade700;
      case 'CUSTOMER_SERVICE':
      case 'SALES':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
