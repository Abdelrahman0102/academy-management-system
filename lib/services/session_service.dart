// session_service.dart
import 'package:shared_preferences/shared_preferences.dart';

import '/repositories/auth_repository.dart';

/// Stores and restores the authenticated application session.
class SessionService {
  SessionService._();

  static const String _kUserId = 'session_user_id';
  static const String _kCoachId = 'session_coach_id';
  static const String _kRole = 'session_role';
  static const String _kToken = 'session_token';
  static const String _kFullName = 'session_full_name';

  static Future<void> save(AuthSession session) async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    /*
     * Remove stale values from a previous account before saving
     * the newly authenticated session.
     */
    await prefs.remove(_kCoachId);
    await prefs.remove(_kToken);
    await prefs.remove(_kFullName);

    await prefs.setInt(_kUserId, session.userId);
    await prefs.setString(
      _kRole,
      session.role.trim().toLowerCase(),
    );

    if (session.coachId != null) {
      await prefs.setInt(_kCoachId, session.coachId!);
    }

    final String token = session.token?.trim() ?? '';

    if (token.isEmpty) {
      throw StateError(
        'Cannot save an authenticated session without session_token.',
      );
    }

    await prefs.setString(_kToken, token);

    final String fullName =
        session.fullName?.trim() ?? '';

    if (fullName.isNotEmpty) {
      await prefs.setString(_kFullName, fullName);
    }
  }

  static Future<bool> isAdmin() async {
    return await currentRole() == 'admin';
  }

  static Future<String?> currentRole() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    return prefs.getString(_kRole);
  }

  static Future<int?> currentUserId() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    return prefs.getInt(_kUserId);
  }

  static Future<int?> currentCoachId() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    return prefs.getInt(_kCoachId);
  }

  static Future<String?> currentToken() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    final String? token = prefs.getString(_kToken);

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token.trim();
  }

  /// Headers used by every authenticated REST request.
  static Future<Map<String, String>> authHeaders() async {
    final String? token = await currentToken();

    if (token == null) {
      return <String, String>{};
    }

    return <String, String>{
      /*
       * X-Session-Token is preferred on shared hosting because
       * some Apache configurations remove Authorization headers.
       */
      'X-Session-Token': token,

      /*
       * Also send Bearer for compatibility with servers where
       * Authorization is available.
       */
      'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> hasAuthenticatedSession() async {
    final int? userId = await currentUserId();
    final String? role = await currentRole();
    final String? token = await currentToken();

    return userId != null &&
        userId > 0 &&
        <String>['admin', 'coach'].contains(role) &&
        token != null;
  }

  static Future<void> clear() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    await prefs.remove(_kUserId);
    await prefs.remove(_kCoachId);
    await prefs.remove(_kRole);
    await prefs.remove(_kToken);
    await prefs.remove(_kFullName);
  }
}
