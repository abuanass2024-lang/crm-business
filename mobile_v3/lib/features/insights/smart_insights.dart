import 'package:flutter/material.dart';
import '../../main.dart' show CrmData, Customer, Opportunity, CrmTask;
import '../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════
/// Smart Insights — محرك التحليلات الذكية
/// ═══════════════════════════════════════════════════════════
/// قواعد منطقية تولّد تحذيرات واقتراحات من بيانات CRM
/// بدون AI حقيقي — فقط قواعد واضحة وقابلة للتفسير

enum InsightPriority {
  critical, // 🔴 عاجل
  warning,  // 🟡 تحذير
  info,     // 🔵 معلومة
  success,  // 🟢 إنجاز
}

class Insight {
  final IconData icon;
  final String title;
  final String description;
  final InsightPriority priority;
  final String? actionLabel;
  final VoidCallback? onAction;

  const Insight({
    required this.icon,
    required this.title,
    required this.description,
    required this.priority,
    this.actionLabel,
    this.onAction,
  });

  Color get color {
    switch (priority) {
      case InsightPriority.critical:
        return AppTheme.error;
      case InsightPriority.warning:
        return AppTheme.amber;
      case InsightPriority.info:
        return AppTheme.cyan;
      case InsightPriority.success:
        return AppTheme.success;
    }
  }
}

class SmartInsights {
  /// توليد كل التحليلات من بيانات CRM
  static List<Insight> generate(CrmData data) {
    final insights = <Insight>[];

    insights.addAll(_staleCustomers(data));
    insights.addAll(_overdueTasks(data));
    insights.addAll(_closingOpportunities(data));
    insights.addAll(_topCustomer(data));
    insights.addAll(_untouchedOpportunities(data));
    insights.addAll(_weekWins(data));
    insights.addAll(_pipelineHealth(data));

    // ترتيب حسب الأولوية
    insights.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    return insights;
  }

  // ═══════════════════════════════════════════════════════════
  // 1. عملاء لم يُتابعوا
  // ═══════════════════════════════════════════════════════════
  static List<Insight> _staleCustomers(CrmData data) {
    final now = DateTime.now();
    final stale = <Customer>[];

    for (final c in data.customers) {
      final days = now.difference(c.createdAt).inDays;
      if (days > 30 && c.status != 'خامل') {
        stale.add(c);
      }
    }

    if (stale.isEmpty) return [];

    return [
      Insight(
        icon: Icons.person_off_rounded,
        title: '${stale.length} عميل بحاجة للمتابعة',
        description: 'مضى أكثر من 30 يومًا دون تفاعل مسجّل',
        priority: InsightPriority.critical,
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════
  // 2. مهام متأخرة
  // ═══════════════════════════════════════════════════════════
  static List<Insight> _overdueTasks(CrmData data) {
    final overdue = data.tasks.where((t) => !t.done && t.overdue).toList();

    if (overdue.isEmpty) return [];

    return [
      Insight(
        icon: Icons.warning_amber_rounded,
        title: '${overdue.length} مهمة متأخرة',
        description: overdue.first.title +
            (overdue.length > 1 ? ' و${overdue.length - 1} أخرى' : ''),
        priority: InsightPriority.critical,
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════
  // 3. فرص قريبة من الإغلاق
  // ═══════════════════════════════════════════════════════════
  static List<Insight> _closingOpportunities(CrmData data) {
    final now = DateTime.now();
    final upcoming = data.opportunities.where((o) {
      if (o.stage == 'Won' || o.stage == 'Lost') return false;
      if (o.expectedCloseDate == null) return false;
      final days = o.expectedCloseDate!.difference(now).inDays;
      return days >= 0 && days <= 7;
    }).toList();

    if (upcoming.isEmpty) return [];

    return [
      Insight(
        icon: Icons.timer_rounded,
        title: '${upcoming.length} فرصة تُغلق هذا الأسبوع',
        description: 'راجعها قبل فوات الوقت',
        priority: InsightPriority.warning,
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════
  // 4. أفضل عميل
  // ═══════════════════════════════════════════════════════════
  static List<Insight> _topCustomer(CrmData data) {
    if (data.customers.isEmpty) return [];

    final Map<String, double> revenueByCustomer = {};
    for (final o in data.opportunities) {
      if (o.stage == 'Won') {
        revenueByCustomer[o.customer] =
            (revenueByCustomer[o.customer] ?? 0) + o.value;
      }
    }

    if (revenueByCustomer.isEmpty) return [];

    final top = revenueByCustomer.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return [
      Insight(
        icon: Icons.emoji_events_rounded,
        title: 'أفضل عميل: ${top.key}',
        description: 'بإجمالي ${_money(top.value)} من الصفقات المُغلقة',
        priority: InsightPriority.success,
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════
  // 5. فرص بدون متابعة
  // ═══════════════════════════════════════════════════════════
  static List<Insight> _untouchedOpportunities(CrmData data) {
    final stuck = data.opportunities.where((o) {
      if (o.stage == 'Won' || o.stage == 'Lost') return false;
      final days = DateTime.now().difference(o.createdAt).inDays;
      return days > 21;
    }).toList();

    if (stuck.isEmpty) return [];

    return [
      Insight(
        icon: Icons.trending_flat_rounded,
        title: '${stuck.length} فرصة راكدة',
        description: 'مضى أكثر من 21 يومًا دون تقدم',
        priority: InsightPriority.warning,
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════
  // 6. إنجازات الأسبوع
  // ═══════════════════════════════════════════════════════════
  static List<Insight> _weekWins(CrmData data) {
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));

    final wonThisWeek = data.opportunities.where((o) {
      return o.stage == 'Won' && o.createdAt.isAfter(weekStart);
    }).toList();

    final doneTasks = data.tasks.where((t) {
      return t.done && t.createdAt.isAfter(weekStart);
    }).length;

    if (wonThisWeek.isEmpty && doneTasks == 0) return [];

    final totalValue =
        wonThisWeek.fold<double>(0, (sum, o) => sum + o.value);

    return [
      Insight(
        icon: Icons.celebration_rounded,
        title: 'إنجازات الأسبوع 🎉',
        description:
            '${wonThisWeek.length} صفقة (${_money(totalValue)}) • $doneTasks مهمة منجزة',
        priority: InsightPriority.success,
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════
  // 7. صحة Pipeline
  // ═══════════════════════════════════════════════════════════
  static List<Insight> _pipelineHealth(CrmData data) {
    final open = data.opportunities
        .where((o) => o.stage != 'Won' && o.stage != 'Lost')
        .toList();

    if (open.isEmpty) {
      return [
        const Insight(
          icon: Icons.info_outline_rounded,
          title: 'Pipeline فارغ',
          description: 'ابدأ بإضافة فرصة جديدة',
          priority: InsightPriority.info,
        ),
      ];
    }

    final totalValue = open.fold<double>(0, (sum, o) => sum + o.value);
    final avgProb = open.fold<int>(0, (sum, o) => sum + o.probability) /
        open.length;

    return [
      Insight(
        icon: Icons.insights_rounded,
        title: 'صحة Pipeline',
        description:
            '${open.length} فرصة • ${_money(totalValue)} • احتمالية ${avgProb.toStringAsFixed(0)}%',
        priority: avgProb > 50
            ? InsightPriority.success
            : InsightPriority.info,
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════
  // Helper
  // ═══════════════════════════════════════════════════════════
  static String _money(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}

/// ═══════════════════════════════════════════════════════════
/// InsightCard — بطاقة عرض تحليل واحد
/// ═══════════════════════════════════════════════════════════
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final color = insight.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(insight.icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  insight.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
