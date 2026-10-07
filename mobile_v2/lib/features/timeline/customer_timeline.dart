import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════
/// Customer Timeline — عرض كل تفاعلات العميل
/// ═══════════════════════════════════════════════════════════

class TimelineEvent {
  final IconData icon;
  final String title;
  final String? description;
  final DateTime date;
  final Color color;
  final String type;

  const TimelineEvent({
    required this.icon,
    required this.title,
    this.description,
    required this.date,
    required this.color,
    required this.type,
  });
}

class CustomerTimeline extends StatelessWidget {
  const CustomerTimeline({
    super.key,
    required this.events,
  });

  final List<TimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _emptyState();
    }

    final sorted = List<TimelineEvent>.from(events)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.timeline_rounded,
              color: AppTheme.primaryTeal,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text(
              'السجل الزمني',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${events.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
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
            children: sorted.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isLast = index == sorted.length - 1;
              return _timelineRow(event, isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _timelineRow(TimelineEvent event, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══ Icon + Line ═══
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: event.color.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(color: event.color, width: 2),
                ),
                child: Icon(event.icon, color: event.color, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.black.withAlpha(20),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // ═══ Content ═══
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(event.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: event.color.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.type,
                      style: TextStyle(
                        fontSize: 10,
                        color: event.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timeline_rounded, color: AppTheme.primaryTeal, size: 22),
            const SizedBox(width: 8),
            const Text(
              'السجل الزمني',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withAlpha(15)),
          ),
          child: const Center(
            child: Text(
              'لا توجد تفاعلات مسجّلة',
              style: TextStyle(color: Colors.black38, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);

    if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} د';
    }
    if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} س';
    }
    if (diff.inDays < 7) {
      return 'منذ ${diff.inDays} ي';
    }
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }
}
