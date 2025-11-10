import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.onBack, required this.onSignOut});

  final VoidCallback onBack;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Почта не указана';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Назад',
                ),
                IconButton(
                  onPressed: onSignOut,
                  icon: const Icon(Icons.logout),
                  tooltip: 'Выйти',
                ),
              ],
            ),
            const SizedBox(height: 48),
            CircleAvatar(
              radius: 36,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                (email.isNotEmpty ? email[0] : '?').toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              email,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(Routes.signin, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Почта не указана';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Назад',
        ),
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    (email.isNotEmpty ? email[0] : '?').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  email,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
