import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/welcome/presentation/screens/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: EnglishTutorApp(),
    ),
  );
}

class EnglishTutorApp extends StatelessWidget {
  const EnglishTutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI English Tutor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const WelcomeScreen(),
    );
  }
}
