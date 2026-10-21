import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';

/// Moves selected students from one class to another and keeps a log.
class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key});

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  String _from = '';
  String _to = '';
  Set<String> _selected = <String>{};

  void _chooseFrom(AppState app, String from) {
    _from = from;
    _selected = app.studentsOfClass(from).map((s) => s.id).toSet();
  }

  Future<void> _promote(AppState app) async {
    String? error;
    if (_from.isEmpty || _to.isEmpty) {
      error = context.tr('اختر الفصل الحالي والفصل الجديد', 'Select the current class and the new class');
    } else if (_from == _to) {
      error = context.tr('الفصل الجديد يجب أن يختلف عن الحالي', 'The new class must differ from the current class');
    } else if (_selected.isEmpty) {
      error = context.tr('اختر طالباً واحداً على الأقل', 'Select at least one student');
    }
    if (error != null) {
      snack(context, error);
      return;
    }
    final ok = await confirmDialog(
      context,
      context.tr(
        'نقل ${_selected.length} طالب من $_from إلى $_to؟',
        'Move ${_selected.length} students from $_from to $_to?',
      ),
    );
    if (!ok || !mounted) return;
    app.promote(_selected.toList(), _from, _to);
    setState(() => _selected = <String>{});
    snack(context, context.tr('تمت الترقية بنجاح', 'Promotion completed successfully'));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final classes = app.table('classes').map((c) => c['name']).toList();
    final students = _from.isEmpty ? <Rec>[] : app.studentsOfClass(_from);
    final allSelected =
        students.isNotEmpty && students.every((s) => _selected.contains(s.id));
    final log = <Rec>[...app.table('promotionLog')]..sort((a, b) =>
        '${b['date']} ${b['time']}'.compareTo('${a['date']} ${a['time']}'));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SectionCard(
          title: context.tr('ترقية الطلاب', 'Promotion'),
          icon: Icons.trending_up,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: classes.contains(_from) ? _from : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr('من الفصل', 'From class'),
                ),
                items: [
                  for (final c in classes)
                    DropdownMenuItem<String>(value: c, child: Text(c)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _chooseFrom(app, v));
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: classes.contains(_to) ? _to : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr('إلى الفصل', 'To class'),
                ),
                items: [
                  for (final c in classes)
                    DropdownMenuItem<String>(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _to = v ?? ''),
              ),
              const SizedBox(height: 8),
              if (students.isNotEmpty) ...[
                CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  value: allSelected,
                  title: Text(
                    '${context.tr('تحديد الكل', 'Select all')} (${_selected.length}/${students.length})',
                  ),
                  onChanged: (v) => setState(() {
                    _selected = (v ?? false)
                        ? students.map((s) => s.id).toSet()
                        : <String>{};
                  }),
                ),
                for (final s in students)
                  CheckboxListTile(
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _selected.contains(s.id),
                    title: Text(s['name']),
                    subtitle: Text(s['code']),
                    onChanged: (v) => setState(() {
                      if (v ?? false) {
                        _selected.add(s.id);
                      } else {
                        _selected.remove(s.id);
                      }
                    }),
                  ),
              ] else if (_from.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    context.tr('لا يوجد طلاب في هذا الفصل', 'No students in this class'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _promote(app),
                icon: const Icon(Icons.trending_up),
                label: Text(context.tr('ترقية', 'Promote')),
              ),
            ],
          ),
        ),
        SectionCard(
          title: context.tr('سجل الترقيات', 'Promotion history'),
          icon: Icons.history,
          child: log.isEmpty
              ? EmptyState(message: context.tr('لا توجد ترقيات', 'No promotions yet'))
              : Column(
                  children: [
                    for (final l in log)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.swap_horiz),
                        title: Text('${l['from']} → ${l['to']}'),
                        subtitle: Text(
                          '${l['count']} ${context.tr('طالب', 'students')} • ${fmtDate(l['date'])} ${l['time']} • ${l['by']}',
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
