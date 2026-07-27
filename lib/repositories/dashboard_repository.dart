// dashboard_repository.dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '/models/dashboard.dart';
import '/services/session_service.dart';

class DashboardRepository {
  DashboardRepository({
    required String baseUrl,
    http.Client? client,
  })  : _baseUrl =
  baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<DashboardData> getDashboard() async {
    final Uri uri =
    Uri.parse('${_baseUrl}dashboard.php');

    try {
      final Map<String, String> authHeaders =
      await SessionService.authHeaders();

      final http.Response response = await _client
          .get(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          ...authHeaders,
        },
      )
          .timeout(const Duration(seconds: 15));

      final Map<String, dynamic> root =
      _decode(response);

      final Map<String, dynamic>? payload =
      _findDashboardPayload(root);

      if (payload == null) {
        throw const DashboardRepositoryException(
          'The dashboard response has an invalid structure.',
        );
      }

      return DashboardData.fromJson(payload);
    } on TimeoutException {
      throw const DashboardRepositoryException(
        'Dashboard request timed out. Please try again.',
      );
    } on http.ClientException catch (error) {
      throw DashboardRepositoryException(
        'Network request failed: ${error.message}',
      );
    } on DashboardRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw DashboardRepositoryException(
        error.message.toString(),
      );
    } catch (error) {
      throw DashboardRepositoryException(
        'Unable to load dashboard: $error',
      );
    }
  }

  Map<String, dynamic> _decode(
      http.Response response,
      ) {
    dynamic decoded;

    try {
      decoded = response.body.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      throw DashboardRepositoryException(
        'The server returned invalid JSON '
            '(${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map) {
      throw DashboardRepositoryException(
        'The server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }

    final Map<String, dynamic> root =
    Map<String, dynamic>.from(decoded);

    if (response.statusCode == 401) {
      unawaited(SessionService.clear());

      throw DashboardRepositoryException(
        _extractError(
          root,
          fallback: 'Authentication is required.',
        ),
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        root['success'] == false) {
      throw DashboardRepositoryException(
        _extractError(root),
        statusCode: response.statusCode,
      );
    }

    return root;
  }

  Map<String, dynamic>? _findDashboardPayload(
      Map<String, dynamic> source, [
        int depth = 0,
      ]) {
    if (source['user'] is Map &&
        source['overview'] is Map) {
      return source;
    }

    if (depth >= 7) {
      return null;
    }

    for (final String key
    in <String>['data', 'result', 'payload']) {
      final dynamic child = source[key];

      if (child is! Map) {
        continue;
      }

      final Map<String, dynamic>? found =
      _findDashboardPayload(
        Map<String, dynamic>.from(child),
        depth + 1,
      );

      if (found != null) {
        return found;
      }
    }

    return null;
  }

  String _extractError(
      Map<String, dynamic> root, {
        String fallback =
        'The dashboard request could not be completed.',
      }) {
    final dynamic message =
        root['message'] ?? root['error'];

    if (message is String &&
        message.trim().isNotEmpty) {
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

    return fallback;
  }

  void dispose() {
    _client.close();
  }
}

class DashboardRepositoryException
    implements Exception {
  const DashboardRepositoryException(
      this.message, {
        this.statusCode,
      });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
