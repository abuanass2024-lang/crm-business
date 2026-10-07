import '../../main.dart' show CrmData;

class AIAnswer {
  final String text;
  final String? category;
  const AIAnswer({required this.text, this.category});
}

class AssistantEngine {
  static AIAnswer ask(String question, CrmData data) {
    final q = question.toLowerCase().trim();

    // ═══════════════════════════════════════════════════════════
    // 1. عدد العملاء
    // ═══════════════════════════════════════════════════════════
    if (q.contains('كم عميل') || q.contains('عدد العملاء')) {
      final total = data.customers.length;
      final active = data.customers.where((c) => c.status == 'نشط').length;
      return AIAnswer(
        text: 'عندك $total عميل.\n$active نشط، ${total - active} بحاجة متابعة.',
        category: 'عملاء',
      );
    }

    // ═══════════════════════════════════════════════════════════
    // 2. قائمة العملاء
    // ═══════════════════════════════════════════════════════════
    if (q.contains('اعرض العملاء') || q.contains('قائمة العملاء')) {
      if (data.customers.isEmpty) return const AIAnswer(text: 'لا يوجد عملاء.');
      final buf = StringBuffer('العملاء (${data.customers.length}):\n');
      for (final c in data.customers.take(10)) {
        buf.writeln('• ${c.name} — ${c.company}');
      }
      if (data.customers.length > 10) {
        buf.writeln('... و${data.customers.length - 10} آخرون');
      }
      return AIAnswer(text: buf.toString(), category: 'عملاء');
    }

    // ═══════════════════════════════════════════════════════════
    // 3. البحث بالاسم
    // ═══════════════════════════════════════════════════════════
    if (q.startsWith('ابحث عن') || q.startsWith('ابحث لي عن')) {
      final name = q.replaceFirst('ابحث عن', '').replaceFirst('ابحث لي عن', '').trim();
      final found = data.customers.where((c) =>
          c.name.toLowerCase().contains(name) ||
          c.company.toLowerCase().contains(name)).toList();
      if (found.isEmpty) {
        return AIAnswer(text: 'لم أجد "$name".', category: 'بحث');
      }
      final buf = StringBuffer('وجدت ${found.length}:\n');
      for (final c in found.take(5)) {
        buf.writeln('• ${c.name} — ${c.company}');
        if (c.phone.isNotEmpty) buf.writeln('  📞 ${c.phone}');
      }
      return AIAnswer(text: buf.toString(), category: 'بحث');
    }

    // ═══════════════════════════════════════════════════════════
    // 4. أفضل مندوب
    // ═══════════════════════════════════════════════════════════
    if (q.contains('أفضل مندوب') || q.contains('افضل مندوب')) {
      final map = <String, int>{};
      for (final c in data.customers) {
        if (c.salesRep.isEmpty) continue;
        map[c.salesRep] = (map[c.salesRep] ?? 0) + 1;
      }
      if (map.isEmpty) return const AIAnswer(text: 'لا يوجد مندوبون بعد.');
      final sorted = map.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final buf = StringBuffer('أفضل المندوبين:\n');
      for (var i = 0; i < sorted.length && i < 5; i++) {
        final e = sorted[i];
        buf.writeln('${i + 1}. ${e.key} — ${e.value} عميل');
      }
      return AIAnswer(text: buf.toString(), category: 'أداء');
    }

    // ═══════════════════════════════════════════════════════════
    // 5. الفرص المفتوحة
    // ═══════════════════════════════════════════════════════════
    if (q.contains('فرص مفتوحة') || q.contains('فرصة مفتوحة')) {
      final open = data.opportunities
          .where((o) => o.stage != 'Won' && o.stage != 'Lost')
          .toList();
      if (open.isEmpty) return const AIAnswer(text: 'لا توجد فرص مفتوحة.');
      final buf = StringBuffer('عندك ${open.length} فرصة مفتوحة:\n');
      for (final o in open.take(5)) {
        buf.writeln('• ${o.title} — ${_money(o.value)} (${o.stage})');
      }
      return AIAnswer(text: buf.toString(), category: 'فرص');
    }

    // ═══════════════════════════════════════════════════════════
    // 6. عدد الفرص
    // ═══════════════════════════════════════════════════════════
    if (q.contains('كم فرصة') || q.contains('عدد الفرص')) {
      final total = data.opportunities.length;
      final open = data.opportunities
          .where((o) => o.stage != 'Won' && o.stage != 'Lost')
          .length;
      final won = data.opportunities.where((o) => o.stage == 'Won').length;
      return AIAnswer(
        text: 'إجمالي الفرص: $total\n'
            '• مفتوحة: $open\n'
            '• مربوحة: $won',
        category: 'فرص',
      );
    }

    // ═══════════════════════════════════════════════════════════
    // 7. المهام
    // ═══════════════════════════════════════════════════════════
    if (q.contains('مهام') || q.contains('مهمة')) {
      final overdue = data.tasks.where((t) => !t.done && t.overdue).toList();
      final today = data.tasks.where((t) => !t.done && t.today).toList();
      final done = data.tasks.where((t) => t.done).length;
      return AIAnswer(
        text: 'المهام:\n'
            '• 📅 اليوم: ${today.length}\n'
            '• ⚠️ متأخرة: ${overdue.length}\n'
            '• ✅ مكتملة: $done',
        category: 'مهام',
      );
    }

    // ═══════════════════════════════════════════════════════════
    // 8. ماذا أفعل اليوم
    // ═══════════════════════════════════════════════════════════
    if (q.contains('ماذا أفعل') || q.contains('اقترح') || q.contains('نصيحة')) {
      final buf = StringBuffer('اقتراحاتي اليوم:\n');
      var count = 0;
      final overdue = data.tasks.where((t) => !t.done && t.overdue).length;
      if (overdue > 0) {
        count++;
        buf.writeln('$count. أكمل $overdue مهمة متأخرة ⚠️');
      }
      final stale = data.customers
          .where((c) => DateTime.now().difference(c.createdAt).inDays > 30)
          .length;
      if (stale > 0) {
        count++;
        buf.writeln('$count. تابع $stale عميل قديم 📞');
      }
      final closing = data.opportunities.where((o) {
        if (o.expectedCloseDate == null) return false;
        final d = o.expectedCloseDate!.difference(DateTime.now()).inDays;
        return d >= 0 && d <= 7;
      }).length;
      if (closing > 0) {
        count++;
        buf.writeln('$count. راجع $closing فرصة تُغلق قريبًا 🎯');
      }
      if (count == 0) {
        buf.writeln('كل شيء تحت السيطرة ✅');
      }
      return AIAnswer(text: buf.toString(), category: 'توصية');
    }

    // ═══════════════════════════════════════════════════════════
    // 9. المبيعات
    // ═══════════════════════════════════════════════════════════
    if (q.contains('مبيعات') || q.contains('ربح')) {
      final won = data.opportunities.where((o) => o.stage == 'Won').toList();
      final total = won.fold<double>(0, (s, o) => s + o.value);
      return AIAnswer(
        text: 'إجمالي المبيعات:\n'
            '• ${won.length} صفقة\n'
            '• ${_money(total)} ر.ي',
        category: 'مبيعات',
      );
    }

    // ═══════════════════════════════════════════════════════════
    // 10. أعلى صفقة
    // ═══════════════════════════════════════════════════════════
    if (q.contains('أعلى صفقة') || q.contains('أكبر صفقة')) {
      if (data.opportunities.isEmpty) {
        return const AIAnswer(text: 'لا توجد فرص.');
      }
      final sorted = List.of(data.opportunities)
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      return AIAnswer(
        text: 'أعلى صفقة:\n'
            '• ${top.title}\n'
            '• ${_money(top.value)}\n'
            '• ${top.customer}',
        category: 'مبيعات',
      );
    }

    // ═══════════════════════════════════════════════════════════
    // 11. القطاعات
    // ═══════════════════════════════════════════════════════════
    if (q.contains('قطاع')) {
      final map = <String, int>{};
      for (final c in data.customers) {
        if (c.sector.isEmpty) continue;
        map[c.sector] = (map[c.sector] ?? 0) + 1;
      }
      if (map.isEmpty) return const AIAnswer(text: 'لا توجد بيانات قطاعات.');
      final buf = StringBuffer('العملاء حسب القطاع:\n');
      map.forEach((k, v) => buf.writeln('• $k: $v'));
      return AIAnswer(text: buf.toString(), category: 'قطاعات');
    }

    // ═══════════════════════════════════════════════════════════
    // 12. الفروع
    // ═══════════════════════════════════════════════════════════
    if (q.contains('فرع')) {
      final map = <String, int>{};
      for (final c in data.customers) {
        if (c.branch.isEmpty) continue;
        map[c.branch] = (map[c.branch] ?? 0) + 1;
      }
      if (map.isEmpty) return const AIAnswer(text: 'لا توجد بيانات فروع.');
      final buf = StringBuffer('العملاء حسب الفرع:\n');
      map.forEach((k, v) => buf.writeln('• $k: $v'));
      return AIAnswer(text: buf.toString(), category: 'فروع');
    }

    // ═══════════════════════════════════════════════════════════
    // 13. حالة عميل
    // ═══════════════════════════════════════════════════════════
    if (q.startsWith('حالة')) {
      final name = q.replaceFirst('حالة', '').trim();
      final found = data.customers.where((c) => c.name.contains(name)).toList();
      if (found.isEmpty) {
        return AIAnswer(text: 'لم أجد عميل "$name".', category: 'بحث');
      }
      final c = found.first;
      final opps = data.opportunities.where((o) => o.customer == c.name).length;
      final tasks = data.tasks.where((t) => t.customer == c.name).length;
      return AIAnswer(
        text: '${c.name}:\n'
            '• الشركة: ${c.company}\n'
            '• الحالة: ${c.status}\n'
            '• الفرص: $opps\n'
            '• المهام: $tasks',
        category: 'عميل',
      );
    }

    // ═══════════════════════════════════════════════════════════
    // 14. المساعدة
    // ═══════════════════════════════════════════════════════════
    if (q.contains('مساعدة') || q.contains('مرحبا') || q.contains('اهلا') || q.contains('السلام')) {
      return const AIAnswer(
        text: 'مرحبًا! 🤖\n'
            'جرّب أن تسأل:\n'
            '• كم عميل عندي؟\n'
            '• اعرض العملاء\n'
            '• ابحث عن [اسم]\n'
            '• من أفضل مندوب؟\n'
            '• كم فرصة مفتوحة؟\n'
            '• ما المهام المتأخرة؟\n'
            '• ماذا أفعل اليوم؟\n'
            '• كم مبيعاتي؟\n'
            '• أعلى صفقة\n'
            '• عملاء القطاع\n'
            '• أداء فرع\n'
            '• حالة [اسم]',
        category: 'مساعدة',
      );
    }

    // ═══════════════════════════════════════════════════════════
    // 15. افتراضي
    // ═══════════════════════════════════════════════════════════
    return const AIAnswer(
      text: 'لم أفهم السؤال 🤔\n'
          'جرّب:\n'
          '• كم عميل عندي؟\n'
          '• اعرض العملاء\n'
          '• ابحث عن أحمد\n'
          '• من أفضل مندوب؟\n'
          '• ماذا أفعل اليوم؟\n'
          '• كم مبيعاتي؟',
      category: 'عام',
    );
  }

  static String _money(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
