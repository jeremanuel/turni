import 'dart:io';

import 'package:dio/dio.dart';

class DioInit {
  static Dio init() {
    final dio = Dio();

    dio.options = BaseOptions(contentType: 'application/json');
    
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions requestOptions,
          RequestInterceptorHandler handler) async {

        // TODO a todas las request se le agrega el token.
        final token = "ver como obtener token";

        requestOptions.headers
            .putIfAbsent('Authorization', () => 'Bearer $token');
        handler.next(requestOptions);
      },

      onError: (DioException err, ErrorInterceptorHandler handler) async {
        // Catcheo de los errores en request. 

        // TODO si vamos a manejar vencimientos de sesiones, y tokens de refresco,
        // aca podemos detectar que se vencio una sesion y reintenar con un nuevo token

      },
    ));

    return dio;
  }

}
