// Entry point

import 'package:flutter/material.dart';
import 'themes/light_theme.dart';
import 'themes/dark_theme.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const CoachApp());
}

class CoachApp extends StatelessWidget {
  const CoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppLightTheme.theme,
      darkTheme: AppDarkTheme.theme,
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(
          child: HomeScreen(),
        ),
      ),
    );
  }
}
