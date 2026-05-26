import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_env.dart';

class AiseeApiDioFactory {
  const AiseeApiDioFactory._();

  static Dio create({Map<String, Object?>? headers}) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: AppEnv.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        responseType: ResponseType.json,
        headers: <String, Object?>{'Accept': 'application/json', ...?headers},
        validateStatus: (_) => true,
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
    return dio;
  }
}
