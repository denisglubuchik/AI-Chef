import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _signUp() async {
    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;

      final needsConfirm = res.session == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            needsConfirm
                ? 'Проверьте почту для подтверждения.'
                : 'Регистрация успешна.',
          ),
        ),
      );

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(Routes.signin, (r) => false);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ошибка регистрации')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Пароль'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _signUp,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Создать аккаунт'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Уже есть аккаунт? Войти'),
            ),
          ],
        ),
      ),
    );
  }
}
