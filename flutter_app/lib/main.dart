import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes.dart';
import 'splash_page.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/recipe_search/recipe_search_screen.dart';
import 'screens/profile/profile_screen.dart';

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
      title: 'AI-Holodilnik',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4D3E), // Темно-зеленый из логотипа
          brightness: Brightness.light,
          primary: const Color(0xFF1B4D3E),
          secondary: const Color(0xFF2A6B54),
          surface: const Color(0xFFF5E6D3), // Бежевый из логотипа
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF3E9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B4D3E),
          foregroundColor: Color(0xFFF5E6D3),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFBF5),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B4D3E),
            foregroundColor: const Color(0xFFF5E6D3),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1B4D3E)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1B4D3E), width: 2),
          ),
        ),
      ),
      routes: {
        Routes.splash: (_) => const SplashPage(),
        Routes.signin: (_) => const SignInScreen(),
        Routes.signup: (_) => const SignUpScreen(),
        Routes.recipeSearch: (_) => const RecipeSearchScreen(),
        Routes.profile: (_) => const ProfileScreen(),
      },
      initialRoute: Routes.splash,
    );
  }
}
