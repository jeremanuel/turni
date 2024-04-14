import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:turni/core/config/environment.dart';

class DioInit {
  static Dio init() {
    final dio = Dio(
      BaseOptions(
        contentType: 'application/json',
        baseUrl: kIsWeb ? Environment.apiUrl : Environment.apiNativeUrl,
      ),
    );
    return dio;
  }

  static addTokenToInterceptor(Dio dio, String token) {
    _authInterceptor = InterceptorsWrapper(
      onRequest: (RequestOptions requestOptions,
          RequestInterceptorHandler handler) async {
        requestOptions.headers
            .putIfAbsent('Authorization', () => 'Bearer $token');
        handler.next(requestOptions);
      },
    );

    dio.interceptors.add(_authInterceptor!);
  }

  static removeTokenInterceptor(Dio dio) {
    print('INTERCEPTORS ANTEREMOVED: ${dio.interceptors.length}');
    print('REMOVE ${dio.interceptors.remove(_authInterceptor)}');
    print('INTERCEPTORS REMOVED: ${dio.interceptors.length}');
  }

  static Interceptor? _authInterceptor;
}
