import 'dart:convert';

import 'package:dio/dio.dart';
import 'token_storage.dart';

class ApiService {
  final Dio _dio;

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.helpfouru.com/api',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Only attach the stored token when the caller hasn't already set
          // an Authorization header explicitly (e.g. a token passed straight
          // through from a login/verify-otp response before it's persisted).
          if (!options.headers.containsKey('Authorization')) {
            final token = await TokenStorage.readToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleNetworkError(e);
    }
  }

  Future<Response> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleNetworkError(e);
    }
  }

  Future<Response> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleNetworkError(e);
    }
  }

  Future<Response> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleNetworkError(e);
    }
  }

  dynamic _handleNetworkError(DioException error) {
    return error;
  }

  /// Uploads a single local file to `/upload/public/assets/:folder` (the
  /// admin panel's generic upload endpoint — this app has no upload UI of
  /// its own to draw the contract from otherwise) and returns the hosted
  /// path from `data.filePath`. `is_success` has been observed as both
  /// `true` and `1` across endpoints, so both are accepted defensively.
  Future<String> uploadFile(String folder, String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    // Photo/document uploads can easily take longer than the default 15s
    // timeout on a slow mobile connection — give them much more headroom
    // than a typical JSON request.
    final response = await post(
      '/upload/public/assets/$folder',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    // Some servers send the multipart-upload response with a content-type
    // Dio doesn't auto-decode as JSON, leaving response.data as a raw
    // String instead of a Map — decode it ourselves in that case.
    final body = response.data is String
        ? jsonDecode(response.data as String) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;
    final isSuccess = body['is_success'] == true || body['is_success'] == 1;
    if (isSuccess) {
      final data = body['data'] as Map<String, dynamic>;
      return data['filePath'] as String;
    }
    throw Exception(body['message'] as String? ?? 'Upload failed');
  }
}
