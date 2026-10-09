import 'package:flutter/material.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({
    super.key,
    required this.apiBaseUrl,
    required this.token,
    required this.role,
    required this.myBranch,
    required this.canManage,
    required this.canTransfer,
  });

  final String apiBaseUrl;
  final String token;
  final String role;
  final String? myBranch;
  final bool canManage;
  final bool canTransfer;

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  List<Map<String, dynamic>> users = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final list = await _apiGet('/users');
      setState(() {
        users = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<List<dynamic>> _apiGet(String path) async {
    if (widget.apiBaseUrl.isEmpty || widget.token.isEmpty) {
      throw Exception('غير متصل بالخادم');
    }
    final base = widget.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse('$base$path');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${widget.token}');
      final res = await req.close();
      final txt = await res.transform(const SystemEncoding().decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: $txt');
      }
      final decoded = jsonDecode(txt);
      if (decoded is List) return decoded;
      return <dynamic>[];
    } finally {
      client.close(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الفريق'),
          actions: [
            IconButton(
              onPressed: load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? _buildError()
                : users.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('تعذر تحميل الفريق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: load, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text('لا يوجد موظفون', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final u = users[i];
          final role = u['role']?.toString() ?? '';
          final roleAr = _roleAr(role);
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  (u['employeeId']?.toString() ?? '?').substring(0, 1),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(u['name']?.toString() ?? ''),
              subtitle: Text('${u['employeeId'] ?? ''} • $roleAr • ${u['branch'] ?? '—'}'),
              trailing: widget.canManage
                  ? PopupMenuButton<String>(
                      onSelected: (v) => _onAction(v, u),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                        if (widget.canTransfer)
                          const PopupMenuItem(value: 'transfer', child: Text('نقل بين الفروع')),
                        const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                      ],
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  void _onAction(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'edit':
        _showSnack('تعديل ${user['name']} (قريبًا)');
        break;
      case 'transfer':
        _showSnack('نقل ${user['name']} (قريبًا)');
        break;
      case 'delete':
        _showSnack('حذف ${user['name']} (قريبًا)');
        break;
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
}
