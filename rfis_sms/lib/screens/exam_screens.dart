import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/record_form.dart';

const List<FieldDef> _questionFields = [
  FieldDef('text', 'نص السؤال', 'Question',
      type: FieldType.multiline, required: true),
  FieldDef('a', 'الخيار A', 'Option A', required: true),
  FieldDef('b', 'الخيار B', 'Option B', required: true),
  FieldDef('c', 'الخيار C', 'Option C', required: true),
  FieldDef('d', 'الخيار D', 'Option D', required: true),
  FieldDef('correct', 'الإجابة الصحيحة', 'True answer',
      type: FieldType.choice,
      required: true,
      options: [
        Opt('A', 'A', 'A'),
        Opt('B', 'B', 'B'),
        Opt('C', 'C', 'C'),
        Opt('D', 'D', 'D'),
      ]),
];

/// Question bank editor for one online exam.
class ExamQuestionsScreen extends StatelessWidget {
  const ExamQuestionsScreen({super.key, required this.examId});

  final String examId;

  Future<void> _add(BuildContext context) async {
    final app = context.app;
    final data = await showRecordForm(
      context,
      title: context.tr('إضافة سؤال', 'Add question'),
      fields: _questionFields,
    );
    if (data == null) return;
    app.add('questions', {...data, 'examId': examId});
  }

  Future<void> _edit(BuildContext context, Rec q) async {
    final app = context.app;
    final data = await showRecordForm(
      context,
      title: context.tr('تعديل السؤال', 'Edit question'),
      fields: _questionFields,
      initial: q.data,
    );
    if (data == null) return;
    app.update('questions', q.id, data);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final exam = app.find('exams', examId);
    final questions =
        app.table('questions').where((q) => q['examId'] == examId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(exam == null ? context.tr('الأسئلة', 'Questions') : exam['name']),
        actions: [
          IconButton(
            tooltip: context.tr('بدء الاختبار', 'Take exam'),
            icon: const Icon(Icons.play_arrow),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ExamTakeScreen(examId: examId),
              ));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('إضافة سؤال', 'Add question')),
      ),
      body: questions.isEmpty
          ? EmptyState(message: context.tr('لا توجد أسئلة', 'No questions'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              itemCount: questions.length,
              itemBuilder: (ctx, i) {
                final q = questions[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${i + 1}. ${q['text']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _edit(ctx, q),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await confirmDialog(
                                  ctx,
                                  ctx.tr('هل تريد حذف هذا السؤال؟', 'Delete this question?'),
                                );
                                if (ok) app.remove('questions', q.id);
                              },
                            ),
                          ],
                        ),
                        for (final letter in const ['A', 'B', 'C', 'D'])
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(
                                  q['correct'] == letter
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 18,
                                  color: q['correct'] == letter
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('$letter. ${q[letter.toLowerCase()]}'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Runs an online exam with a countdown. The result is shown but not written
/// to the marksheet (it is a staff preview of the student flow).
class ExamTakeScreen extends StatefulWidget {
  const ExamTakeScreen({super.key, required this.examId});

  final String examId;

  @override
  State<ExamTakeScreen> createState() => _ExamTakeScreenState();
}

class _ExamTakeScreenState extends State<ExamTakeScreen> {
  final Map<String, String> _answers = <String, String>{};
  Timer? _timer;
  int _remaining = 600;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    final exam = app.find('exams', widget.examId);
    final minutes = int.tryParse(exam?['duration'] ?? '') ?? 10;
    _remaining = (minutes < 1 ? 1 : minutes) * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) _submit();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _clock {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${twoDigits(m < 0 ? 0 : m)}:${twoDigits(s < 0 ? 0 : s)}';
  }

  Future<void> _submit() async {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();

    final app = context.app;
    final exam = app.find('exams', widget.examId);
    final questions = app
        .table('questions')
        .where((q) => q['examId'] == widget.examId)
        .toList();

    var correct = 0;
    for (final q in questions) {
      if (_answers[q.id] == q['correct']) correct++;
    }
    final max = double.tryParse(exam?['maxMark'] ?? '') ?? 100;
    final total = questions.length;
    final score = total == 0 ? 0.0 : correct / total * max;
    final pct = max == 0 ? 0.0 : score / max * 100;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('نتيجة الاختبار', 'Exam result')),
        content: Text(
          '${ctx.tr('الإجابات الصحيحة', 'Correct answers')}: $correct / $total\n'
          '${ctx.tr('الدرجة', 'Score')}: ${fmtNum(score)} / ${fmtNum(max)} (${pct.toStringAsFixed(1)}%)\n'
          '${ctx.tr('التقدير', 'Grade')}: ${gradeFor(pct)}\n\n'
          '${ctx.tr('معاينة فقط: لا تُحفظ النتيجة في كشف الدرجات.', 'Preview only: the result is not saved to the marksheet.')}',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr('إغلاق', 'Close')),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Widget _option(Rec q, String letter) {
    final selected = _answers[q.id] == letter;
    return ListTile(
      dense: true,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
      title: Text('$letter. ${q[letter.toLowerCase()]}'),
      onTap: _finished ? null : () => setState(() => _answers[q.id] = letter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final exam = app.find('exams', widget.examId);
    final questions = app
        .table('questions')
        .where((q) => q['examId'] == widget.examId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(exam == null ? context.tr('اختبار', 'Exam') : exam['name']),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18),
                  const SizedBox(width: 4),
                  Text(_clock, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: questions.isEmpty
          ? EmptyState(message: context.tr('لا توجد أسئلة لهذا الاختبار', 'This exam has no questions'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: questions.length,
                    itemBuilder: (ctx, i) {
                      final q = questions[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i + 1}. ${q['text']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              for (final letter in const ['A', 'B', 'C', 'D'])
                                _option(q, letter),
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
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.send),
                        label: Text(context.tr('تسليم الإجابات', 'Submit answers')),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
