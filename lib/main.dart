
import 'package:flutter/material.dart';
import 'screens/splash.dart';
import 'screens/dashboard.dart';
import 'screens/analysis.dart';
import 'screens/guide.dart';
import 'screens/history.dart';
import 'screens/reports.dart';
import 'screens/quiz.dart';
import 'screens/kids.dart';
import 'screens/settings.dart';

void main() {
  runApp(const AquaApp());
}

class AquaApp extends StatelessWidget {
  const AquaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3DD6EE),
        secondary: Color(0xFF6FE3FF),
      ),
      useMaterial3: true,
      fontFamily: 'Roboto',
    );

    return MaterialApp(
      title: "Aqua Insights",
      debugShowCheckedModeBanner: false,
      theme: theme,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/analysis': (_) => const AnalysisScreen(),
        '/guide': (_) => const GuideScreen(),
        '/history': (_) => const HistoryScreen(),
        '/reports': (_) => CommunityReportsScreen(),
        '/quiz': (_) => const QuizScreen(),
        '/kids': (_) => KidsCornerScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
