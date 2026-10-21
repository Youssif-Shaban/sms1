import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';

/// Marks entry per exam (with live percentage, grade and class statistics)
/// and a per-student marks report.
///
/// Grade scale: A >= 90, B >= 80, C >= 70, D >= 60, otherwise F.
/// Percentage = mark / max mark x 100. Pass mark = 60%.
class MarksheetScreen extends StatefulWidget {
  const MarksheetScreen({super.key});

  @override
  State<MarksheetScreen> createState() => _MarksheetScreenState();
}

class _MarksheetScreenState extends State<MarksheetScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _examId = '';
  String _studentId = '';
  final Map<String, TextEditingController> _ctrls =
      <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: app.marksheetTab == 1 ? 1 : 0,
    );
    final exams = app.table('exams');
    final students = app.table('students');
    _examId = app.marksheetExamId ?? (exams.isNotEmpty ? exams.first.id : '');
    _studentId =
        app.marksheetStudentId ?? (students.isNotEmpty ? students.first.id : '');
    app.marksheetExamId = null;
    app.marksheetStudentId = null;
    app.marksheetTab = 0;
    _loadExam(app);
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadExam(AppState app) {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    _ctrls.clear();
    final exam = app.find('exams', _examId);
    if (exam == null) return;
    final saved = app.marks[_examId] ?? <String, double>{};
    for (final s in app.studentsOfClass(exam['class'])) {
      final v = saved[s.id];
      _ctrls[s.id] = TextEditingController(text: v == null ? '' : fmtNum(v));
    }
  }

  void _saveMarks(AppState app, double max, List<Rec> students) {
    final out = <String, double>{};
    for (final s in students) {
      final text = _ctrls[s.id]?.text.trim() ?? '';
      if (text.isEmpty) continue;
      final v = double.tryParse(text);
      if (v == null || v < 0 || v > max) {
        snack(
          context,
          '${s['name']}: ${context.tr('الدرجة يجب أن تكون بين 0 و', 'Mark must be between 0 and')} ${fmtNum(max)}',
        );
        return;
      }
      out[s.id] = v;
    }
    app.saveMarks(_examId, out);
    snack(context, context.tr('تم حفظ الدرجات', 'Marks saved successfully'));
  }

  Widget _examTab(BuildContext context, AppState app) {
    final exams = app.table('exams');
    if (exams.isEmpty) {
      return EmptyState(message: context.tr('لا توجد اختبارات', 'No exams'));
    }
    final exam = app.find('exams', _examId);
    final max = double.tryParse(exam?['maxMark'] ?? '') ?? 100;
    final students = exam == null ? <Rec>[] : app.studentsOfClass(exam['class']);

    final values = <double>[];
    for (final s in students) {
      final v = double.tryParse(_ctrls[s.id]?.text.trim() ?? '');
      if (v != null && v >= 0 && v <= max) values.add(v);
    }
    final hasValues = values.isNotEmpty;
    final avg = hasValues ? values.reduce((a, b) => a + b) / values.length : 0.0;
    final hi = hasValues ? values.reduce((a, b) => a > b ? a : b) : 0.0;
    final lo = hasValues ? values.reduce((a, b) => a < b ? a : b) : 0.0;
    final passed = values.where((v) => v / max * 100 >= 60).length;
    final passRate = hasValues ? passed / values.length * 100 : 0.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            value: exams.any((e) => e.id == _examId) ? _examId : null,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              labelText: context.tr('الاختبار', 'Exam'),
            ),
            items: [
              for (final e in exams)
                DropdownMenuItem<String>(
                  value: e.id,
                  child: Text(
                    '${e['name']} • ${e['class']} • ${e['subject']}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _examId = v;
                _loadExam(app);
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusChip(
                label: '${context.tr('المُدخلة', 'Entered')}: ${values.length}/${students.length}',
                color: Colors.blueGrey,
              ),
              StatusChip(
                label: '${context.tr('المتوسط', 'Average')}: ${hasValues ? fmtNum(double.parse(avg.toStringAsFixed(1))) : '-'}',
                color: Colors.blue,
              ),
              StatusChip(
                label: '${context.tr('الأعلى', 'Highest')}: ${hasValues ? fmtNum(hi) : '-'}',
                color: Colors.green,
              ),
              StatusChip(
                label: '${context.tr('الأدنى', 'Lowest')}: ${hasValues ? fmtNum(lo) : '-'}',
                color: Colors.red,
              ),
              StatusChip(
                label: '${context.tr('نسبة النجاح', 'Pass rate')}: ${hasValues ? passRate.toStringAsFixed(0) : '-'}%',
                color: Colors.purple,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(),
        Expanded(
          child: students.isEmpty
              ? EmptyState(message: context.tr('لا يوجد طلاب في هذا الفصل', 'No students in this class'))
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (ctx, i) {
                    final s = students[i];
                    final ctrl = _ctrls[s.id];
                    final text = ctrl?.text.trim() ?? '';
                    final v = double.tryParse(text);
                    final invalid = text.isNotEmpty && (v == null || v < 0 || v > max);
                    final pct = (v != null && !invalid && max > 0) ? v / max * 100 : null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(s['name'], overflow: TextOverflow.ellipsis),
                          ),
                          SizedBox(
                            width: 96,
                            child: TextField(
                              controller: ctrl,
                              textAlign: TextAlign.center,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                isDense: true,
                                suffixText: '/${fmtNum(max)}',
                                errorText: invalid ? '' : null,
                                errorStyle: const TextStyle(height: 0, fontSize: 0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: Text(
                              pct == null ? '-' : '${pct.toStringAsFixed(1)}%',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 28,
                            child: Text(
                              pct == null ? '' : gradeFor(pct),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: students.isEmpty ? null : () => _saveMarks(app, max, students),
                icon: const Icon(Icons.save_outlined),
                label: Text(context.tr('حفظ الدرجات', 'Add/Update Marks')),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _studentTab(BuildContext context, AppState app) {
    final students = app.table('students');
    if (students.isEmpty) {
      return EmptyState(message: context.tr('لا يوجد طلاب', 'No students'));
    }
    final student = app.find('students', _studentId);
    final exams = student == null
        ? <Rec>[]
        : app.table('exams').where((e) => e['class'] == student['class']).toList();

    var sumMarks = 0.0;
    var sumMax = 0.0;
    for (final e in exams) {
      final m = app.marks[e.id]?[_studentId];
      final max = double.tryParse(e['maxMark']) ?? 0;
      if (m != null && max > 0) {
        sumMarks += m;
        sumMax += max;
      }
    }
    final overall = sumMax == 0 ? null : sumMarks / sumMax * 100;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        DropdownButtonFormField<String>(
          value: students.any((s) => s.id == _studentId) ? _studentId : null,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            labelText: context.tr('الطالب', 'Student'),
          ),
          items: [
            for (final s in students)
              DropdownMenuItem<String>(
                value: s.id,
                child: Text('${s['name']} • ${s['class']}'),
              ),
          ],
          onChanged: (v) => setState(() => _studentId = v ?? ''),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: context.tr('الدرجات', 'List grades'),
          icon: Icons.grading_outlined,
          child: exams.isEmpty
              ? EmptyState(message: context.tr('لا توجد اختبارات', 'No exams'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text(context.tr('الاختبار', 'Exam'))),
                          DataColumn(label: Text(context.tr('المادة', 'Subject'))),
                          DataColumn(label: Text(context.tr('الدرجة', 'Mark'))),
                          const DataColumn(label: Text('%')),
                          DataColumn(label: Text(context.tr('التقدير', 'Grade'))),
                        ],
                        rows: [
                          for (final e in exams)
                            () {
                              final m = app.marks[e.id]?[_studentId];
                              final max = double.tryParse(e['maxMark']) ?? 0;
                              final pct = (m != null && max > 0) ? m / max * 100 : null;
                              return DataRow(cells: [
                                DataCell(Text(e['name'])),
                                DataCell(Text(e['subject'])),
                                DataCell(Text(m == null ? '-' : '${fmtNum(m)}/${fmtNum(max)}')),
                                DataCell(Text(pct == null ? '-' : pct.toStringAsFixed(1))),
                                DataCell(Text(pct == null ? '-' : gradeFor(pct))),
                              ]);
                            }(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${context.tr('المعدل العام', 'Overall')}: '
                      '${overall == null ? '-' : '${overall.toStringAsFixed(1)}% (${gradeFor(overall)})'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      context.tr(
                        'المعدل العام = مجموع الدرجات ÷ مجموع الدرجات العظمى للاختبارات التي لها درجات.',
                        'Overall = sum of marks / sum of max marks, for exams that have a mark.',
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Column(
      children: [
        TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: context.tr('درجات الاختبار', 'Exam marks')),
            Tab(text: context.tr('كشف الطالب', 'Student report')),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _examTab(context, app),
              _studentTab(context, app),
            ],
          ),
        ),
      ],
    );
  }
}
