import 'package:flutter/material.dart';
import '../../main.dart' show CrmData, Customer, Opportunity, CrmTask;
import '../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════
/// صفحة التقارير — مركز قيادة شامل
/// ═══════════════════════════════════════════════════════════
Widget buildReportsPage({required CrmData data}) {
  return _ReportsPage(data: data);
}

class _ReportsPage extends StatelessWidget {
  const _ReportsPage({required this.data});

  final CrmData data;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _kpiSection(),
          const SizedBox(height: 24),
          _sectorDistribution(),
          const SizedBox(height: 24),
          _branchDistribution(),
          const SizedBox(height: 24),
          _sizeDistribution(),
          const SizedBox(height: 24),
          _topSalesReps(),
          const SizedBox(height: 24),
          _topCustomers(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 1. KPIs الإجمالية
  // ═══════════════════════════════════════════════════════════
  Widget _kpiSection() {
    final totalCustomers = data.customers.length;
    final activeCustomers =
        data.customers.where((c) => c.status == 'نشط').length;
    final openOpps = data.opportunities
        .where((o) => o.stage != 'Won' && o.stage != 'Lost')
        .toList();
    final pipelineValue =
        openOpps.fold<double>(0, (s, o) => s + o.value);
    final totalTasks = data.tasks.length;
    final overdueTasks =
        data.tasks.where((t) => !t.done && t.overdue).length;
    final totalValue = data.opportunities
        .where((o) => o.stage == 'Won')
        .fold<double>(0, (s, o) => s + o.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(icon: Icons.dashboard_rounded, title: 'نظرة عامة'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                icon: Icons.people_alt_rounded,
                value: '$totalCustomers',
                label: 'العملاء',
                subLabel: '$activeCustomers نشط',
                color: AppTheme.primaryTeal,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                icon: Icons.trending_up_rounded,
                value: '${openOpps.length}',
                label: 'الفرص',
                subLabel: _money(pipelineValue),
                color: AppTheme.cyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                icon: Icons.task_alt_rounded,
                value: '$totalTasks',
                label: 'المهام',
                subLabel: overdueTasks > 0
                    ? '⚠️ $overdueTasks متأخرة'
                    : 'لا متأخرة',
                color: AppTheme.success,
                subColor: overdueTasks > 0 ? AppTheme.error : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                icon: Icons.emoji_events_rounded,
                value: _money(totalValue),
                label: 'المبيعات',
                subLabel: 'إجمالي المُغلق',
                color: AppTheme.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required String value,
    required String label,
    required String subLabel,
    required Color color,
    Color? subColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: TextStyle(
              fontSize: 11,
              color: subColor ?? Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 2. توزيع بالقطاعات
  // ═══════════════════════════════════════════════════════════
  Widget _sectorDistribution() {
    final map = <String, int>{};
    for (final c in data.customers) {
      if (c.sector.isEmpty) continue;
      map[c.sector] = (map[c.sector] ?? 0) + 1;
    }

    if (map.isEmpty) return const SizedBox.shrink();

    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = sorted.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          icon: Icons.business_center_rounded,
          title: 'العملاء حسب القطاع',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withAlpha(15)),
          ),
          child: Column(
            children: sorted.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _barRow(
                  label: e.key,
                  value: e.value,
                  max: max,
                  color: AppTheme.primaryTeal,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 3. توزيع بالفروع
  // ═══════════════════════════════════════════════════════════
  Widget _branchDistribution() {
    final map = <String, int>{};
    for (final c in data.customers) {
      if (c.branch.isEmpty) continue;
      map[c.branch] = (map[c.branch] ?? 0) + 1;
    }

    if (map.isEmpty) return const SizedBox.shrink();

    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = sorted.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          icon: Icons.store_rounded,
          title: 'العملاء حسب الفرع',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withAlpha(15)),
          ),
          child: Column(
            children: sorted.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _barRow(
                  label: e.key,
                  value: e.value,
                  max: max,
                  color: AppTheme.cyan,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 4. توزيع بالأحجام
  // ═══════════════════════════════════════════════════════════
  Widget _sizeDistribution() {
    final map = <String, int>{};
    for (final c in data.customers) {
      if (c.size.isEmpty) continue;
      map[c.size] = (map[c.size] ?? 0) + 1;
    }

    if (map.isEmpty) return const SizedBox.shrink();

    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = sorted.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          icon: Icons.aspect_ratio_rounded,
          title: 'العملاء حسب الحجم',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withAlpha(15)),
          ),
          child: Column(
            children: sorted.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _barRow(
                  label: e.key,
                  value: e.value,
                  max: max,
                  color: AppTheme.amber,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 5. أفضل المندوبين
  // ═══════════════════════════════════════════════════════════
  Widget _topSalesReps() {
    final map = <String, int>{};
    for (final c in data.customers) {
      if (c.salesRep.isEmpty) continue;
      map[c.salesRep] = (map[c.salesRep] ?? 0) + 1;
    }

    if (map.isEmpty) return const SizedBox.shrink();

    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          icon: Icons.emoji_events_rounded,
          title: 'أفضل المندوبين',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withAlpha(15)),
          ),
          child: Column(
            children: top.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _rankRow(
                  rank: index + 1,
                  label: item.key,
                  value: '${item.value} عميل',
                  color: _rankColor(index),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 6. أفضل العملاء
  // ═══════════════════════════════════════════════════════════
  Widget _topCustomers() {
    final map = <String, double>{};
    for (final o in data.opportunities) {
      if (o.stage == 'Won') {
        map[o.customer] = (map[o.customer] ?? 0) + o.value;
      }
    }

    if (map.isEmpty) return const SizedBox.shrink();

    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          icon: Icons.star_rounded,
          title: 'أفضل العملاء',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withAlpha(15)),
          ),
          child: Column(
            children: top.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _rankRow(
                  rank: index + 1,
                  label: item.key,
                  value: _money(item.value),
                  color: _rankColor(index),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════
  Widget _sectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryTeal, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _barRow({
    required String label,
    required int value,
    required int max,
    required Color color,
  }) {
    final ratio = max > 0 ? value / max : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: color.withAlpha(30),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _rankRow({
    required int rank,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _rankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFB300); // ذهبي
      case 1:
        return const Color(0xFF9E9E9E); // فضي
      case 2:
        return const Color(0xFFBF8970); // برونزي
      default:
        return AppTheme.primaryTeal;
    }
  }

  String _money(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
