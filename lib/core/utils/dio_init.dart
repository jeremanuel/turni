import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/environment.dart';

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
      onRequest: (RequestOptions requestOptions, RequestInterceptorHandler handler) async {
        requestOptions.headers.putIfAbsent('Authorization', () => 'Bearer $token');
        handler.next(requestOptions);
      },
    );

    dio.interceptors.add(_authInterceptor!);
  }

  static removeTokenInterceptor(Dio dio) {
    dio.interceptors.remove(_authInterceptor);
  }

  static Interceptor? _authInterceptor;
}
