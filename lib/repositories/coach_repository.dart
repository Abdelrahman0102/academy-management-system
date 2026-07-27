// coach_repository.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '/models/coach.dart';
import '/services/session_service.dart';

typedef ApiHeadersProvider =
Future<Map<String, String>> Function();

class CoachRepository {
  CoachRepository({
    required String baseUrl,
    required ApiHeadersProvider headersProvider,
    http.Client? client,
  })  : _baseUrl =
  baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
        _headersProvider = headersProvider,
        _client = client ?? http.Client();

  final String _baseUrl;
  final ApiHeadersProvider _headersProvider;
  final http.Client _client;

  Future<List<CoachModel>> getCoaches({
    int page = 1,
    int limit = 100,
    String? search,
  }) async {
    final Map<String, String> query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final String normalizedSearch =
        search?.trim() ?? '';

    if (normalizedSearch.isNotEmpty) {
      query['search'] = normalizedSearch;
    }

    final Map<String, dynamic> root = await _get(
      'coaches.php',
      queryParameters: query,
    );

    final Map<String, dynamic> container =
    _findContainer(root, 'coaches');

    final dynamic rawCoaches =
    container['coaches'];

    if (rawCoaches is! List) {
      throw const CoachRepositoryException(
        'The coaches response does not contain a coaches list.',
      );
    }

    return rawCoaches
        .whereType<Map>()
        .map(
          (Map item) => CoachModel.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList(growable: false);
  }

  Future<CoachModel> getCoach(int coachId) async {
    final Map<String, dynamic> root = await _get(
      'coaches.php',
      queryParameters: <String, String>{
        'id': coachId.toString(),
      },
    );

    final Map<String, dynamic> container =
    _findContainer(root, 'coach');

    final dynamic rawCoach = container['coach'];

    if (rawCoach is! Map) {
      throw const CoachRepositoryException(
        'The coach response does not contain a coach object.',
      );
    }

    return CoachModel.fromJson(
      Map<String, dynamic>.from(rawCoach),
    );
  }

  Future<CoachModel> createCoach(
      CoachInput input,
      ) async {
    final Map<String, dynamic> root = await _sendJson(
      method: 'POST',
      endpoint: 'coaches.php',
      body: input.toJson(),
    );

    return _coachFromCreateResponse(root);
  }

  /// Creates a coach directly from the Add Coach form without depending on
  /// a particular CoachInput constructor shape.
  Future<CoachModel> createCoachFromData({
    required String fullName,
    required String phone,
    required String password,
    String? specialization,
    String? notes,
  }) async {
    final Map<String, dynamic> root = await _sendJson(
      method: 'POST',
      endpoint: 'coaches.php',
      body: <String, dynamic>{
        'full_name': fullName,
        'phone': phone,
        'password': password,
        'specialization': specialization,
        'notes': notes,
      },
    );

    return _coachFromCreateResponse(root);
  }

  CoachModel _coachFromCreateResponse(
      Map<String, dynamic> root,
      ) {
    final Map<String, dynamic> container =
    _findContainer(root, 'coach');

    final dynamic rawCoach = container['coach'];

    if (rawCoach is! Map) {
      throw const CoachRepositoryException(
        'The create response does not contain the created coach.',
      );
    }

    return CoachModel.fromJson(
      Map<String, dynamic>.from(rawCoach),
    );
  }

  Future<CoachModel> updateCoach(
      int coachId,
      CoachInput input,
      ) async {
    final Map<String, dynamic> body =
    input.toJson();

    body['id'] = coachId;

    final Map<String, dynamic> root = await _sendJson(
      method: 'PUT',
      endpoint: 'coaches.php',
      body: body,
    );

    final Map<String, dynamic> container =
    _findContainer(root, 'coach');

    final dynamic rawCoach = container['coach'];

    if (rawCoach is! Map) {
      throw const CoachRepositoryException(
        'The update response does not contain the updated coach.',
      );
    }

    return CoachModel.fromJson(
      Map<String, dynamic>.from(rawCoach),
    );
  }

  Future<void> deleteCoach(int coachId) async {
    await _sendJson(
      method: 'DELETE',
      endpoint: 'coaches.php',
      body: <String, dynamic>{
        'id': coachId,
      },
    );
  }

  Future<List<CoachModel>> searchCoach(
      String query,
      ) {
    return getCoaches(search: query);
  }

  Future<List<CoachModel>> refresh() {
    return getCoaches();
  }

  void dispose() {
    _client.close();
  }

  Future<Map<String, dynamic>> _get(
      String endpoint, {
        Map<String, String>? queryParameters,
      }) async {
    final http.Response response =
    await _client.get(
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

    final Map<String, String> headers =
    await _headers(jsonBody: true);

    final String encodedBody =
    jsonEncode(body);

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

      case 'DELETE':
        response = await _client.delete(
          uri,
          headers: headers,
          body: encodedBody,
        );
        break;

      default:
        throw CoachRepositoryException(
          'Unsupported HTTP method: $method',
        );
    }

    return _decode(response);
  }

  Future<Map<String, String>> _headers({
    required bool jsonBody,
  }) async {
    final Map<String, String> providedHeaders =
    await _headersProvider();

    final Map<String, String> sessionHeaders =
    await SessionService.authHeaders();

    final Map<String, String> headers =
    <String, String>{
      'Accept': 'application/json',
      ...providedHeaders,
      ...sessionHeaders,
    };

    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }

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

  Map<String, dynamic> _decode(
      http.Response response,
      ) {
    dynamic decoded;

    try {
      decoded = response.body.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } on FormatException {
      throw CoachRepositoryException(
        'The server returned invalid JSON '
            '(${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map) {
      throw CoachRepositoryException(
        'The server returned an invalid response structure.',
        statusCode: response.statusCode,
      );
    }

    final Map<String, dynamic> root =
    Map<String, dynamic>.from(decoded);

    if (
    response.statusCode < 200 ||
        response.statusCode >= 300 ||
        root['success'] == false) {
      throw CoachRepositoryException(
        _extractError(root),
        statusCode: response.statusCode,
      );
    }

    return root;
  }

  Map<String, dynamic> _findContainer(
      Map<String, dynamic> source,
      String key,
      ) {
    if (source.containsKey(key)) {
      return source;
    }

    Map<String, dynamic> current = source;

    for (int depth = 0; depth < 5; depth++) {
      if (current.containsKey(key)) {
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

  String _extractError(
      Map<String, dynamic> root,
      ) {
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
}

class CoachRepositoryException
    implements Exception {
  const CoachRepositoryException(
      this.message, {
        this.statusCode,
      });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
