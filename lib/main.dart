import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

import 'l10n/app_localizations.dart';
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
import 'screens/login/login_screen.dart';
import 'screens/coaches/coaches_screen.dart';
import 'screens/groups/groups_screen.dart';
import 'repositories/coach_repository.dart';
import 'repositories/group_repository.dart';
import 'repositories/attendance_repository.dart';
import 'screens/attendance/attendance_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'repositories/user_settings_repository.dart';
import 'repositories/parent_account_request_repository.dart';
import 'screens/parent_account_requests_screen.dart';
import 'services/session_service.dart';
import 'settings/app_settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const CoachApp());
}

class CoachApp extends StatelessWidget {
  const CoachApp({super.key});

  static const String _baseUrl =
      'https://turbo-app.com/api/sports_academy';

  static final UserSettingsRepository _settingsRepository =
  UserSettingsRepository(
    baseUrl: _baseUrl,
    headersProvider: SessionService.authHeaders,
  );

  static final AppSettingsController _settingsController =
  AppSettingsController(
    repository: _settingsRepository,
  );

  static final PlayerRepository _playerRepository =
  PlayerRepository(
    baseUrl: _baseUrl,
    headersProvider: SessionService.authHeaders,
  );

  static final AttendanceRepository _attendanceRepository =
  AttendanceRepository(
    client: http.Client(),
    baseUrl: _baseUrl,
    playerRepository: _playerRepository,
  );

  static final CoachRepository _coachRepository =
  CoachRepository(
    baseUrl: _baseUrl,
    headersProvider: SessionService.authHeaders,
  );

  static final GroupRepository _groupRepository =
  GroupRepository(
    baseUrl: _baseUrl,
    headersProvider: SessionService.authHeaders,
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settingsController,
      builder: (
          BuildContext context,
          Widget? child,
          ) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppLightTheme.theme,
          darkTheme: AppDarkTheme.theme,
          themeMode: _settingsController.themeMode,
          locale: _settingsController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates:
          const <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/splash',
          routes: <String, WidgetBuilder>{
            '/parent-account-requests': (BuildContext context) {
              return ParentAccountRequestsScreen(
                repository: ParentAccountRequestRepository(
                  baseUrl: _baseUrl,
                  headersProvider: SessionService.authHeaders,
                ),
              );
            },
            '/home': (BuildContext context) => const HomeScreen(),
            '/players': (BuildContext context) => PlayersScreen(
              repository: _playerRepository,
            ),
            '/playsers/create': (BuildContext context) => AddPlayerScreen(
              repository: _playerRepository,
            ),
            '/attendance': (BuildContext context) => AttendanceScreen(
              repository: _attendanceRepository,
            ),
            '/settings': (BuildContext context) {
              return SettingsScreen(
                controller: _settingsController,
              );
            },
            '/splash': (BuildContext context) {
              return SplashScreen(
                settingsController: _settingsController,
              );
            },
            '/login': (BuildContext context) {
              return LoginScreen(
                role: '',
                settingsController: _settingsController,
              );
            },
            '/coaches': (BuildContext context) {
              return CoachesScreen(
                repository: _coachRepository,
              );
            },
            '/groups': (BuildContext context) {
              return GroupsScreen(
                repository: _groupRepository,
                coachRepository: _coachRepository,
              );
            },
            '/evaluations': (BuildContext context) =>
                PlayerEvaluationScreen(
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
                  builder: (BuildContext context) =>
                      PlayerDetailsScreen(
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
                  builder: (BuildContext context) =>
                      EditPlayerScreen(
                        player: arguments,
                        repository: _playerRepository,
                      ),
                );

              default:
                return _errorRoute('Page not found.');
            }
          },
        );
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
