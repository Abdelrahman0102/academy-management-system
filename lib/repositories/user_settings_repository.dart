import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user_settings.dart';

typedef AuthHeadersProvider = Future<Map<String, String>> Function();

class UserSettingsException implements Exception {
  const UserSettingsException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UserSettingsRepository {
  UserSettingsRepository({
    required this.baseUrl,
    required this.headersProvider,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final AuthHeadersProvider headersProvider;
  final http.Client _client;

  Uri get _settingsUri => Uri.parse(
    '${baseUrl.replaceAll(RegExp(r'/$'), '')}/user_settings.php',
  );

  Future<UserSettingsModel> getSettings() async {
    final Map<String, String> authHeaders =
    await headersProvider();

    final http.Response response = await _client.get(
      _settingsUri,
      headers: <String, String>{
        'Accept': 'application/json',
        ...authHeaders,
      },
    );

    final Map<String, dynamic> body =
    _decodeResponse(response);

    return UserSettingsModel.fromJson(
      _extractData(body),
    );
  }

  Future<UserSettingsModel> updateThemeMode({
    required bool darkMode,
  }) {
    return _updateSettings(<String, String>{
      'theme_mode': darkMode ? 'dark' : 'light',
    });
  }

  Future<UserSettingsModel> updateLanguageCode({
    required String languageCode,
  }) {
    final String normalized =
    languageCode.trim().toLowerCase();

    if (normalized != 'en' && normalized != 'ar') {
      throw const UserSettingsException(
        'The selected language is not supported.',
      );
    }

    return _updateSettings(<String, String>{
      'language_code': normalized,
    });
  }

  Future<UserSettingsModel> _updateSettings(
      Map<String, String> changes,
      ) async {
    final Map<String, String> authHeaders =
    await headersProvider();

    final http.Response response = await _client.put(
      _settingsUri,
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...authHeaders,
      },
      body: jsonEncode(changes),
    );

    final Map<String, dynamic> body =
    _decodeResponse(response);

    return UserSettingsModel.fromJson(
      _extractData(body),
    );
  }

  Map<String, dynamic> _decodeResponse(
      http.Response response,
      ) {
    Map<String, dynamic> body;

    try {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw const FormatException();
      }

      body = Map<String, dynamic>.from(decoded);
    } on FormatException {
      throw UserSettingsException(
        response.statusCode >= 500
            ? 'The server returned an invalid response.'
            : 'Unable to read the server response.',
      );
    }

    final bool successfulStatus =
        response.statusCode >= 200 &&
            response.statusCode < 300;

    final bool apiSuccess = body['success'] != false;

    if (!successfulStatus || !apiSuccess) {
      final String message =
          body['message']?.toString().trim() ?? '';

      throw UserSettingsException(
        message.isNotEmpty
            ? message
            : _messageForStatus(response.statusCode),
      );
    }

    return body;
  }

  Map<String, dynamic> _extractData(
      Map<String, dynamic> body,
      ) {
    dynamic value =
        body['data'] ?? body['result'] ?? body['payload'];

    while (value is Map) {
      final Map<String, dynamic> map =
      Map<String, dynamic>.from(value);

      final dynamic nested =
          map['data'] ?? map['result'] ?? map['payload'];

      if (nested is Map) {
        value = nested;
        continue;
      }

      return map;
    }

    throw const UserSettingsException(
      'User settings were not found in the server response.',
    );
  }

  String _messageForStatus(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to update these settings.';
      case 404:
        return 'The settings service was not found.';
      default:
        if (statusCode >= 500) {
          return 'A server error occurred while saving the settings.';
        }

        return 'Unable to update the settings.';
    }
  }

  void dispose() {
    _client.close();
  }
}
