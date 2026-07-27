import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/parent_account_request.dart';

typedef ApiHeadersProvider =
Future<Map<String, String>> Function();

class ParentAccountRequestRepository {
  ParentAccountRequestRepository({
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

  Future<List<ParentAccountRequestModel>>
  getPendingRequests() async {
    final Uri uri = Uri.parse(
      '${_baseUrl}parent_account_requests.php',
    ).replace(
      queryParameters: const <String, String>{
        'status': 'pending_approval',
      },
    );

    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{
        'Accept': 'application/json',
        ...await _headersProvider(),
      },
    );

    final Map<String, dynamic> root =
    _decode(response);
    final dynamic data = root['data'];

    if (data is! Map) {
      throw const ParentApprovalException(
        'The request list response is invalid.',
      );
    }

    final dynamic rawRequests = data['requests'];

    if (rawRequests is! List) {
      throw const ParentApprovalException(
        'The response does not contain requests.',
      );
    }

    return rawRequests
        .whereType<Map>()
        .map(
          (Map item) =>
          ParentAccountRequestModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
    )
        .toList(growable: false);
  }

  Future<ParentAccountRequestModel> approve(
      int userId,
      ) {
    return _review(userId, 'approve');
  }

  Future<ParentAccountRequestModel> reject(
      int userId,
      ) {
    return _review(userId, 'reject');
  }

  Future<ParentAccountRequestModel> _review(
      int userId,
      String action,
      ) async {
    final http.Response response = await _client.post(
      Uri.parse(
        '${_baseUrl}parent_account_requests.php',
      ),
      headers: <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...await _headersProvider(),
      },
      body: jsonEncode(<String, dynamic>{
        'user_id': userId,
        'action': action,
      }),
    );

    final Map<String, dynamic> root =
    _decode(response);
    final dynamic data = root['data'];

    if (data is! Map || data['request'] is! Map) {
      throw const ParentApprovalException(
        'The review response is invalid.',
      );
    }

    return ParentAccountRequestModel.fromJson(
      Map<String, dynamic>.from(
        data['request'] as Map,
      ),
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
      throw ParentApprovalException(
        'The server returned invalid JSON '
            '(${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map) {
      throw ParentApprovalException(
        'The server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }

    final Map<String, dynamic> root =
    Map<String, dynamic>.from(decoded);

    if (
    response.statusCode < 200 ||
        response.statusCode >= 300 ||
        root['success'] == false) {
      final dynamic data = root['data'];
      final String message = data is Map &&
          data.isNotEmpty
          ? data.values
          .map((dynamic value) => value.toString())
          .join('\n')
          : root['message']?.toString() ??
          'The request could not be completed.';

      throw ParentApprovalException(
        message,
        statusCode: response.statusCode,
      );
    }

    return root;
  }

  void dispose() {
    _client.close();
  }
}

class ParentApprovalException implements Exception {
  const ParentApprovalException(
      this.message, {
        this.statusCode,
      });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
