// lib/core/network/api_client.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiBaseUrl.resolve();

  final http.Client _client;
  final String _baseUrl;

  Future<List<dynamic>> getList(String path) async {
    final response = await _client.get(Uri.parse('$_baseUrl$path'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('GET $path 실패: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is List<dynamic>) {
      return data;
    }

    throw Exception('GET $path 응답이 목록 형식이 아닙니다.');
  }

  Future<Map<String, dynamic>> getMap(String path) async {
    final response = await _client.get(Uri.parse('$_baseUrl$path'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('GET $path 실패: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('GET $path 응답이 객체 형식이 아닙니다.');
  }

  Future<Map<String, dynamic>> postMap(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var detail = '';
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic> && data['detail'] != null) {
          detail = ': ${data['detail']}';
        }
      } catch (_) {}

      throw Exception('POST $path 실패: ${response.statusCode}$detail');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('POST $path 응답이 객체 형식이 아닙니다.');
  }

  Future<Map<String, dynamic>> patchMap(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var detail = '';
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data is Map<String, dynamic> && data['detail'] != null) {
          detail = ': ${data['detail']}';
        }
      } catch (_) {}

      throw Exception('PATCH $path 실패: ${response.statusCode}$detail');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('PATCH $path 응답이 객체 형식이 아닙니다.');
  }

  Future<Map<String, dynamic>> deleteMap(String path) async {
    final response = await _client.delete(Uri.parse('$_baseUrl$path'));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('DELETE $path 실패: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('DELETE $path 응답이 객체 형식이 아닙니다.');
  }
}

class ApiBaseUrl {
  const ApiBaseUrl._();

  static String resolve() {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }
}
