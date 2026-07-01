import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../storage/secure_storage.dart';
import 'endpoints.dart';

export 'package:dio/dio.dart' show DioException, DioExceptionType;

// ── Provider ──────────────────────────────────────────────────────────────────
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage: storage);
});

// ── ApiClient ─────────────────────────────────────────────────────────────────
class ApiClient {
  late final Dio _dio;
  final SecureStorage storage;

  ApiClient({required this.storage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.base,
        connectTimeout: const Duration(seconds: 5), // Fail fast if host is unreachable
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(storage: storage, dio: _dio),
      _LoggingInterceptor(),
      _RetryInterceptor(dio: _dio),
    ]);
  }

  // ── GET ───────────────────────────────────────────────────────────────────
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(path,
        queryParameters: queryParameters, options: options);
  }

  // ── POST ──────────────────────────────────────────────────────────────────
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.post(path,
        data: data,
        queryParameters: queryParameters,
        options: options);
  }

  // ── PUT ───────────────────────────────────────────────────────────────────
  Future<Response> put(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    return _dio.put(path, data: data, options: options);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<Response> delete(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    return _dio.delete(path, data: data, options: options);
  }

  // ── Multipart ─────────────────────────────────────────────────────────────
  Future<Response> upload(
    String path,
    FormData formData, {
    ProgressCallback? onSendProgress,
  }) async {
    return _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}

// ── Auth Interceptor ──────────────────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  final SecureStorage storage;
  final Dio dio;

  _AuthInterceptor({required this.storage, required this.dio});

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired — clear local session
      await storage.clearAll();
    }
    handler.next(err);
  }
}

// ── Logging Interceptor ───────────────────────────────────────────────────────
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('→ ${options.method} ${options.path}', name: 'API');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('← ${response.statusCode} ${response.requestOptions.path}',
        name: 'API');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('✗ ${err.response?.statusCode} ${err.requestOptions.path} — ${err.message}',
        name: 'API');
    handler.next(err);
  }
}

// ── Retry Interceptor ─────────────────────────────────────────────────────────
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  static const _maxRetries = 2;

  _RetryInterceptor({required this.dio});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retries = (extra['retryCount'] ?? 0) as int;

    // Do not retry on bad response codes (4xx, 5xx)
    final isTimeout = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;

    if (isTimeout && retries < _maxRetries) {
      err.requestOptions.extra['retryCount'] = retries + 1;
      // Exponential backoff
      await Future.delayed(Duration(milliseconds: (retries + 1) * 800));
      try {
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (_) {}
    }
    handler.next(err);
  }
}

// ── Api Exception ─────────────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  factory ApiException.fromDioError(DioException e) {
    String msg = 'An unexpected error occurred';
    int? code = e.response?.statusCode;

    // Check if Laravel returned a validation or customized message
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return ApiException(message: data['message'].toString(), statusCode: code);
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        msg = 'Connection timeout. Please check if the server is running and reachable at ${e.requestOptions.baseUrl}.';
        break;
      case DioExceptionType.sendTimeout:
        msg = 'Sending data timed out. Please check your network connection.';
        break;
      case DioExceptionType.receiveTimeout:
        msg = 'Server took too long to respond. Please try again later.';
        break;
      case DioExceptionType.badResponse:
        if (code == 400) {
          msg = 'Bad Request. Please check input parameters.';
        } else if (code == 401) {
          msg = 'Session expired or invalid login. Please sign in again.';
        } else if (code == 403) {
          msg = 'Access denied. You do not have permission to view this content.';
        } else if (code == 404) {
          msg = 'Request endpoint not found on the server.';
        } else if (code == 500) {
          msg = 'Internal server error. The backend encountered a problem.';
        } else {
          msg = 'Server error (Status Code: $code).';
        }
        break;
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        final errString = e.toString().toLowerCase();
        if (errString.contains('socketexception') || errString.contains('network_unreachable') || errString.contains('connection refused')) {
          msg = 'Unable to connect to the server. Please verify your internet connection and check if the Laravel server is online at ${e.requestOptions.baseUrl}.';
        } else {
          msg = 'Network connection failed or host is unreachable.';
        }
        break;
      case DioExceptionType.cancel:
        msg = 'Request was cancelled.';
        break;
      default:
        msg = e.message ?? 'Unknown communication error.';
    }

    return ApiException(message: msg, statusCode: code);
  }

  @override
  String toString() => message;
}

