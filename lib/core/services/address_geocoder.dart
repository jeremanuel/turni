import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Busca las coordenadas de una dirección con Nominatim (OpenStreetMap):
/// gratis y sin API key, el mismo proveedor que usa el back para la ciudad.
/// Su política de uso pide no más de un pedido por segundo: se llama solo
/// cuando el admin lo pide, nunca mientras escribe.
class AddressGeocoder {
  AddressGeocoder._();

  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  /// Primer resultado en Argentina, o `null` si no encontró nada o falló.
  static Future<LatLng?> search(String address) async {
    final query = address.trim();
    if (query.isEmpty) return null;

    try {
      final response = await _dio.get<List<dynamic>>('/search', queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'limit': 1,
        'countrycodes': 'ar',
        'accept-language': 'es',
      });
      final first = response.data?.firstOrNull;
      if (first is! Map) return null;

      final lat = double.tryParse('${first['lat']}');
      final lng = double.tryParse('${first['lon']}');
      return lat == null || lng == null ? null : LatLng(lat, lng);
    } on DioException {
      return null;
    }
  }
}
