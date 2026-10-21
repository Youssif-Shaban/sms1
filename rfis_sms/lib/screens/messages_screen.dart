import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';

/// Inbox / Sent with read-state, reply, compose and delete.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  List<Rec> _folder(AppState app, String folder) {
    final rows =
        app.table('messages').where((m) => m['folder'] == folder).toList();
    rows.sort((a, b) =>
        '${b['date']} ${b['time']}'.compareTo('${a['date']} ${a['time']}'));
    return rows;
  }

  Widget _list(BuildContext context, AppState app, List<Rec> rows, bool inbox) {
    if (rows.isEmpty) {
      return EmptyState(message: context.tr('لا توجد رسائل', 'No messages'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: rows.length,
      itemBuilder: (ctx, i) {
        final m = rows[i];
        final unread = inbox && m['read'] == '0';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(unread ? Icons.mark_email_unread_outlined : Icons.mail_outline),
            ),
            title: Text(
              m['subject'],
              style: TextStyle(
                fontWeight: unread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              '${inbox ? m['from'] : m['to']} • ${fmtDate(m['date'])} ${m['time']}',
            ),
            trailing: unread
                ? const Icon(Icons.circle, size: 10, color: Colors.red)
                : null,
            onTap: () {
              app.markRead(m.id);
              Navigator.of(ctx).push(MaterialPageRoute<void>(
                builder: (_) => MessageDetailScreen(messageId: m.id),
              ));
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final inbox = _folder(app, 'inbox');
    final sent = _folder(app, 'sent');
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const ComposeMessageScreen(),
            ));
          },
          icon: const Icon(Icons.edit_outlined),
          label: Text(context.tr('رسالة جديدة', 'Compose')),
        ),
        body: Column(
          children: [
            TabBar(
              tabs: [
                Tab(
                  text: '${context.tr('الوارد', 'Inbox')} (${inbox.length}) • ${app.unreadMessages} ${context.tr('جديدة', 'new')}',
                ),
                Tab(text: '${context.tr('المرسلة', 'Sent')} (${sent.length})'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _list(context, app, inbox, true),
                  _list(context, app, sent, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageDetailScreen extends StatelessWidget {
  const MessageDetailScreen({super.key, required this.messageId});

  final String messageId;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final m = app.find('messages', messageId);
    if (m == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('الرسالة', 'Message'))),
        body: EmptyState(message: context.tr('الرسالة غير موجودة', 'Message not found')),
      );
    }
    final isInbox = m['folder'] == 'inbox';
    return Scaffold(
      appBar: AppBar(
        title: Text(m['subject']),
        actions: [
          IconButton(
            tooltip: context.tr('رد', 'Reply'),
            icon: const Icon(Icons.reply),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ComposeMessageScreen(
                  to: isInbox ? m['from'] : m['to'],
                  subject: m['subject'].startsWith('Re:')
                      ? m['subject']
                      : 'Re: ${m['subject']}',
                ),
              ));
            },
          ),
          IconButton(
            tooltip: context.tr('حذف', 'Delete'),
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                context.tr('هل تريد حذف هذه الرسالة؟', 'Delete this message?'),
              );
              if (!ok || !context.mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              app.remove('messages', m.id);
              Navigator.of(context).pop();
              messenger.showSnackBar(
                SnackBar(content: Text(context.tr('تم حذف الرسالة', 'Message deleted'))),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            m['subject'],
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('${context.tr('من', 'From')}: ${m['from']}'),
          Text('${context.tr('إلى', 'To')}: ${m['to']}'),
          Text('${context.tr('التاريخ', 'Date')}: ${fmtDate(m['date'])} ${m['time']}'),
          const Divider(height: 24),
          SelectableText(m['body']),
        ],
      ),
    );
  }
}

class ComposeMessageScreen extends StatefulWidget {
  const ComposeMessageScreen({super.key, this.to = '', this.subject = ''});

  final String to;
  final String subject;

  @override
  State<ComposeMessageScreen> createState() => _ComposeMessageScreenState();
}

class _ComposeMessageScreenState extends State<ComposeMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subject;
  final TextEditingController _body = TextEditingController();
  String _to = '';

  @override
  void initState() {
    super.initState();
    _to = widget.to;
    _subject = TextEditingController(text: widget.subject);
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  void _send() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final app = context.app;
    final messenger = ScaffoldMessenger.of(context);
    final sentText = context.tr('تم إرسال الرسالة', 'Message sent');
    app.add('messages', {
      'from': app.profile['name'] ?? '',
      'to': _to,
      'subject': _subject.text.trim(),
      'body': _body.text.trim(),
      'date': iso(today()),
      'time': nowTime(),
      'folder': 'sent',
      'read': '1',
    });
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(sentText)));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final names = app.recipientNames();
    if (_to.isNotEmpty && !names.contains(_to)) names.add(_to);
    final required = context.tr('هذا الحقل مطلوب', 'This field is required');
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('رسالة جديدة', 'New message'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: names.contains(_to) ? _to : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: '${context.tr('إلى', 'To')} *'),
              items: [
                for (final n in names)
                  DropdownMenuItem<String>(value: n, child: Text(n)),
              ],
              onChanged: (v) => setState(() => _to = v ?? ''),
              validator: (v) => (v == null || v.isEmpty) ? required : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subject,
              decoration: InputDecoration(
                labelText: '${context.tr('عنوان الرسالة', 'Message title')} *',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? required : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              minLines: 6,
              maxLines: 12,
              decoration: InputDecoration(
                labelText: '${context.tr('محتوى الرسالة', 'Message content')} *',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? required : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _send,
              icon: const Icon(Icons.send),
              label: Text(context.tr('إرسال', 'Send')),
            ),
          ],
        ),
      ),
    );
  }
}
