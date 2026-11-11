import 'file_download_stub.dart' if (dart.library.js_interop) 'file_download_web.dart' as impl;

/// Descarga un archivo de texto generado en la app (ej. un CSV).
///
/// En la web lo baja el navegador y devuelve true. En las otras plataformas
/// todavía no hay descarga: devuelve false y la pantalla ofrece copiarlo.
Future<bool> downloadTextFile(String filename, String content, {String mimeType = 'text/csv;charset=utf-8'}) =>
    impl.downloadTextFile(filename, content, mimeType);
