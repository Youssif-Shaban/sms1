import 'package:flutter/material.dart';

import '../app_state.dart';
import '../util.dart';
import '../widgets/common.dart';

/// Marks which students of the assignment's class have submitted.
class AssignmentSubmissionsScreen extends StatelessWidget {
  const AssignmentSubmissionsScreen({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final assignment = app.find('assignments', assignmentId);
    if (assignment == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('التسليمات', 'Submissions'))),
        body: EmptyState(message: context.tr('الواجب غير موجود', 'Assignment not found')),
      );
    }

    final students = app.studentsOfClass(assignment['class']);
    final done = app.submissions[assignmentId] ?? <String>{};
    final submitted = students.where((s) => done.contains(s.id)).length;
    final ratio = students.isEmpty ? 0.0 : submitted / students.length;

    return Scaffold(
      appBar: AppBar(title: Text(assignment['title'])),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${assignment['class']} • ${assignment['subject']} • ${context.tr('الموعد النهائي', 'Deadline')}: ${fmtDate(assignment['end'])}',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: ratio, minHeight: 8),
                const SizedBox(height: 4),
                Text(
                  '${context.tr('تم التسليم', 'Submitted')}: $submitted / ${students.length} (${(ratio * 100).toStringAsFixed(0)}%)',
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        app.submissions[assignmentId] =
                            students.map((s) => s.id).toSet();
                        app.touch();
                      },
                      child: Text(context.tr('تحديد الكل', 'Mark all submitted')),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        app.submissions[assignmentId] = <String>{};
                        app.touch();
                      },
                      child: Text(context.tr('إلغاء الكل', 'Clear all')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: students.isEmpty
                ? EmptyState(message: context.tr('لا يوجد طلاب في هذا الفصل', 'No students in this class'))
                : ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (ctx, i) {
                      final s = students[i];
                      return SwitchListTile(
                        title: Text(s['name']),
                        subtitle: Text(s['code']),
                        value: done.contains(s.id),
                        onChanged: (_) => app.toggleSubmission(assignmentId, s.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
