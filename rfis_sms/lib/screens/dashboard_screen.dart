import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';
import '../widgets/record_form.dart';

IconData _resourceIcon(String type) {
  switch (type) {
    case 'PPTX':
      return Icons.slideshow_outlined;
    case 'PDF':
      return Icons.picture_as_pdf_outlined;
    case 'DOCX':
      return Icons.description_outlined;
    case 'XLSX':
      return Icons.table_chart_outlined;
    case 'Video':
      return Icons.videocam_outlined;
    case 'Link':
      return Icons.link;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _addNews(BuildContext context, AppState app) async {
    final data = await showRecordForm(
      context,
      title: context.tr('إضافة خبر', 'Add news'),
      fields: const [
        FieldDef('title', 'العنوان', 'News title', required: true),
        FieldDef('content', 'المحتوى', 'News content',
            type: FieldType.multiline, required: true),
        FieldDef('date', 'التاريخ', 'Date', type: FieldType.date, required: true),
      ],
      initial: {'date': iso(today())},
    );
    if (data == null) return;
    app.add('news', data);
  }

  Widget _stats(BuildContext context, AppState app) {
    final cards = <Widget>[
      StatCard(
        label: context.tr('الفصول', 'Classes'),
        value: '${app.table('classes').length}',
        icon: Icons.class_outlined,
        color: const Color(0xFF3E7C3E),
        onTap: () => app.go('classes'),
      ),
      StatCard(
        label: context.tr('الطلاب', 'Students'),
        value: '${app.table('students').length}',
        icon: Icons.school_outlined,
        color: const Color(0xFF009EFB),
        onTap: () => app.go('students'),
      ),
      StatCard(
        label: context.tr('المعلمون', 'Teachers'),
        value: '${app.teacherCount}',
        icon: Icons.badge_outlined,
        color: const Color(0xFFEF8F00),
        onTap: () => app.go('teachers'),
      ),
      StatCard(
        label: context.tr('أولياء الأمور', 'Parents'),
        value: '${app.table('parents').length}',
        icon: Icons.family_restroom_outlined,
        color: const Color(0xFF7E57C2),
        onTap: () => app.go('students'),
      ),
      StatCard(
        label: context.tr('رسائل جديدة', 'New messages'),
        value: '${app.unreadMessages}',
        icon: Icons.mail_outline,
        color: const Color(0xFFD9534F),
        onTap: () => app.go('messages'),
      ),
    ];
    return LayoutBuilder(
      builder: (ctx, c) {
        final cols = c.maxWidth >= 700 ? 4 : 2;
        final itemWidth = (c.maxWidth - 12 * (cols - 1)) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards) SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }

  Widget _quickLinks(BuildContext context, AppState app) {
    final links = <(String, String, IconData, String)>[
      ('الحضور', 'Attendance', Icons.how_to_reg_outlined, 'attendance'),
      ('التقويم', 'Calendar', Icons.calendar_month_outlined, 'calender'),
      ('الرسائل', 'Messages', Icons.mail_outline, 'messages'),
      ('بريد / رسائل نصية', 'Mail / SMS', Icons.sms_outlined, 'mailsms'),
      ('كشف الدرجات', 'Marksheet', Icons.grading_outlined, 'marksheet'),
      ('الواجبات', 'Assignments', Icons.assignment_outlined, 'onlineAssignments'),
    ];
    return SectionCard(
      title: context.tr('روابط سريعة', 'Quick links'),
      icon: Icons.bolt_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final l in links)
            ActionChip(
              avatar: Icon(l.$3, size: 18),
              label: Text(context.tr(l.$1, l.$2)),
              onPressed: () => app.go(l.$4),
            ),
        ],
      ),
    );
  }

  Widget _payments(BuildContext context, AppState app) {
    final rows = app.table('payments');
    Color statusColor(String s) {
      if (s == 'Paid') return Colors.green;
      if (s == 'Overdue') return Colors.red;
      return Colors.orange;
    }

    String statusLabel(String s) {
      if (s == 'Paid') return context.tr('مدفوع', 'Paid');
      if (s == 'Overdue') return context.tr('متأخر', 'Overdue');
      return context.tr('قيد الانتظار', 'Pending');
    }

    return SectionCard(
      title: context.tr('المدفوعات', 'Payments'),
      icon: Icons.payments_outlined,
      child: rows.isEmpty
          ? EmptyState(message: context.tr('لا توجد بيانات', 'No Data Available'))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(context.tr('العنوان', 'Title'))),
                  DataColumn(label: Text(context.tr('الحالة', 'Status'))),
                  DataColumn(label: Text(context.tr('التاريخ', 'Date'))),
                  DataColumn(label: Text(context.tr('تاريخ الاستحقاق', 'Due Date'))),
                  DataColumn(label: Text(context.tr('المبلغ', 'Amount'))),
                ],
                rows: [
                  for (final p in rows)
                    DataRow(cells: [
                      DataCell(Text(p['title'])),
                      DataCell(StatusChip(
                        label: statusLabel(p['status']),
                        color: statusColor(p['status']),
                      )),
                      DataCell(Text(fmtDate(p['date']))),
                      DataCell(Text(fmtDate(p['due']))),
                      DataCell(Text('${p['amount']} ${context.tr('ر.س', 'SR')}')),
                    ]),
                ],
              ),
            ),
    );
  }

  Widget _news(BuildContext context, AppState app) {
    final news = <Rec>[...app.table('news')]
      ..sort((a, b) => b['date'].compareTo(a['date']));
    return SectionCard(
      title: context.tr('لوحة الأخبار', 'News board'),
      icon: Icons.campaign_outlined,
      trailing: IconButton(
        tooltip: context.tr('إضافة خبر', 'Add news'),
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => _addNews(context, app),
      ),
      child: news.isEmpty
          ? EmptyState(message: context.tr('لا توجد أخبار', 'No news'))
          : Column(
              children: [
                for (final n in news)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(n['title']),
                    subtitle: Text('${n['content']}\n${fmtDate(n['date'])}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await confirmDialog(
                          context,
                          context.tr('هل تريد حذف هذا الخبر؟', 'Delete this news item?'),
                        );
                        if (ok) app.remove('news', n.id);
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _resources(BuildContext context, AppState app) {
    final items = <Rec>[...app.table('materials')]
      ..sort((a, b) => b['date'].compareTo(a['date']));
    return SectionCard(
      title: context.tr('أحدث المواد التعليمية المشاركة', 'Recently shared learning resources'),
      icon: Icons.menu_book_outlined,
      trailing: TextButton(
        onPressed: () => app.go('materials'),
        child: Text(context.tr('عرض الكل', 'View all')),
      ),
      child: items.isEmpty
          ? EmptyState(message: context.tr('لا توجد بيانات', 'No Data Available'))
          : Column(
              children: [
                for (final m in items.take(5))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(_resourceIcon(m['fileType'])),
                    title: Text(m['title']),
                    subtitle: Text('${m['subject']} • ${fmtDate(m['date'])}'),
                    trailing: StatusChip(
                      label: m['fileType'],
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _calendarCard(BuildContext context, AppState app) {
    final now = today();
    final upcoming = app
        .calendarEvents()
        .where((e) => !e.date.isBefore(now))
        .take(6)
        .toList();
    return SectionCard(
      title: context.tr('التقويم', 'Calendar'),
      icon: Icons.calendar_month_outlined,
      trailing: TextButton(
        onPressed: () => app.go('calender'),
        child: Text(context.tr('فتح التقويم كاملاً', 'Open full calendar')),
      ),
      child: upcoming.isEmpty
          ? EmptyState(message: context.tr('لا توجد عناصر', 'No items'))
          : Column(
              children: [
                for (final e in upcoming)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: e.deadline ? kDeadlineColor : e.cat.color,
                      child: Text(
                        '${e.date.day}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    title: Text(e.title),
                    subtitle: Text(
                      '${fmtDate(iso(e.date))} • ${e.marker == 'end' ? context.tr('الموعد النهائي', 'Last deadline') : context.tr(e.cat.ar, e.cat.en)}',
                    ),
                    onTap: () => app.go(e.route),
                  ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          context.tr('لوحة التحكم', 'Dashboard'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF3E7C3E),
              ),
        ),
        const SizedBox(height: 12),
        _stats(context, app),
        const SizedBox(height: 12),
        _quickLinks(context, app),
        _payments(context, app),
        _news(context, app),
        const _PollCard(),
        _resources(context, app),
        _calendarCard(context, app),
      ],
    );
  }
}

class _PollCard extends StatefulWidget {
  const _PollCard();

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard> {
  int _selected = -1;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final total = app.pollVotes.fold<int>(0, (a, b) => a + b);
    return SectionCard(
      title: context.tr('استطلاع الرأي', 'Polls'),
      icon: Icons.poll_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            app.pollQuestion,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < app.pollOptions.length; i++)
            if (!app.hasVoted)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _selected == i
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(app.pollOptions[i]),
                onTap: () => setState(() => _selected = i),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(app.pollOptions[i]),
                        Text(
                          '${total == 0 ? 0 : (app.pollVotes[i] * 100 / total).round()}% (${app.pollVotes[i]})',
                        ),
                      ],
                    ),
                    LinearProgressIndicator(
                      value: total == 0 ? 0 : app.pollVotes[i] / total,
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          if (!app.hasVoted)
            FilledButton(
              onPressed: _selected < 0 ? null : () => app.vote(_selected),
              child: Text(context.tr('تصويت', 'Vote')),
            ),
          Text(
            '${context.tr('إجمالي الأصوات', 'Total votes')}: $total',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
