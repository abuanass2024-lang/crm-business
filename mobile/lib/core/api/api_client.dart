import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? 'http://10.0.2.2:3000/api';
  final String baseUrl;
  String? accessToken;

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: _headers());
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(Uri.parse('$baseUrl$path'), headers: _headers(), body: jsonEncode(body));
    return _decode(response);
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body['message'] ?? 'API request failed (${response.statusCode})');
    }
    return body;
  }
}
