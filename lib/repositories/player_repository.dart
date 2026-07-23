// player_repository.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '/models/player.dart';
import '/models/group.dart';
import '/services/session_service.dart';

typedef ApiHeadersProvider =
Future<Map<String, String>> Function();

class PlayerRepository {
  PlayerRepository({
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

  Future<List<PlayerModel>> getPlayers({
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
      'players.php',
      queryParameters: query,
    );

    final Map<String, dynamic> container =
    _findContainer(root, 'players');

    final dynamic rawPlayers = container['players'];

    if (rawPlayers is! List) {
      throw const PlayerRepositoryException(
        'The players response does not contain a players list.',
      );
    }

    return rawPlayers
        .whereType<Map>()
        .map(
          (Map item) => PlayerModel.fromJson(
        Map<String, dynamic>.from(item),
      ),
    )
        .toList(growable: false);
  }

  Future<PlayerModel> getPlayer(int playerId) async {
    final Map<String, dynamic> root = await _get(
      'players.php',
      queryParameters: <String, String>{
        'id': playerId.toString(),
      },
    );

    final Map<String, dynamic> container =
    _findContainer(root, 'player');

    final dynamic rawPlayer = container['player'];

    if (rawPlayer is! Map) {
      throw const PlayerRepositoryException(
        'The player response does not contain a player object.',
      );
    }

    return PlayerModel.fromJson(
      Map<String, dynamic>.from(rawPlayer),
    );
  }

  Future<PlayerModel> createPlayer(
      PlayerInput input,
      ) async {
    final Map<String, dynamic> root = await _sendJson(
      method: 'POST',
      endpoint: 'players.php',
      body: input.toJson(),
    );

    final Map<String, dynamic> container =
    _findContainer(root, 'player');

    final dynamic rawPlayer = container['player'];

    if (rawPlayer is! Map) {
      throw const PlayerRepositoryException(
        'The create response does not contain the created player.',
      );
    }

    return PlayerModel.fromJson(
      Map<String, dynamic>.from(rawPlayer),
    );
  }

  Future<PlayerModel> updatePlayer(
      int playerId,
      PlayerInput input,
      ) async {
    final Map<String, dynamic> body = input.toJson();
    body['id'] = playerId;

    final Map<String, dynamic> root = await _sendJson(
      method: 'PUT',
      endpoint: 'players.php',
      body: body,
    );

    final Map<String, dynamic> container =
    _findContainer(root, 'player');

    final dynamic rawPlayer = container['player'];

    if (rawPlayer is! Map) {
      throw const PlayerRepositoryException(
        'The update response does not contain the updated player.',
      );
    }

    return PlayerModel.fromJson(
      Map<String, dynamic>.from(rawPlayer),
    );
  }

  Future<Map<String, dynamic>> saveEvaluation(
      Map<String, dynamic> evaluationData,
      ) async {
    final Map<String, dynamic> root = await _sendJson(
      method: 'POST',
      endpoint: 'evaluations.php',
      body: evaluationData,
    );

    final Map<String, dynamic> container =
    _findContainer(root, 'evaluation');

    final dynamic rawEvaluation =
    container['evaluation'];

    if (rawEvaluation is! Map) {
      throw const PlayerRepositoryException(
        'The save response does not contain the created evaluation.',
      );
    }

    return Map<String, dynamic>.from(rawEvaluation);
  }

  Future<String> uploadPlayerPhoto({
    required int playerId,
    required XFile photo,
  }) async {
    final Uri uri =
    _uri('upload_player_photo.php', null);

    final http.MultipartRequest request =
    http.MultipartRequest('POST', uri);

    request.headers.addAll(
      await _headers(jsonBody: false),
    );

    request.fields['player_id'] =
        playerId.toString();

    final List<int> bytes =
    await photo.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: photo.name,
      ),
    );

    final http.StreamedResponse streamedResponse =
    await request.send();

    final http.Response response =
    await http.Response.fromStream(
      streamedResponse,
    );

    final Map<String, dynamic> root =
    _decode(response);

    final Map<String, dynamic> container =
    _findContainer(root, 'photo');

    final dynamic photoUrl = container['photo'];

    if (photoUrl is! String ||
        photoUrl.trim().isEmpty) {
      throw const PlayerRepositoryException(
        'The photo upload response does not contain the photo URL.',
      );
    }

    return photoUrl.trim();
  }

  Future<List<TrainingGroupModel>> getGroups() async {
    final Map<String, dynamic> root = await _get(
      'groups.php',
      queryParameters: const <String, String>{
        'limit': '100',
      },
    );

    final Map<String, dynamic> container =
    _findContainer(root, 'groups');

    final dynamic rawGroups = container['groups'];

    if (rawGroups is! List) {
      throw const PlayerRepositoryException(
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

      default:
        throw PlayerRepositoryException(
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

    /*
     * Read the saved token directly as a safety net.
     * This prevents an empty headersProvider from silently
     * sending unauthenticated requests.
     */
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
      throw PlayerRepositoryException(
        'The server returned invalid JSON '
            '(${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map) {
      throw PlayerRepositoryException(
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
      throw PlayerRepositoryException(
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

class PlayerRepositoryException
    implements Exception {
  const PlayerRepositoryException(
      this.message, {
        this.statusCode,
      });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
