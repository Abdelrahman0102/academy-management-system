// attendance_repository.dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '/models/player.dart';
import '/repositories/player_repository.dart';
import '/services/session_service.dart';

/// {@template attendance_repository_exception}
/// Exception thrown when an operation in [AttendanceRepository] fails.
/// {@endtemplate}
class AttendanceRepositoryException implements Exception {
  /// {@macro attendance_repository_exception}
  const AttendanceRepositoryException(
      this.message, {
        this.statusCode,
      });

  /// Human-readable error message.
  final String message;

  /// Optional HTTP status code.
  final int? statusCode;

  @override
  String toString() => message;
}

/// {@template attendance_repository}
/// Repository responsible for attendance-related operations.
///
/// Delegates player fetching to the existing [PlayerRepository]
/// and handles daily attendance marking via the attendance API.
/// {@endtemplate}
class AttendanceRepository {
  /// {@macro attendance_repository}
  AttendanceRepository({
    required http.Client client,
    required String baseUrl,
    required this.playerRepository,
  })  : _client = client,
        _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

  final http.Client _client;
  final String _baseUrl;

  /// Existing player repository for fetching coach players.
  final PlayerRepository playerRepository;

  /// Fetches all players assigned to the current coach.
  Future<List<PlayerModel>> getCoachPlayers() async {
    try {
      return await playerRepository.getPlayers();
    } on PlayerRepositoryException catch (error) {
      throw AttendanceRepositoryException(
        error.message,
        statusCode: error.statusCode,
      );
    } catch (error) {
      throw AttendanceRepositoryException(
        'Failed to load players: $error',
      );
    }
  }

  /// Marks daily attendance for a player.
  ///
  /// The backend updates today's existing row when the same player is marked
  /// again, and creates a new row when the date is different.
  Future<void> markAttendance({
    required int playerId,
    required String status,
    String? notes,
  }) async {
    final Uri uri = Uri.parse('${_baseUrl}attendance.php');

    final Map<String, dynamic> body = <String, dynamic>{
      'player_id': playerId,
      'status': status,
      'notes': notes,
    };

    try {
      final Map<String, String> headers =
      await SessionService.authHeaders();

      final http.Response response = await _client
          .post(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          ...headers,
        },
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 15));

      _decode(response);
    } on TimeoutException {
      throw const AttendanceRepositoryException(
        'Request timed out. Please try again.',
      );
    } on http.ClientException catch (error) {
      throw AttendanceRepositoryException(
        'Network request failed: ${error.message}',
      );
    } on AttendanceRepositoryException {
      rethrow;
    } catch (error) {
      throw AttendanceRepositoryException(
        'Failed to mark attendance: $error',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;

    try {
      decoded = response.body.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      throw AttendanceRepositoryException(
        'The server returned invalid JSON '
            '(${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map) {
      throw AttendanceRepositoryException(
        'The server returned an invalid response structure.',
        statusCode: response.statusCode,
      );
    }

    final Map<String, dynamic> root =
    Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        root['success'] == false) {
      throw AttendanceRepositoryException(
        _extractError(root),
        statusCode: response.statusCode,
      );
    }

    return root;
  }

  String _extractError(Map<String, dynamic> root) {
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

    return 'The request could not be completed.';
  }

  void dispose() {
    _client.close();
  }
}
