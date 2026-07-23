// auth_repository.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of a successful login call.
class AuthSession {
  const AuthSession({
    required this.userId,
    required this.role,
    this.coachId,
    this.token,
    this.fullName,
  });

  final int userId;
  final String role;
  final int? coachId;
  final String? token;
  final String? fullName;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: _asInt(json['user_id']) ?? 0,
      role: (_asString(json['role']) ?? '').toLowerCase(),
      coachId: _asInt(json['coach_id']),

      // The PHP backend returns "session_token".
      // Keep "token" as a backward-compatible fallback.
      token: _asString(
        json['session_token'] ?? json['token'],
      ),

      fullName: _asString(
        json['full_name'] ?? json['name'],
      ),
    );
  }
}

/// Handles the login request.
class AuthRepository {
  AuthRepository({
    required String baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<AuthSession> login({
    required String phone,
    required String password,
    required String role,
  }) async {
    final Uri uri = Uri.parse('${_baseUrl}login.php');

    final http.Response response = await _client.post(
      uri,
      headers: const <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{
        'phone': phone.trim(),
        'password': password,
        'role': role.trim().toLowerCase(),
      }),
    );

    final Map<String, dynamic> root = _decodeResponse(response);

    if (
    response.statusCode < 200 ||
        response.statusCode >= 300 ||
        root['success'] == false) {
      throw AuthRepositoryException(
        _extractError(root),
        statusCode: response.statusCode,
      );
    }

    /*
     * Supports both response shapes:
     *
     * {
     *   "success": true,
     *   "data": { session fields }
     * }
     *
     * and:
     *
     * {
     *   "success": true,
     *   "data": {
     *     "message": "...",
     *     "data": { session fields }
     *   }
     * }
     */
    final Map<String, dynamic> sessionData =
    _findSessionData(root);

    final AuthSession session =
    AuthSession.fromJson(sessionData);

    if (session.userId <= 0) {
      throw const AuthRepositoryException(
        'The login response does not contain a valid user_id.',
      );
    }

    if (!<String>['admin', 'coach'].contains(session.role)) {
      throw const AuthRepositoryException(
        'The login response does not contain a valid role.',
      );
    }

    if (session.role == 'coach' && session.coachId == null) {
      throw const AuthRepositoryException(
        'The coach account is not linked to a coach profile.',
      );
    }

    if (session.token == null || session.token!.trim().isEmpty) {
      throw const AuthRepositoryException(
        'The login response does not contain session_token.',
      );
    }

    return session;
  }

  void dispose() {
    _client.close();
  }

  Map<String, dynamic> _decodeResponse(
      http.Response response,
      ) {
    dynamic decoded;

    try {
      decoded = response.body.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      throw AuthRepositoryException(
        'The server returned an unexpected response '
            '(${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map) {
      throw AuthRepositoryException(
        'The server returned an invalid response structure.',
        statusCode: response.statusCode,
      );
    }

    return Map<String, dynamic>.from(decoded);
  }

  Map<String, dynamic> _findSessionData(
      Map<String, dynamic> root,
      ) {
    Map<String, dynamic> current = root;

    for (int depth = 0; depth < 5; depth++) {
      final bool hasSessionFields =
          current.containsKey('user_id') &&
              current.containsKey('role');

      if (hasSessionFields) {
        return current;
      }

      final dynamic child = current['data'];

      if (child is! Map) {
        break;
      }

      current = Map<String, dynamic>.from(child);
    }

    return current;
  }

  String _extractError(Map<String, dynamic> root) {
    final dynamic message =
        root['message'] ?? root['error'];

    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final dynamic errors = root['errors'] ??
        (root['data'] is Map
            ? (root['data'] as Map)['errors']
            : null);

    if (errors is Map && errors.isNotEmpty) {
      return errors.values
          .map((dynamic value) => value.toString())
          .join('\n');
    }

    return 'Invalid phone number, password, or role.';
  }
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(
      this.message, {
        this.statusCode,
      });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

String? _asString(dynamic value) {
  if (value == null) return null;

  final String result = value.toString().trim();

  return result.isEmpty ? null : result;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value.toString());
}
