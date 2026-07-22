// Entry point

import 'package:flutter/material.dart';
import 'themes/light_theme.dart';
import 'themes/dark_theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/players/players_screen.dart';
import 'screens/players/add_player_screen.dart';
import 'screens/players/edit_player_screen.dart';
import 'screens/players/player_details_screen.dart';

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

      initialRoute: '/home',

      routes: {
        '/home': (context) => const HomeScreen(),

        '/players': (context) => const PlayersScreen(),

        '/players/create': (context) => const AddPlayerScreen(),

        '/players/edit': (context) => const EditPlayerScreen(),

        '/players/details': (context) => const PlayerDetailsScreen(),
      },
    );
  }
}
