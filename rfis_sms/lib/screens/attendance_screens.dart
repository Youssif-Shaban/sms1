import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';

/// Take attendance for one class and one date.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String _class = '';
  String _date = iso(today());
  Map<String, AttStatus> _status = <String, AttStatus>{};

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    final classes = app.table('classes');
    if (classes.isNotEmpty) {
      _class = classes.first['name'];
      _load(app);
    }
  }

  /// Loads the saved attendance for the class/date, or defaults everyone to
  /// Present when nothing has been saved yet.
  void _load(AppState app) {
    final students = app.studentsOfClass(_class);
    final saved = app.attendanceFor(_class, _date);
    _status = <String, AttStatus>{
      for (final s in students) s.id: saved?[s.id] ?? AttStatus.present,
    };
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final classes = app.table('classes').map((c) => c['name']).toList();
    final students = app.studentsOfClass(_class);
    final counts = <AttStatus, int>{
      for (final s in AttStatus.values) s: 0,
    };
    for (final s in students) {
      final st = _status[s.id] ?? AttStatus.present;
      counts[st] = (counts[st] ?? 0) + 1;
    }
    final attended = students.where((s) => (_status[s.id] ?? AttStatus.present).attended).length;
    final pct = students.isEmpty ? 0.0 : attended / students.length * 100;
    final savedBefore = app.attendanceFor(_class, _date) != null;
    final weekend = (parseIso(_date) != null) && sundayIndex(parseIso(_date)!) > 4;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: classes.contains(_class) ? _class : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: context.tr('الفصل', 'Class'),
                  ),
                  items: [
                    for (final c in classes)
                      DropdownMenuItem<String>(value: c, child: Text(c)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _class = v;
                      _load(app);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await pickDate(context, _date);
                  if (picked == null) return;
                  setState(() {
                    _date = picked;
                    _load(app);
                  });
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(fmtDate(_date)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in AttStatus.values)
                StatusChip(
                  label: '${context.tr(s.ar, s.en)}: ${counts[s]}',
                  color: s.color,
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${context.tr('نسبة الحضور اليوم', 'Attendance today')}: ${pct.toStringAsFixed(1)}% • '
              '${savedBefore ? context.tr('محفوظ', 'Saved') : context.tr('غير محفوظ', 'Not saved yet')}'
              '${weekend ? ' • ${context.tr('عطلة نهاية الأسبوع', 'Weekend')}' : ''}',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: students.isEmpty
              ? EmptyState(message: context.tr('لا يوجد طلاب في هذا الفصل', 'No students in this class'))
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (ctx, i) {
                    final s = students[i];
                    final st = _status[s.id] ?? AttStatus.present;
                    return ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text(s['name']),
                      subtitle: Text(s['code']),
                      trailing: PopupMenuButton<AttStatus>(
                        initialValue: st,
                        onSelected: (v) => setState(() => _status[s.id] = v),
                        itemBuilder: (pctx) => [
                          for (final option in AttStatus.values)
                            PopupMenuItem<AttStatus>(
                              value: option,
                              child: Text(pctx.tr(option.ar, option.en)),
                            ),
                        ],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusChip(label: ctx.tr(st.ar, st.en), color: st.color),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: students.isEmpty
                        ? null
                        : () => setState(() {
                              for (final s in students) {
                                _status[s.id] = AttStatus.present;
                              }
                            }),
                    child: Text(context.tr('الكل حاضر', 'Mark all present')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: students.isEmpty
                        ? null
                        : () {
                            app.saveAttendance(_class, _date, _status);
                            snack(context, context.tr('تم حفظ الحضور بنجاح', 'Attendance saved successfully'));
                          },
                    icon: const Icon(Icons.save_outlined),
                    label: Text(context.tr('حفظ الحضور', 'Save attendance')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportRow {
  _ReportRow(this.student);

  final Rec student;
  final Map<AttStatus, int> counts = <AttStatus, int>{};

  int get total => counts.values.fold<int>(0, (a, b) => a + b);

  int get attended {
    var n = 0;
    counts.forEach((status, count) {
      if (status.attended) n += count;
    });
    return n;
  }

  /// null when the student has no records in the range.
  double? get percent => total == 0 ? null : attended / total * 100;
}

/// Attendance statistics per student for a class and date range, the list of
/// absences, and a CSV export (copied to the clipboard).
class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  String _class = '';
  String _from = iso(addDays(today(), -30));
  String _to = iso(today());

  Future<void> _pick(bool from) async {
    final picked = await pickDate(context, from ? _from : _to);
    if (picked == null) return;
    setState(() {
      if (from) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final classes = app.table('classes').map((c) => c['name']).toList();

    final byStudent = <String, _ReportRow>{};
    final absences = <List<String>>[]; // [date, studentId, class]
    for (final entry in app.attendance.entries) {
      final sep = entry.key.indexOf('|');
      if (sep < 0) continue;
      final cls = entry.key.substring(0, sep);
      final date = entry.key.substring(sep + 1);
      if (_class.isNotEmpty && cls != _class) continue;
      if (date.compareTo(_from) < 0 || date.compareTo(_to) > 0) continue;
      entry.value.forEach((studentId, status) {
        final student = app.find('students', studentId);
        if (student == null) return;
        final row = byStudent.putIfAbsent(studentId, () => _ReportRow(student));
        row.counts[status] = (row.counts[status] ?? 0) + 1;
        if (status == AttStatus.absent) absences.add([date, studentId, cls]);
      });
    }
    final rows = byStudent.values.toList()
      ..sort((a, b) => (a.percent ?? 101).compareTo(b.percent ?? 101));
    absences.sort((a, b) => b[0].compareTo(a[0]));

    final rangeInvalid = _from.compareTo(_to) > 0;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SectionCard(
          title: context.tr('خيارات البحث', 'Search for attendance (select filters)'),
          icon: Icons.filter_alt_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _class,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: context.tr('الفصل', 'Class'),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: '',
                    child: Text(context.tr('كل الفصول', 'All classes')),
                  ),
                  for (final c in classes)
                    DropdownMenuItem<String>(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _class = v ?? ''),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pick(true),
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text('${context.tr('من', 'From')}: ${fmtDate(_from)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pick(false),
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text('${context.tr('إلى', 'To')}: ${fmtDate(_to)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: rows.isEmpty
                        ? null
                        : () async {
                            final lines = <String>[
                              [
                                'Student code',
                                'Student',
                                'Class',
                                'Present',
                                'Late',
                                'Late with excuse',
                                'Absent',
                                'Early dismissal',
                                'Attendance %',
                              ].map(csvCell).join(','),
                            ];
                            for (final r in rows) {
                              lines.add([
                                r.student['code'],
                                r.student['name'],
                                r.student['class'],
                                '${r.counts[AttStatus.present] ?? 0}',
                                '${r.counts[AttStatus.late] ?? 0}',
                                '${r.counts[AttStatus.lateExcuse] ?? 0}',
                                '${r.counts[AttStatus.absent] ?? 0}',
                                '${r.counts[AttStatus.earlyDismissal] ?? 0}',
                                r.percent == null ? '' : r.percent!.toStringAsFixed(1),
                              ].map(csvCell).join(','));
                            }
                            await Clipboard.setData(ClipboardData(text: lines.join('\n')));
                            if (context.mounted) {
                              snack(context, context.tr('تم نسخ CSV إلى الحافظة', 'CSV copied to clipboard'));
                            }
                          },
                    icon: const Icon(Icons.file_download_outlined, size: 18),
                    label: Text(context.tr('تصدير CSV', 'Export to CSV')),
                  ),
                ],
              ),
              if (rangeInvalid)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    context.tr('تاريخ البداية بعد تاريخ النهاية', 'The From date is after the To date'),
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
        SectionCard(
          title: context.tr('إحصائيات الحضور', 'Attendance statistics'),
          icon: Icons.assessment_outlined,
          child: rows.isEmpty
              ? EmptyState(message: context.tr('لا توجد بيانات', 'No Data Available'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 18,
                        columns: [
                          DataColumn(label: Text(context.tr('الطالب', 'Student'))),
                          DataColumn(label: Text(context.tr('الفصل', 'Class'))),
                          DataColumn(label: Text(context.tr('ح', 'P'))),
                          DataColumn(label: Text(context.tr('ت', 'L'))),
                          DataColumn(label: Text(context.tr('ع', 'E'))),
                          DataColumn(label: Text(context.tr('غ', 'A'))),
                          DataColumn(label: Text(context.tr('ص', 'D'))),
                          const DataColumn(label: Text('%')),
                        ],
                        rows: [
                          for (final r in rows)
                            DataRow(cells: [
                              DataCell(Text(r.student['name'])),
                              DataCell(Text(r.student['class'])),
                              DataCell(Text('${r.counts[AttStatus.present] ?? 0}')),
                              DataCell(Text('${r.counts[AttStatus.late] ?? 0}')),
                              DataCell(Text('${r.counts[AttStatus.lateExcuse] ?? 0}')),
                              DataCell(Text('${r.counts[AttStatus.absent] ?? 0}')),
                              DataCell(Text('${r.counts[AttStatus.earlyDismissal] ?? 0}')),
                              DataCell(Text(
                                r.percent == null ? '-' : r.percent!.toStringAsFixed(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: (r.percent ?? 100) < 85 ? Colors.red : Colors.green,
                                ),
                              )),
                            ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        'ح: حاضر، ت: متأخر، ع: متأخر بعذر، غ: غائب، ص: انصراف مبكر. النسبة = (كل الحالات عدا الغياب) ÷ إجمالي السجلات.',
                        'P: present, L: late, E: late with excuse, A: absent, D: early dismissal. Percent = (all statuses except Absent) / total records.',
                      ),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
        ),
        SectionCard(
          title: context.tr('تقرير غياب الطلاب', 'Student absence report'),
          icon: Icons.person_off_outlined,
          child: absences.isEmpty
              ? EmptyState(message: context.tr('لا توجد حالات غياب', 'No absences'))
              : Column(
                  children: [
                    for (final a in absences)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_busy_outlined, color: Colors.red),
                        title: Text(app.find('students', a[1])?['name'] ?? '-'),
                        subtitle: Text('${a[2]} • ${fmtDate(a[0])}'),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
