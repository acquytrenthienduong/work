import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// Dio provider for network requests
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  
  // Base configuration
  dio.options = BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    sendTimeout: AppConstants.sendTimeout,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );

  // Add interceptors
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        AppLogger.logger.d('Request: ${options.method} ${options.path}');
        AppLogger.logger.d('Headers: ${options.headers}');
        if (options.data != null) {
          AppLogger.logger.d('Data: ${options.data}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.logger.d(
          'Response: ${response.statusCode} ${response.requestOptions.path}',
        );
        handler.next(response);
      },
      onError: (error, handler) {
        AppLogger.logger.e(
          'Error: ${error.response?.statusCode} ${error.requestOptions.path}',
          error: error,
        );
        handler.next(error);
      },
    ),
  );

  return dio;
});

/// Pretty logger interceptor for debugging
class PrettyDioLogger extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.logger.d('┌─────────────────────────────────────────────────────────────');
    AppLogger.logger.d('│ REQUEST');
    AppLogger.logger.d('│ ${options.method} ${options.baseUrl}${options.path}');
    AppLogger.logger.d('│ Headers: ${options.headers}');
    if (options.data != null) {
      AppLogger.logger.d('│ Data: ${options.data}');
    }
    AppLogger.logger.d('└─────────────────────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.logger.d('┌─────────────────────────────────────────────────────────────');
    AppLogger.logger.d('│ RESPONSE');
    AppLogger.logger.d('│ ${response.statusCode} ${response.requestOptions.path}');
    AppLogger.logger.d('│ Data: ${response.data}');
    AppLogger.logger.d('└─────────────────────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.logger.e('┌─────────────────────────────────────────────────────────────');
    AppLogger.logger.e('│ ERROR');
    AppLogger.logger.e('│ ${err.response?.statusCode} ${err.requestOptions.path}');
    AppLogger.logger.e('│ Message: ${err.message}');
    AppLogger.logger.e('│ Data: ${err.response?.data}');
    AppLogger.logger.e('└─────────────────────────────────────────────────────────────');
    handler.next(err);
  }
} 