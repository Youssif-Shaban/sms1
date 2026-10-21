import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';

String _typeLabel(BuildContext context, String raw) {
  switch (raw.toLowerCase()) {
    case 'mail':
      return context.tr('بريد إلكتروني', 'Mail');
    case 'sms':
      return context.tr('رسالة نصية', 'SMS');
    default:
      return context.tr('بريد + رسالة نصية', 'Mail + SMS');
  }
}

String _audienceLabel(BuildContext context, String raw) {
  switch (raw) {
    case 'students':
      return context.tr('الطلاب', 'Students');
    case 'teachers':
      return context.tr('المعلمون', 'Teachers');
    case 'parents':
      return context.tr('أولياء الأمور', 'Parents');
    default:
      return context.tr('الجميع', 'Everyone');
  }
}

/// Send Mail / SMS, list sent items, and edit the sender settings.
class MailSmsScreen extends StatelessWidget {
  const MailSmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: context.tr('إرسال', 'Send')),
                Tab(text: context.tr('المرسلة', 'Sent')),
                Tab(text: context.tr('الإعدادات', 'Settings')),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [_SendTab(), _SentTab(), _SettingsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendTab extends StatefulWidget {
  const _SendTab();

  @override
  State<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends State<_SendTab>
    with AutomaticKeepAliveClientMixin {
  String _type = 'mail';
  String _audience = 'parents';
  String _class = '';
  String _templateId = '';
  final TextEditingController _title = TextEditingController();
  final TextEditingController _content = TextEditingController();
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  List<Rec> _students(AppState app) =>
      _class.isEmpty ? app.table('students') : app.studentsOfClass(_class);

  int _recipients(AppState app) {
    final students = _students(app);
    final studentCount = students.length;
    final teacherCount = app.teacherCount;
    final parentCount =
        students.map((s) => s['parent']).where((p) => p.isNotEmpty).toSet().length;
    switch (_audience) {
      case 'students':
        return studentCount;
      case 'teachers':
        return teacherCount;
      case 'parents':
        return parentCount;
      default:
        return studentCount + teacherCount + parentCount;
    }
  }

  List<Rec> _templates(AppState app) {
    return app.table('templates').where((t) {
      if (_type == 'both') return true;
      return t['type'].toLowerCase() == _type;
    }).toList();
  }

  void _applyTemplate(AppState app, String id) {
    final t = app.find('templates', id);
    setState(() {
      _templateId = id;
      if (t != null) {
        _title.text = t['title'];
        _content.text = t['content'];
      }
    });
  }

  Map<String, String> _sampleVars(BuildContext context, AppState app) {
    return {
      'student': context.tr('اسم الطالب', 'Student Name'),
      'class': _class.isEmpty ? context.tr('الفصل', 'Class') : _class,
      'date': fmtDate(iso(today())),
      'school': app.mailSettings['senderName'] ?? 'RFIS',
    };
  }

  void _send(AppState app) {
    final recipients = _recipients(app);
    final needsTitle = _type != 'sms';
    String? error;
    if (needsTitle && _title.text.trim().isEmpty) {
      error = context.tr('يجب إدخال عنوان الرسالة', 'You must type the message title');
    } else if (_content.text.trim().isEmpty) {
      error = context.tr('يجب إدخال محتوى الرسالة', 'You must type the message content');
    } else if (recipients == 0) {
      error = context.tr('لا يوجد مستلمون لهذا الاختيار', 'There are no recipients for this selection');
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final segments = _type == 'mail' ? 0 : smsSegments(_content.text);
    app.add('sentMail', {
      'type': _type,
      'audience': _audience,
      'class': _class,
      'title': _title.text.trim().isEmpty ? '-' : _title.text.trim(),
      'content': _content.text.trim(),
      'date': iso(today()),
      'time': nowTime(),
      'recipients': '$recipients',
      'segments': '$segments',
    });
    setState(() {
      _error = null;
      _title.clear();
      _content.clear();
      _templateId = '';
    });
    snack(
      context,
      context.tr('تم الإرسال إلى $recipients مستلم (محاكاة)', 'Sent to $recipients recipients (simulated)'),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final app = context.app;
    final scheme = Theme.of(context).colorScheme;
    final templates = _templates(app);
    final recipients = _recipients(app);
    final classes = app.table('classes').map((c) => c['name']).toList();
    final segments = smsSegments(_content.text);
    final vars = _sampleVars(context, app);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.tr('نوع الرسالة', 'Send as'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final t in const ['mail', 'sms', 'both'])
              ChoiceChip(
                label: Text(_typeLabel(context, t)),
                selected: _type == t,
                onSelected: (_) => setState(() {
                  _type = t;
                  _templateId = '';
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(context.tr('المستلمون', 'Select users'),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final a in const ['students', 'teachers', 'parents', 'all'])
              ChoiceChip(
                label: Text(_audienceLabel(context, a)),
                selected: _audience == a,
                onSelected: (_) => setState(() => _audience = a),
              ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _class,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.tr('الفصل', 'Class')),
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
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: templates.any((t) => t.id == _templateId) ? _templateId : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: context.tr('القالب', 'Template')),
          items: [
            for (final t in templates)
              DropdownMenuItem<String>(
                value: t.id,
                child: Text('${t['title']} (${t['type']})'),
              ),
          ],
          onChanged: (v) {
            if (v != null) _applyTemplate(app, v);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _title,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: _type == 'sms'
                ? context.tr('العنوان (اختياري)', 'Title (optional)')
                : '${context.tr('عنوان الرسالة', 'Message title')} *',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _content,
          onChanged: (_) => setState(() {}),
          minLines: 4,
          maxLines: 8,
          decoration: InputDecoration(
            labelText: '${context.tr('محتوى الرسالة', 'Message content')} *',
            alignLabelWithHint: true,
            helperText: context.tr(
              'المتغيرات: {student} {class} {date} {school}',
              'Variables: {student} {class} {date} {school}',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: scheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('معاينة', 'Preview'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _content.text.isEmpty
                      ? '-'
                      : applyVars(_content.text, vars),
                ),
                const Divider(),
                Text(
                  '${context.tr('عدد المستلمين', 'Recipients')}: $recipients',
                ),
                if (_type != 'mail')
                  Text(
                    '${context.tr('أجزاء الرسالة النصية', 'SMS segments')}: $segments × $recipients = ${segments * recipients}',
                  ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: scheme.error)),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _send(app),
          icon: const Icon(Icons.send),
          label: Text(context.tr('إرسال', 'Send')),
        ),
      ],
    );
  }
}

class _SentTab extends StatelessWidget {
  const _SentTab();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final rows = <Rec>[...app.table('sentMail')]..sort((a, b) =>
        '${b['date']} ${b['time']}'.compareTo('${a['date']} ${a['time']}'));
    if (rows.isEmpty) {
      return EmptyState(message: context.tr('لا توجد رسائل مرسلة', 'No messages'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: rows.length,
      itemBuilder: (ctx, i) {
        final r = rows[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(r['type'].toLowerCase() == 'mail'
                  ? Icons.email_outlined
                  : Icons.sms_outlined),
            ),
            title: Text(r['title']),
            subtitle: Text(
              '${_typeLabel(ctx, r['type'])} • ${_audienceLabel(ctx, r['audience'])}'
              '${r['class'].isEmpty ? '' : ' • ${r['class']}'}'
              ' • ${r['recipients']} ${ctx.tr('مستلم', 'recipients')}',
            ),
            trailing: Text(fmtDate(r['date'])),
            onTap: () => showDialog<void>(
              context: ctx,
              builder: (dctx) => AlertDialog(
                title: Text(r['title']),
                content: SingleChildScrollView(
                  child: Text(
                    '${r['content']}\n\n${fmtDate(r['date'])} ${r['time']}',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dctx);
                      app.remove('sentMail', r.id);
                    },
                    child: Text(dctx.tr('حذف', 'Delete')),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dctx),
                    child: Text(dctx.tr('إغلاق', 'Close')),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late final TextEditingController _sender;
  String _mailDelivery = 'smtp';
  String _smsProvider = 'provider_a';

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    _sender = TextEditingController(text: app.mailSettings['senderName'] ?? '');
    _mailDelivery = app.mailSettings['mailDelivery'] ?? 'smtp';
    _smsProvider = app.mailSettings['smsProvider'] ?? 'provider_a';
  }

  @override
  void dispose() {
    _sender.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _sender,
          decoration: InputDecoration(labelText: context.tr('اسم المرسل', 'Sender')),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _mailDelivery,
          decoration: InputDecoration(
            labelText: context.tr('طريقة إرسال البريد', 'Mail delivery type'),
          ),
          items: const [
            DropdownMenuItem<String>(value: 'smtp', child: Text('SMTP')),
            DropdownMenuItem<String>(value: 'php', child: Text('PHP mail')),
          ],
          onChanged: (v) => setState(() => _mailDelivery = v ?? 'smtp'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _smsProvider,
          decoration: InputDecoration(
            labelText: context.tr('مزود الرسائل النصية', 'SMS provider'),
          ),
          items: [
            const DropdownMenuItem<String>(value: 'provider_a', child: Text('Provider A')),
            const DropdownMenuItem<String>(value: 'provider_b', child: Text('Provider B')),
            DropdownMenuItem<String>(
              value: 'none',
              child: Text(context.tr('بدون', 'None')),
            ),
          ],
          onChanged: (v) => setState(() => _smsProvider = v ?? 'provider_a'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            app.mailSettings['senderName'] = _sender.text.trim();
            app.mailSettings['mailDelivery'] = _mailDelivery;
            app.mailSettings['smsProvider'] = _smsProvider;
            app.touch();
            snack(context, context.tr('تم حفظ الإعدادات', 'Settings saved'));
          },
          icon: const Icon(Icons.save_outlined),
          label: Text(context.tr('حفظ الإعدادات', 'Save settings')),
        ),
      ],
    );
  }
}
