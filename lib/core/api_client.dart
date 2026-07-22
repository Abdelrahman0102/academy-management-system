// api_client.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  const ApiClient();

  Future<Map<String, dynamic>> get(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(response.body);
  }
}
