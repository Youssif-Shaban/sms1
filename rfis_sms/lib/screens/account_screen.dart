import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../util.dart';
import '../widgets/common.dart';

/// Account settings: profile data, e-mail, password and language.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: context.tr('البيانات الشخصية', 'Profile')),
              Tab(text: context.tr('البريد الإلكتروني', 'E-mail')),
              Tab(text: context.tr('كلمة المرور', 'Password')),
              Tab(text: context.tr('اللغة', 'Language')),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [_ProfileTab(), _EmailTab(), _PasswordTab(), _LanguageTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _address;
  String _gender = 'Male';
  String _birthday = '';

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    _name = TextEditingController(text: app.profile['name'] ?? '');
    _mobile = TextEditingController(text: app.profile['mobile'] ?? '');
    _address = TextEditingController(text: app.profile['address'] ?? '');
    _gender = app.profile['gender'] ?? 'Male';
    _birthday = app.profile['birthday'] ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final required = context.tr('هذا الحقل مطلوب', 'This field is required');
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 44)),
                TextButton(
                  onPressed: () => snack(
                    context,
                    context.tr('تغيير الصورة (محاكاة)', 'Change photo (simulated)'),
                  ),
                  child: Text(context.tr('تغيير الصورة', 'Photo')),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: _name,
            decoration: InputDecoration(labelText: '${context.tr('الاسم الكامل', 'Full name')} *'),
            validator: (v) => (v == null || v.trim().isEmpty) ? required : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: InputDecoration(labelText: context.tr('الجنس', 'Gender')),
            items: [
              DropdownMenuItem<String>(value: 'Male', child: Text(context.tr('ذكر', 'Male'))),
              DropdownMenuItem<String>(value: 'Female', child: Text(context.tr('أنثى', 'Female'))),
            ],
            onChanged: (v) => setState(() => _gender = v ?? 'Male'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await pickDate(context, _birthday);
              if (picked != null) setState(() => _birthday = picked);
            },
            icon: const Icon(Icons.cake_outlined),
            label: Text(
              '${context.tr('تاريخ الميلاد', 'Birthday')}: ${_birthday.isEmpty ? '-' : fmtDate(_birthday)}',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: context.tr('رقم الجوال', 'Mobile No')),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            decoration: InputDecoration(labelText: context.tr('العنوان', 'Address')),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              app.profile['name'] = _name.text.trim();
              app.profile['gender'] = _gender;
              app.profile['birthday'] = _birthday;
              app.profile['mobile'] = _mobile.text.trim();
              app.profile['address'] = _address.text.trim();
              app.touch();
              snack(context, context.tr('تم تحديث البيانات', 'Profile updated successfully'));
            },
            icon: const Icon(Icons.save_outlined),
            label: Text(context.tr('تعديل البيانات', 'Edit profile')),
          ),
        ],
      ),
    );
  }
}

class _EmailTab extends StatefulWidget {
  const _EmailTab();

  @override
  State<_EmailTab> createState() => _EmailTabState();
}

class _EmailTabState extends State<_EmailTab> {
  final _newEmail = TextEditingController();
  final _retype = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _newEmail.dispose();
    _retype.dispose();
    super.dispose();
  }

  void _save(AppState app) {
    final email = _newEmail.text.trim();
    String? error;
    if (email.isEmpty || !email.contains('@')) {
      error = context.tr('عنوان بريد إلكتروني غير صحيح', 'Invalid e-mail address');
    } else if (email != _retype.text.trim()) {
      error = context.tr('عنوانا البريد غير متطابقين', 'The e-mail addresses do not match');
    } else if (app.table('employees').any((e) => e['email'] == email) &&
        email != app.profile['email']) {
      error = context.tr('البريد مستخدم مسبقاً', 'E-mail address already used');
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    app.profile['email'] = email;
    app.touch();
    setState(() {
      _error = null;
      _newEmail.clear();
      _retype.clear();
    });
    snack(context, context.tr('تم تغيير البريد الإلكتروني', 'E-mail address changed'));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.email_outlined),
          title: Text(context.tr('البريد الحالي', 'Current e-mail')),
          subtitle: Text(app.profile['email'] ?? ''),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _newEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: context.tr('البريد الجديد', 'New e-mail address')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _retype,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: context.tr('أعد كتابة البريد', 'Retype Email address')),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => _save(app),
          child: Text(context.tr('تغيير البريد الإلكتروني', 'Change e-mail address')),
        ),
      ],
    );
  }
}

class _PasswordTab extends StatefulWidget {
  const _PasswordTab();

  @override
  State<_PasswordTab> createState() => _PasswordTabState();
}

class _PasswordTabState extends State<_PasswordTab> {
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _retype = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _retype.dispose();
    super.dispose();
  }

  Future<void> _save(AppState app) async {
    String? error;
    if (_old.text != app.password) {
      error = context.tr('كلمة المرور القديمة غير مطابقة', "Old password don't match stored one");
    } else if (_new.text.length < 6) {
      error = context.tr('كلمة المرور الجديدة 6 أحرف على الأقل', 'New password must have at least 6 characters');
    } else if (_new.text != _retype.text) {
      error = context.tr('كلمتا المرور غير متطابقتين', 'The new passwords do not match');
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    app.password = _new.text;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Text(ctx.tr(
          'تم تغيير كلمة المرور بنجاح، اضغط دخول للمتابعة',
          'Password changed successfully, press login to continue',
        )),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr('دخول', 'Login')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    app.logout();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _old,
          obscureText: _obscure,
          decoration: deco(context.tr('كلمة المرور القديمة', 'Old password')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _new,
          obscureText: _obscure,
          decoration: deco(context.tr('كلمة المرور الجديدة', 'New password')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _retype,
          obscureText: _obscure,
          decoration: deco(context.tr('أعد كتابة كلمة المرور', 'Retype New password')),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => _save(app),
          child: Text(context.tr('تغيير كلمة المرور', 'Change password')),
        ),
      ],
    );
  }
}

class _LanguageTab extends StatelessWidget {
  const _LanguageTab();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          context.tr('اللغة الافتراضية', 'Default language'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            title: const Text('العربية'),
            trailing: app.isArabic ? const Icon(Icons.check_circle, color: Colors.green) : null,
            onTap: () => app.setLanguage(true),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('English'),
            trailing: app.isArabic ? null : const Icon(Icons.check_circle, color: Colors.green),
            onTap: () => app.setLanguage(false),
          ),
        ),
      ],
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      (
        'الاستخدام المقبول',
        'This simulation is for demonstration only. Use it with sample data only.'
      ),
      (
        'الخصوصية',
        'No real student, parent or staff data is stored or sent anywhere by this app.'
      ),
      (
        'المحاكاة',
        'All screens work on in-memory data that resets when the app restarts.'
      ),
    ];
    final titlesEn = <String>['Acceptable use', 'Privacy', 'Simulation'];
    final bodiesAr = <String>[
      'هذه المحاكاة للعرض فقط. استخدمها ببيانات تجريبية فقط.',
      'لا يخزّن هذا التطبيق ولا يرسل أي بيانات حقيقية للطلاب أو أولياء الأمور أو الموظفين.',
      'تعمل جميع الشاشات على بيانات في الذاكرة تُعاد عند إعادة تشغيل التطبيق.',
    ];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (var i = 0; i < items.length; i++)
          SectionCard(
            title: context.tr(items[i].$1, titlesEn[i]),
            icon: Icons.gavel_outlined,
            child: Text(context.tr(bodiesAr[i], items[i].$2)),
          ),
      ],
    );
  }
}
