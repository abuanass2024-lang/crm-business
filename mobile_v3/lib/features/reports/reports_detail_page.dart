import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class ReportsDetailPage extends StatefulWidget {
  const ReportsDetailPage({
    super.key,
    required this.apiBaseUrl,
    required this.token,
  });

  final String apiBaseUrl;
  final String token;

  @override
  State<ReportsDetailPage> createState() => _ReportsDetailPageState();
}

class _ReportsDetailPageState extends State<ReportsDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  Map<String, dynamic>? _customersReport;
  Map<String, dynamic>? _tasksReport;
  Map<String, dynamic>? _oppsReport;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  String get _base => widget.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _get('/analytics/customers/report'),
        _get('/analytics/tasks/report'),
        _get('/analytics/opportunities/report'),
      ]);
      setState(() {
        _customersReport = results[0];
        _tasksReport = results[1];
        _oppsReport = results[2];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse('$_base$path'));
      req.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${widget.token}',
      );
      final res = await req.close();
      final txt = await res.transform(utf8.decoder).join();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}');
      }
      return Map<String, dynamic>.from(jsonDecode(txt) as Map);
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
          title: const Text('التقارير التفصيلية'),
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            controller: _tab,
            tabs: const [
              Tab(icon: Icon(Icons.people), text: 'العملاء'),
              Tab(icon: Icon(Icons.task), text: 'المهام'),
              Tab(icon: Icon(Icons.trending_up), text: 'الفرص'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : TabBarView(
                    controller: _tab,
                    children: [
                      _buildCustomersTab(),
                      _buildTasksTab(),
                      _buildOppsTab(),
                    ],
                  ),
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
            const Text('تعذر تحميل التقارير',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }

  // ═══════════ العملاء ═══════════
  Widget _buildCustomersTab() {
    final r = _customersReport ?? {};
    final byStatus = Map<String, dynamic>.from(r['byStatus'] as Map? ?? {});
    final byBranch = Map<String, dynamic>.from(r['byBranch'] as Map? ?? {});
    final byPeriod = Map<String, dynamic>.from(r['byPeriod'] as Map? ?? {});
    final byEmployee = (r['byEmployee'] as List? ?? []);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _bigNumberCard(
            'إجمالي العملاء',
            '${r['total'] ?? 0}',
            Icons.people,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _section('حسب الحالة'),
          ..._statusCards(byStatus),
          const SizedBox(height: 16),
          _section('حسب الفرع'),
          ..._branchRows(byBranch),
          const SizedBox(height: 16),
          _section('حسب الفترة'),
          Row(
            children: [
              Expanded(child: _smallCard('7 أيام', '${byPeriod['last7'] ?? 0}')),
              const SizedBox(width: 8),
              Expanded(child: _smallCard('30 يومًا', '${byPeriod['last30'] ?? 0}')),
              const SizedBox(width: 8),
              Expanded(child: _smallCard('90 يومًا', '${byPeriod['last90'] ?? 0}')),
            ],
          ),
          const SizedBox(height: 16),
          _section('حسب الموظف'),
          if (byEmployee.isEmpty)
            _empty('لا يوجد موظفون مرتبطون بعملاء')
          else
            ...byEmployee.map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return _employeeRow(
                m['name']?.toString() ?? '',
                m['employeeId']?.toString() ?? '',
                '${m['count'] ?? 0}',
              );
            }),
        ],
      ),
    );
  }

  List<Widget> _statusCards(Map<String, dynamic> m) {
    final entries = m.entries.toList();
    if (entries.isEmpty) return [_empty('لا توجد بيانات')];
    return entries.map((e) {
      final colors = {
        'PROSPECT': Colors.blue,
        'CUSTOMER': Colors.amber,
        'ACTIVE': Colors.green,
        'INACTIVE': Colors.orange,
        'WITHDRAWN': Colors.red,
      };
      final labels = {
        'PROSPECT': 'محتمل',
        'CUSTOMER': 'عميل',
        'ACTIVE': 'نشط',
        'INACTIVE': 'غير فعال',
        'WITHDRAWN': 'منسحب',
      };
      final color = colors[e.key] ?? Colors.grey;
      final label = labels[e.key] ?? e.key;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text('${e.value}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
            title: Text(label),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _branchRows(Map<String, dynamic> m) {
    final entries = m.entries.toList();
    if (entries.isEmpty) return [_empty('لا توجد بيانات')];
    return entries.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Card(
          child: ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(_branchName(e.key)),
            trailing: Text('${e.value}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }).toList();
  }

  // ═══════════ المهام ═══════════
  Widget _buildTasksTab() {
    final r = _tasksReport ?? {};
    final byStatus = Map<String, dynamic>.from(r['byStatus'] as Map? ?? {});
    final byPriority = Map<String, dynamic>.from(r['byPriority'] as Map? ?? {});
    final byEmployee = (r['byEmployee'] as List? ?? []);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _bigNumberCard('إجمالي المهام', '${r['total'] ?? 0}', Icons.task, Colors.indigo),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _smallCard('مكتملة', '${r['completed'] ?? 0}')),
              const SizedBox(width: 8),
              Expanded(child: _smallCard('متأخرة', '${r['overdue'] ?? 0}')),
              const SizedBox(width: 8),
              Expanded(child: _smallCard('هذا الأسبوع', '${r['completedThisWeek'] ?? 0}')),
            ],
          ),
          const SizedBox(height: 16),
          _section('حسب الحالة'),
          ..._taskStatusRows(byStatus),
          const SizedBox(height: 16),
          _section('حسب الأولوية'),
          ..._priorityRows(byPriority),
          const SizedBox(height: 16),
          _section('حسب الموظف'),
          if (byEmployee.isEmpty)
            _empty('لا يوجد موظفون مرتبطون بمهام')
          else
            ...byEmployee.map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return _employeeRow(
                m['name']?.toString() ?? '',
                m['employeeId']?.toString() ?? '',
                '${m['completed'] ?? 0} / ${m['total'] ?? 0}',
              );
            }),
        ],
      ),
    );
  }

  List<Widget> _taskStatusRows(Map<String, dynamic> m) {
    final labels = {
      'TODO': 'قيد الانتظار',
      'IN_PROGRESS': 'قيد التنفيذ',
      'COMPLETED': 'مكتملة',
      'CANCELLED': 'ملغاة',
    };
    final entries = m.entries.toList();
    if (entries.isEmpty) return [_empty('لا توجد بيانات')];
    return entries
        .map((e) => _simpleRow(labels[e.key] ?? e.key, '${e.value}'))
        .toList();
  }

  List<Widget> _priorityRows(Map<String, dynamic> m) {
    final labels = {
      'LOW': 'منخفضة',
      'MEDIUM': 'متوسطة',
      'HIGH': 'عالية',
      'URGENT': 'عاجلة',
    };
    final colors = {
      'LOW': Colors.grey,
      'MEDIUM': Colors.blue,
      'HIGH': Colors.orange,
      'URGENT': Colors.red,
    };
    final entries = m.entries.toList();
    if (entries.isEmpty) return [_empty('لا توجد بيانات')];
    return entries.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (colors[e.key] ?? Colors.grey).withValues(alpha: 0.2),
              child: Text('${e.value}',
                  style: TextStyle(
                      color: colors[e.key] ?? Colors.grey,
                      fontWeight: FontWeight.bold)),
            ),
            title: Text(labels[e.key] ?? e.key),
          ),
        ),
      );
    }).toList();
  }

  // ═══════════ الفرص ═══════════
  Widget _buildOppsTab() {
    final r = _oppsReport ?? {};
    final byStage = (r['byStage'] as List? ?? []);
    final byEmployee = (r['byEmployee'] as List? ?? []);
    final byBranch = (r['byBranch'] as List? ?? []);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _bigNumberCard('إجمالي الفرص', '${r['total'] ?? 0}',
              Icons.trending_up, Colors.purple),
          const SizedBox(height: 12),
          _bigNumberCard(
            'القيمة الكلية',
            '${_fmtNum(r['totalValue'])} ﷼',
            Icons.attach_money,
            Colors.green,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _smallCard('Pipeline', '${_fmtNum(r['pipelineValue'])}')),
              const SizedBox(width: 8),
              Expanded(child: _smallCard('مُرجّحة', '${_fmtNum(r['weightedPipeline'])}')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _smallCard('Win Rate',
                  '${((r['winRate'] ?? 0) * 100).toStringAsFixed(0)}%')),
              const SizedBox(width: 8),
              Expanded(child: _smallCard('فوز', '${r['wonCount'] ?? 0}')),
              const SizedBox(width: 8),
              Expanded(child: _smallCard('خسارة', '${r['lostCount'] ?? 0}')),
            ],
          ),
          const SizedBox(height: 16),
          _section('حسب المرحلة'),
          ...byStage.map((s) {
            final m = Map<String, dynamic>.from(s as Map);
            return _stageRow(
              m['stage']?.toString() ?? '',
              '${m['count'] ?? 0}',
              '${_fmtNum(m['value'])}',
            );
          }),
          const SizedBox(height: 16),
          _section('حسب الموظف'),
          if (byEmployee.isEmpty)
            _empty('لا يوجد موظفون مرتبطون بفرص')
          else
            ...byEmployee.map((e) {
              final m = Map<String, dynamic>.from(e as Map);
              return _employeeRow(
                m['name']?.toString() ?? '',
                m['employeeId']?.toString() ?? '',
                '${m['count'] ?? 0} • ${_fmtNum(m['value'])}',
              );
            }),
          const SizedBox(height: 16),
          _section('حسب الفرع'),
          if (byBranch.isEmpty)
            _empty('لا توجد بيانات')
          else
            ...byBranch.map((b) {
              final m = Map<String, dynamic>.from(b as Map);
              return _simpleRow(
                _branchName(m['branch']?.toString() ?? ''),
                '${m['count'] ?? 0} • ${_fmtNum(m['value'])}',
              );
            }),
        ],
      ),
    );
  }

  Widget _stageRow(String stage, String count, String value) {
    final labels = {
      'LEAD': 'مهتم',
      'QUALIFIED': 'مؤهل',
      'MEETING': 'اجتماع',
      'PROPOSAL': 'عرض',
      'NEGOTIATION': 'تفاوض',
      'WON': 'ربح',
      'LOST': 'خسارة',
    };
    final colors = {
      'LEAD': Colors.blue,
      'QUALIFIED': Colors.cyan,
      'MEETING': Colors.teal,
      'PROPOSAL': Colors.amber,
      'NEGOTIATION': Colors.orange,
      'WON': Colors.green,
      'LOST': Colors.red,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (colors[stage] ?? Colors.grey).withValues(alpha: 0.2),
            child: Text(count,
                style: TextStyle(
                    color: colors[stage] ?? Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          title: Text(labels[stage] ?? stage),
          trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  // ═══════════ Helpers ═══════════
  Widget _bigNumberCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _simpleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        child: ListTile(
          title: Text(label),
          trailing: Text(value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _employeeRow(String name, String empId, String count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            child: Text(empId.isEmpty ? '؟' : empId.substring(0, 1),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          title: Text(name),
          subtitle: Text(empId),
          trailing: Text(count,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }

  String _branchName(String code) {
    return {
      'HQ': 'المركز الرئيسي',
      'SANAA': 'صنعاء',
      'ADEN': 'عدن',
      'غير محدد': 'غير محدد',
    }[code] ?? code;
  }

  String _fmtNum(dynamic v) {
    if (v == null) return '0';
    final n = (v is num) ? v : num.tryParse(v.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}
