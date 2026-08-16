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
    // Si ya había un interceptor de un login/checkAuthStatus anterior (por
    // ejemplo uno con un token viejo/inválido), hay que sacarlo antes de
    // agregar el nuevo. Si no, ambos quedan apilados y como el header se
    // setea con `putIfAbsent`, el primero que corre (el viejo) gana siempre
    // — el token nuevo nunca llega a pisarlo y todo request autenticado
    // sale con credenciales viejas hasta recargar la página.
    if (_authInterceptor != null) {
      dio.interceptors.remove(_authInterceptor);
    }

    _authInterceptor = InterceptorsWrapper(
      onRequest: (RequestOptions requestOptions,
          RequestInterceptorHandler handler) async {
        requestOptions.headers['Authorization'] = 'Bearer $token';
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
