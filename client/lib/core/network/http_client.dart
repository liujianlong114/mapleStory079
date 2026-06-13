import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../storage/storage_service.dart';

/// 统一的 API 响应结构
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode = 200,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, {T Function(dynamic)? parseData}) {
    final success = json['success'] as bool? ?? (json['error'] == null);
    return ApiResponse<T>(
      success: success,
      data: parseData != null && json['data'] != null ? parseData(json['data']) : json['data'] as T?,
      error: json['error'] as String? ?? json['message'] as String?,
      statusCode: json['status_code'] as int? ?? 200,
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'data': data,
        'error': error,
        'status_code': statusCode,
      };
}

/// Dio-like HTTP 客户端封装
class HttpClient {
  static final HttpClient _instance = HttpClient._internal();
  factory HttpClient() => _instance;
  HttpClient._internal();

  final http.Client _client = http.Client();
  final Duration _defaultTimeout = const Duration(seconds: 15);
  final int _maxRetries = 2;

  String get baseUrl => AppConfig.apiBaseUrl;

  Map<String, String> _defaultHeaders() {
    return <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, String>> _authHeaders() async {
    final headers = _defaultHeaders();
    final token = await StorageService().getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<ApiResponse<T>> _request<T>(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool requireAuth = true,
    T Function(dynamic)? parseData,
    int retryCount = 0,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final mergedHeaders = <String, String>{
        ...(requireAuth ? await _authHeaders() : _defaultHeaders()),
        ...?headers,
      };

      http.Response response;
      switch (method.toUpperCase()) {
        case 'POST':
          response = await _client
              .post(uri, headers: mergedHeaders, body: body != null ? jsonEncode(body) : null)
              .timeout(_defaultTimeout);
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: mergedHeaders, body: body != null ? jsonEncode(body) : null)
              .timeout(_defaultTimeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: mergedHeaders, body: body != null ? jsonEncode(body) : null)
              .timeout(_defaultTimeout);
          break;
        case 'GET':
        default:
          response = await _client.get(uri, headers: mergedHeaders).timeout(_defaultTimeout);
      }

      return _parseResponse<T>(response, parseData: parseData);
    } catch (e) {
      if (retryCount < _maxRetries) {
        debugPrint('HttpClient: 请求失败 ($e)，重试 ${retryCount + 1}/$_maxRetries');
        await Future.delayed(Duration(milliseconds: 300 * (retryCount + 1)));
        return _request<T>(
          method,
          path,
          body: body,
          queryParameters: queryParameters,
          headers: headers,
          requireAuth: requireAuth,
          parseData: parseData,
          retryCount: retryCount + 1,
        );
      }
      return ApiResponse<T>(
        success: false,
        error: e.toString().replaceAll('Exception: ', ''),
        statusCode: 0,
      );
    }
  }

  Uri _buildUri(String path, Map<String, String>? queryParameters) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path).replace(queryParameters: queryParameters);
    }
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(queryParameters: queryParameters);
  }

  ApiResponse<T> _parseResponse<T>(http.Response response, {T Function(dynamic)? parseData}) {
    final statusOk = response.statusCode >= 200 && response.statusCode < 300;
    if (response.body.isEmpty) {
      return ApiResponse<T>(
        success: statusOk,
        statusCode: response.statusCode,
        error: statusOk ? null : 'HTTP ${response.statusCode}',
      );
    }

    try {
      final dynamic json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is Map<String, dynamic>) {
        if (json.containsKey('success') || json.containsKey('error')) {
          return ApiResponse<T>.fromJson(json, parseData: parseData);
        }
        return ApiResponse<T>(
          success: statusOk,
          data: parseData != null ? parseData(json) : json as T?,
          statusCode: response.statusCode,
        );
      }
      return ApiResponse<T>(
        success: statusOk,
        data: json as T?,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<T>(
        success: statusOk,
        error: 'Parse error: $e',
        statusCode: response.statusCode,
      );
    }
  }

  // ============ Public Convenience Methods ============

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool requireAuth = true,
    T Function(dynamic)? parseData,
  }) =>
      _request<T>(
        'GET',
        path,
        queryParameters: queryParameters,
        headers: headers,
        requireAuth: requireAuth,
        parseData: parseData,
      );

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool requireAuth = true,
    T Function(dynamic)? parseData,
  }) =>
      _request<T>(
        'POST',
        path,
        body: body,
        queryParameters: queryParameters,
        headers: headers,
        requireAuth: requireAuth,
        parseData: parseData,
      );

  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool requireAuth = true,
    T Function(dynamic)? parseData,
  }) =>
      _request<T>(
        'PUT',
        path,
        body: body,
        queryParameters: queryParameters,
        headers: headers,
        requireAuth: requireAuth,
        parseData: parseData,
      );

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    bool requireAuth = true,
    T Function(dynamic)? parseData,
  }) =>
      _request<T>(
        'DELETE',
        path,
        body: body,
        queryParameters: queryParameters,
        headers: headers,
        requireAuth: requireAuth,
        parseData: parseData,
      );

  void close() => _client.close();
}
