import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/record_form.dart';

/// Weekly schedule of one class (Sunday to Thursday), editable.
class ClassScheduleScreen extends StatelessWidget {
  const ClassScheduleScreen({super.key, required this.className});

  final String className;

  Future<void> _add(BuildContext context, int day) async {
    final app = context.app;
    final data = await showRecordForm(
      context,
      title: context.tr('إضافة حصة', 'Add schedule'),
      fields: const [
        FieldDef('subject', 'المادة', 'Subject',
            type: FieldType.ref, refTable: 'subjects', required: true),
        FieldDef('start', 'وقت البداية (HH:mm)', 'Start time (HH:mm)',
            required: true),
        FieldDef('end', 'وقت النهاية (HH:mm)', 'End time (HH:mm)',
            required: true),
      ],
      validate: (v) {
        final s = (v['start'] ?? '').trim();
        final e = (v['end'] ?? '').trim();
        if (!isValidTime(s) || !isValidTime(e)) {
          return context.tr('صيغة الوقت يجب أن تكون HH:mm', 'Time format must be HH:mm');
        }
        final sm = timeToMinutes(s);
        final em = timeToMinutes(e);
        if (em <= sm) {
          return context.tr('وقت النهاية يجب أن يكون بعد البداية', 'End time must be after start time');
        }
        for (final r in app.table('schedule')) {
          if (r['class'] != className || r['day'] != '$day') continue;
          final rs = timeToMinutes(r['start']);
          final re = timeToMinutes(r['end']);
          if (sm < re && em > rs) {
            return context.tr('يتعارض مع حصة أخرى (${r['subject']})', 'Overlaps another period (${r['subject']})');
          }
        }
        return null;
      },
    );
    if (data == null) return;
    app.add('schedule', {
      'class': className,
      'day': '$day',
      'subject': data['subject'] ?? '',
      'start': normalizeTime(data['start'] ?? '00:00'),
      'end': normalizeTime(data['end'] ?? '00:00'),
    });
    if (context.mounted) {
      snack(context, context.tr('تمت إضافة الحصة', 'Schedule added'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${context.tr('جدول الحصص', 'Class schedule')} - $className'),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              for (var i = 0; i < 5; i++) Tab(text: context.tr(kDaysAr[i], kDaysEn[i])),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (ctx) => FloatingActionButton.extended(
            onPressed: () => _add(ctx, DefaultTabController.of(ctx).index),
            icon: const Icon(Icons.add),
            label: Text(ctx.tr('إضافة حصة', 'Add schedule')),
          ),
        ),
        body: TabBarView(
          children: [
            for (var i = 0; i < 5; i++) _DayList(className: className, day: i),
          ],
        ),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.className, required this.day});

  final String className;
  final int day;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final rows = app
        .table('schedule')
        .where((r) => r['class'] == className && r['day'] == '$day')
        .toList()
      ..sort((a, b) => timeToMinutes(a['start']).compareTo(timeToMinutes(b['start'])));

    if (rows.isEmpty) {
      return EmptyState(message: context.tr('لا توجد حصص', 'No classes'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      itemCount: rows.length,
      itemBuilder: (ctx, i) {
        final r = rows[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(r['subject']),
            subtitle: Text('${r['start']} - ${r['end']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await confirmDialog(
                  ctx,
                  ctx.tr('هل تريد حذف هذه الحصة؟', 'Delete this period?'),
                );
                if (ok) app.remove('schedule', r.id);
              },
            ),
          ),
        );
      },
    );
  }
}
