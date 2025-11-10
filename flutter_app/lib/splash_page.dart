import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final hasSession = Supabase.instance.client.auth.currentSession != null;
    Navigator.of(context).pushNamedAndRemoveUntil(
      hasSession ? Routes.recipeSearch : Routes.signin,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
