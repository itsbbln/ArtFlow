import 'dart:async';

class ApiClient {
  const ApiClient({required this.baseUrl});

  final String baseUrl;

  Future<Map<String, dynamic>> get(String path) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return <String, dynamic>{'path': path, 'method': 'GET', 'baseUrl': baseUrl};
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return <String, dynamic>{
      'path': path,
      'method': 'POST',
      'baseUrl': baseUrl,
      'body': body,
    };
  }
}
