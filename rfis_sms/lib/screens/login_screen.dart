import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _user = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  bool _remember = true;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    final app = context.app;
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = context.tr(
            'يجب إدخال اسم المستخدم وكلمة المرور',
            'You must type username and password',
          ));
      return;
    }
    if (!app.login(_user.text, _pass.text)) {
      setState(() => _error = context.tr(
            'يرجى التحقق من اسم المستخدم وكلمة المرور',
            'Please check your username & password',
          ));
    }
  }

  Future<void> _forgot() async {
    final controller = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(ctx.tr('استعادة كلمة المرور', 'Restore password')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: ctx.tr('اسم المستخدم أو البريد الإلكتروني', 'Username / e-mail'),
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('إلغاء', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  setLocal(() => error = ctx.tr(
                        'يجب إدخال اسم المستخدم أو البريد',
                        'You must type username / e-mail',
                      ));
                  return;
                }
                Navigator.pop(ctx);
                snack(
                  context,
                  context.tr(
                    'يرجى التحقق من بريدك الإلكتروني لرابط الاستعادة (محاكاة)',
                    'Please check your e-mail for restore link (simulated)',
                  ),
                );
              },
              child: Text(ctx.tr('إرسال', 'Send')),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton.icon(
            onPressed: () => app.setLanguage(!app.isArabic),
            icon: const Icon(Icons.translate, color: Colors.white),
            label: Text(
              context.tr('English', 'العربية'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.school, size: 56, color: scheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      'RFIS',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      context.tr('تسجيل الدخول', 'Sign in'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr(
                          'وضع المحاكاة: لا اتصال بالنظام الحقيقي. استخدم demo / demo123',
                          'Simulation mode: no connection to the real system. Use demo / demo123',
                        ),
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _user,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: context.tr('اسم المستخدم', 'Username'),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pass,
                      obscureText: _obscure,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: context.tr('كلمة المرور', 'Password'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: scheme.error)),
                    ],
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _remember,
                      onChanged: (v) => setState(() => _remember = v ?? false),
                      title: Text(context.tr('تذكرني', 'Remember me')),
                    ),
                    FilledButton(
                      onPressed: _submit,
                      child: Text(context.tr('دخول', 'Login')),
                    ),
                    TextButton(
                      onPressed: _forgot,
                      child: Text(context.tr('نسيت كلمة المرور؟', 'Forgot password?')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
