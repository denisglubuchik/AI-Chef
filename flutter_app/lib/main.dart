import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes.dart';
import 'splash_page.dart';
import 'auth/sign_in_page.dart';
import 'auth/sign_up_page.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final url = dotenv.env['SUPABASE_URL'] ?? '';
  final anon = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  await Supabase.initialize(url: url, anonKey: anon);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Chef',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {
        Routes.splash: (_) => const SplashPage(),
        Routes.signin: (_) => const SignInPage(),
        Routes.signup: (_) => const SignUpPage(),
        Routes.home: (_) => const HomePage(),
      },
      initialRoute: Routes.splash,
    );
  }
}
