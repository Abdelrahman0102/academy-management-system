// group_repository.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/group.dart';

typedef GroupApiHeadersProvider =
Future<Map<String, String>> Function();

class GroupRepository {
  GroupRepository({
    required String baseUrl,
    required GroupApiHeadersProvider headersProvider,
    http.Client? client,
  })  : _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
        _headersProvider = headersProvider,
        _client = client ?? http.Client();

  final String _baseUrl;
  final GroupApiHeadersProvider _headersProvider;
  final http.Client _client;

  Future<List<TrainingGroupModel>> getGroups({
    int page = 1,
    int limit = 100,
    String? search,
    bool availableOnly = false,
  }) async {
    final Map<String, String> query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final String normalizedSearch = search?.trim() ?? '';
    if (normalizedSearch.isNotEmpty) query['search'] = normalizedSearch;
    if (availableOnly) query['available'] = '1';

    final Map<String, dynamic> root = await _get(
      'groups.php',
      queryParameters: query,
    );

    final dynamic rawGroups = _findValue(root, 'groups');

    if (rawGroups is! List) {
      throw const GroupRepositoryException(
        'The groups response does not contain a groups list.',
      );
    }

    return rawGroups
        .whereType<Map>()
        .map(
          (Map item) => TrainingGroupModel.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList(growable: false);
  }

  Future<List<TrainingGroupModel>> refresh({
    String? search,
    bool availableOnly = false,
  }) {
    return getGroups(
      search: search,
      availableOnly: availableOnly,
    );
  }

  Future<TrainingGroupModel> getGroup(int groupId) async {
    final Map<String, dynamic> root = await _get(
      'groups.php',
      queryParameters: <String, String>{
        'id': groupId.toString(),
      },
    );

    return _groupFromResponse(root);
  }

  Future<TrainingGroupModel> createGroup({
    required String groupName,
    required String? level,
    required int? maxPlayers,
    required List<GroupScheduleRequest> schedules,
    int? coachId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'group_name': groupName.trim(),
      'level': _nullableText(level),
      'max_players': maxPlayers,
      'schedules': schedules
          .map((GroupScheduleRequest item) => item.toJson())
          .toList(growable: false),
      if (coachId != null) 'coach_id': coachId,
    };

    final Map<String, dynamic> root = await _sendJson(
      method: 'POST',
      endpoint: 'groups.php',
      body: body,
    );

    return _groupFromResponse(root);
  }

  Future<TrainingGroupModel> updateGroup({
    required int id,
    required String groupName,
    required String? level,
    required int? maxPlayers,
    required List<GroupScheduleRequest> schedules,
    int? coachId,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'id': id,
      'group_name': groupName.trim(),
      'level': _nullableText(level),
      'max_players': maxPlayers,
      'schedules': schedules
          .map((GroupScheduleRequest item) => item.toJson())
          .toList(growable: false),
      if (coachId != null) 'coach_id': coachId,
    };

    final Map<String, dynamic> root = await _sendJson(
      method: 'PUT',
      endpoint: 'groups.php',
      body: body,
    );

    return _groupFromResponse(root);
  }

  Future<void> deleteGroup(int groupId) async {
    final http.Response response = await _client.delete(
      _uri(
        'groups.php',
        <String, String>{'id': groupId.toString()},
      ),
      headers: await _headers(jsonBody: false),
    );

    _decode(response);
  }

  void dispose() {
    _client.close();
  }

  Future<Map<String, dynamic>> _get(
      String endpoint, {
        Map<String, String>? queryParameters,
      }) async {
    final http.Response response = await _client.get(
      _uri(endpoint, queryParameters),
      headers: await _headers(jsonBody: false),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> _sendJson({
    required String method,
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    final Uri uri = _uri(endpoint, null);
    final Map<String, String> headers = await _headers(jsonBody: true);
    final String encodedBody = jsonEncode(body);

    late final http.Response response;

    switch (method) {
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: encodedBody,
        );
        break;
      case 'PUT':
        response = await _client.put(
          uri,
          headers: headers,
          body: encodedBody,
        );
        break;
      default:
        throw GroupRepositoryException(
          'Unsupported HTTP method: $method',
        );
    }

    return _decode(response);
  }

  Future<Map<String, String>> _headers({
    required bool jsonBody,
  }) async {
    final Map<String, String> provided = await _headersProvider();

    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
      ...provided,
    };

    if (jsonBody) headers['Content-Type'] = 'application/json';

    return headers;
  }

  Uri _uri(
      String endpoint,
      Map<String, String>? queryParameters,
      ) {
    return Uri.parse('$_baseUrl$endpoint').replace(
      queryParameters: queryParameters,
    );
  }

  TrainingGroupModel _groupFromResponse(Map<String, dynamic> root) {
    final dynamic rawGroup = _findValue(root, 'group');

    if (rawGroup is! Map) {
      throw const GroupRepositoryException(
        'The group response does not contain a group object.',
      );
    }

    return TrainingGroupModel.fromJson(
      Map<String, dynamic>.from(rawGroup),
    );
  }

  dynamic _findValue(Map<String, dynamic> source, String key) {
    if (source.containsKey(key)) return source[key];

    Map<String, dynamic> current = source;

    for (int depth = 0; depth < 8; depth++) {
      if (current.containsKey(key)) return current[key];

      final dynamic data = current['data'];
      if (data is! Map) break;

      current = Map<String, dynamic>.from(data);
    }

    return null;
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;

    try {
      decoded = response.body.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      throw GroupRepositoryException(
        'The server returned invalid JSON (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map) {
      throw GroupRepositoryException(
        'The server returned an invalid response structure.',
        statusCode: response.statusCode,
      );
    }

    final Map<String, dynamic> root =
    Map<String, dynamic>.from(decoded);

    final bool successfulStatus =
        response.statusCode >= 200 && response.statusCode < 300;

    if (!successfulStatus || root['success'] == false) {
      throw GroupRepositoryException(
        _extractError(root, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    return root;
  }

  String _extractError(
      Map<String, dynamic> root,
      int statusCode,
      ) {
    final List<String> details = <String>[];

    final dynamic data = root['data'];
    if (data is Map) _collectErrorValues(data, details);

    final dynamic errors = root['errors'];
    if (errors is Map) _collectErrorValues(errors, details);

    if (details.isNotEmpty) return details.toSet().join('\n');

    final dynamic message = root['message'] ?? root['error'];

    if (message is String &&
        message.trim().isNotEmpty &&
        message.trim().toLowerCase() != 'validation failed') {
      return message.trim();
    }

    switch (statusCode) {
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to manage this group.';
      case 404:
        return 'The requested group was not found.';
      case 409:
        return 'The group could not be changed because it is currently in use.';
      case 422:
        return 'Please review the entered group information.';
      default:
        if (statusCode >= 500) {
          return 'A server error occurred while processing the group.';
        }

        return 'The group request could not be completed.';
    }
  }

  void _collectErrorValues(Map values, List<String> output) {
    for (final dynamic value in values.values) {
      if (value is Map) {
        _collectErrorValues(value, output);
      } else if (value is List) {
        for (final dynamic item in value) {
          final String text = item.toString().trim();
          if (text.isNotEmpty) output.add(text);
        }
      } else if (value != null) {
        final String text = value.toString().trim();
        if (text.isNotEmpty) output.add(text);
      }
    }
  }

  String? _nullableText(String? value) {
    final String normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }
}

class GroupRepositoryException implements Exception {
  const GroupRepositoryException(
      this.message, {
        this.statusCode,
      });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
