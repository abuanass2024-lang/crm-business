import 'package:flutter/material.dart';
import '../../main.dart' show CrmData, CrmTask;
import '../../core/theme/app_theme.dart';
import '../insights/smart_insights.dart';

/// Dashboard V2 — نسخة محسّنة مع KPI متقدمة
Widget buildDashboardV2({
  required CrmData data,
  required VoidCallback onAddCustomer,
  required VoidCallback onOpenNotifications,
  required VoidCallback onOpenSettings,
  required VoidCallback onOpenAI,
}) {
  return _DashboardV2(
    data: data,
    onAddCustomer: onAddCustomer,
    onOpenNotifications: onOpenNotifications,
    onOpenSettings: onOpenSettings,
    onOpenAI: onOpenAI,
  );
}

class _DashboardV2 extends StatelessWidget {
  const _DashboardV2({
    required this.data,
    required this.onAddCustomer,
    required this.onOpenNotifications,
    required this.onOpenSettings,
    required this.onOpenAI,
  });

  final CrmData data;
  final VoidCallback onAddCustomer;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAI;

  @override
  Widget build(BuildContext context) {
    final userName = data.session?.user['name']?.toString() ??
        data.company?.managerName ??
        'صديقي';
    final companyName = data.company?.companyName ?? 'شركتك';

    // ═══ إحصائيات ═══
    final totalCustomers = data.customers.length;
    final activeCustomers = data.customers.where((c) => c.status == 'نشط').length;
    final openOpportunities =
        data.opportunities.where((o) => o.stage != 'Won' && o.stage != 'Lost').length;
    final pipelineValue = data.opportunities
        .where((o) => o.stage != 'Won' && o.stage != 'Lost')
        .fold<double>(0, (sum, o) => sum + o.value);
    final todayTasks = data.tasks.where((t) => !t.done && t.today).length;
    final overdueTasks = data.tasks.where((t) => !t.done && t.overdue).length;

    // ═══ مهام اليوم (أول 3) ═══
    final priorityTasks = data.tasks
        .where((t) => !t.done && (t.today || t.overdue))
        .take(3)
        .toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        color: AppTheme.primaryTeal,
        onRefresh: () async {
          data.refreshSystemNotifications();
          await data.save();
        },
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // ═══ ترحيب ═══
            _greetingCard(userName, companyName),

            const SizedBox(height: 14),

            // ═══ 4 بطاقات KPI ═══
            Row(
              children: [
                Expanded(
                  child: _kpiCard(
                    icon: Icons.people_alt_rounded,
                    title: 'العملاء',
                    value: '$totalCustomers',
                    subtitle: '$activeCustomers نشط',
                    color: AppTheme.primaryTeal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _kpiCard(
                    icon: Icons.trending_up_rounded,
                    title: 'الفرص',
                    value: '$openOpportunities',
                    subtitle: _formatMoney(pipelineValue),
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
                    title: 'مهام اليوم',
                    value: '$todayTasks',
                    subtitle: overdueTasks > 0
                        ? '⚠️ $overdueTasks متأخرة'
                        : 'لا مهام متأخرة',
                    color: AppTheme.success,
                    subtitleColor: overdueTasks > 0 ? AppTheme.error : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _kpiCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'إجمالي الفرص',
                    value: '$openOpportunities',
                    subtitle: 'فرصة مفتوحة',
                    color: AppTheme.amber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ═══ مهام اليوم ═══
            if (priorityTasks.isNotEmpty) ...[
              _sectionTitle(
                icon: Icons.checklist_rounded,
                title: 'مهام اليوم',
                count: priorityTasks.length,
              ),
              const SizedBox(height: 8),
              ...priorityTasks.map((t) => _taskRow(t)),
              const SizedBox(height: 20),
            ],


            // ═══ تحليلات ذكية ═══
            if (SmartInsights.generate(data).isNotEmpty) ...[
              _sectionTitle(
                icon: Icons.psychology_rounded,
                title: 'تحليلات ذكية',
                count: SmartInsights.generate(data).length,
              ),
              const SizedBox(height: 8),
              ...SmartInsights.generate(data).map((i) => InsightCard(insight: i)),
              const SizedBox(height: 20),
            ],

            // ═══ اختصارات سريعة ═══
            _sectionTitle(
              icon: Icons.bolt_rounded,
              title: 'إجراءات سريعة',
            ),
            const SizedBox(height: 8),
            // ═══ زر AI ═══
            _quickAction(
              icon: Icons.psychology_rounded,
              label: 'المساعد الذكي 🤖',
              onTap: onOpenAI,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _quickAction(
                    icon: Icons.person_add_rounded,
                    label: 'عميل جديد',
                    onTap: onAddCustomer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickAction(
                    icon: Icons.notifications_rounded,
                    label: 'الإشعارات',
                    onTap: onOpenNotifications,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickAction(
                    icon: Icons.settings_rounded,
                    label: 'الإعدادات',
                    onTap: onOpenSettings,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ═══ ملخص Pipeline ═══
            _sectionTitle(
              icon: Icons.insights_rounded,
              title: 'ملخص الفرص',
            ),
            const SizedBox(height: 8),
            _pipelineSummary(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ════════════════════ Widgets ════════════════════

  Widget _greetingCard(String userName, String companyName) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryTeal, AppTheme.primaryTealLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withAlpha(60),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً $userName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  companyName,
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    Color? subtitleColor,
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
                  title,
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: subtitleColor ?? Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    int? count,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryTeal, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _taskRow(CrmTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.overdue
              ? AppTheme.error.withAlpha(80)
              : Colors.black.withAlpha(15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            task.overdue
                ? Icons.warning_amber_rounded
                : Icons.circle_outlined,
            color: task.overdue ? AppTheme.error : AppTheme.primaryTeal,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.customer != null && task.customer!.isNotEmpty)
                  Text(
                    task.customer!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          if (task.overdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'متأخرة',
                style: TextStyle(
                  color: AppTheme.error,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryTeal, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pipelineSummary() {
    final stages = ['Lead', 'Qualification', 'Proposal', 'Negotiation'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withAlpha(15)),
      ),
      child: Column(
        children: stages.map((stage) {
          final list = data.opportunities.where((o) => o.stage == stage).toList();
          final value = list.fold<double>(0, (sum, o) => sum + o.value);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _stageLabel(stage),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  '${list.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatMoney(value),
                  style: const TextStyle(
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'Lead':
        return 'تواصل أولي';
      case 'Qualification':
        return 'تأهيل';
      case 'Proposal':
        return 'عرض سعر';
      case 'Negotiation':
        return 'تفاوض';
      case 'Won':
        return 'رُبحت';
      case 'Lost':
        return 'خُسرت';
      default:
        return stage;
    }
  }

  String _formatMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
