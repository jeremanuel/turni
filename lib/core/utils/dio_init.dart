import 'dart:io';

import 'package:dio/dio.dart';
import 'package:turni/core/config/environment.dart';

class DioInit {
  static Dio init() {
    final dio = Dio();
    print(Environment.apiUrl);
    dio.options = BaseOptions(
      contentType: 'application/json',
      baseUrl: Environment.apiUrl
      );

  

    // dio.interceptors.add(InterceptorsWrapper(
    //   onRequest: (RequestOptions requestOptions,
    //       RequestInterceptorHandler handler) async {

    //     // TODO a todas las request se le agrega el token.
    //     final token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MiwiaWF0IjoxNzA5ODQ1ODQ4fQ.P284KLoU8_2Ovj6I8GtWgcxDBWWDvXBv0EWpIO4wQT4";

    //     requestOptions.headers
    //         .putIfAbsent('Authorization', () => 'Bearer $token');
    //     handler.next(requestOptions);
    //   },

    //   // onError: (DioException err, ErrorInterceptorHandler handler) async {
    //   //   // Catcheo de los errores en request. 

    //   //   // TODO si vamos a manejar vencimientos de sesiones, y tokens de refresco,
    //   //   // aca podemos detectar que se vencio una sesion y reintenar con un nuevo token

    //   // },
    // ));

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
