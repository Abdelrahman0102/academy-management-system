// Entry point

import 'package:flutter/material.dart';

import 'models/player.dart';
import 'repositories/player_repository.dart';

import 'themes/light_theme.dart';
import 'themes/dark_theme.dart';

import 'screens/home/home_screen.dart';
import 'screens/players/players_screen.dart';
import 'screens/players/add_player_screen.dart';
import 'screens/players/edit_player_screen.dart';
import 'screens/players/player_details_screen.dart';
import 'screens/evaluations/player_evaluation_screen.dart';
import 'screens/splash/splash_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/coaches/coaches_screen.dart';
import '../repositories/coach_repository.dart';
//import '/add_coach_screen.dart';

void main() {
  runApp(const CoachApp());
}

class CoachApp extends StatelessWidget {
  const CoachApp({super.key});

  static final PlayerRepository _playerRepository = PlayerRepository(
    // غيّر الرابط إلى رابط الـ API الحقيقي.
    baseUrl: 'https://turbo-app.com/api/sports_academy',

    // JWT ملغي حاليًا، لذلك لا نرسل Authorization header.
    headersProvider: () async => const <String, String>{},
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: AppLightTheme.theme,
      darkTheme: AppDarkTheme.theme,
      themeMode: ThemeMode.system,

      initialRoute: '/splash',

      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => const HomeScreen(),

        '/players': (BuildContext context) => PlayersScreen(
          repository: _playerRepository,
        ),


        '/players/create': (BuildContext context) => AddPlayerScreen(
          repository: _playerRepository,
        ),
        '/splash': (context) => const SplashScreen(),

        '/login': (context) => const LoginScreen(role: '',),

        '/coaches': (context) => CoachesScreen(
          repository: CoachRepository(
            baseUrl: 'https://turbo-app.com/api/sports_academy',
            headersProvider: () async => const <String, String>{},
          ),
        ),

        // '/coaches/add': (context) => AddCoachScreen(
        //   repository: _coachRepository,
        // ),
        '/evaluations': (BuildContext context) => PlayerEvaluationScreen(
          repository: _playerRepository,
        ),

      },


      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/players/details':
            final Object? arguments = settings.arguments;

            if (arguments is! PlayerModel) {
              return _errorRoute(
                'Player data is required to open player details.',
              );
            }

            return MaterialPageRoute<void>(
              settings: settings,
              builder: (BuildContext context) => PlayerDetailsScreen(
                player: arguments,
                repository: _playerRepository,
              ),
            );

          case '/players/edit':
            final Object? arguments = settings.arguments;

            if (arguments is! PlayerModel) {
              return _errorRoute(
                'Player data is required to edit the player.',
              );
            }

            return MaterialPageRoute<void>(
              settings: settings,
              builder: (BuildContext context) => EditPlayerScreen(
                player: arguments,
                repository: _playerRepository,
              ),
            );

          default:
            return _errorRoute('Page not found.');
        }
      },
    );
  }

  static Route<void> _errorRoute(String message) {
    return MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Error'),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}