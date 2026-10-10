import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static initEnvironment() async {
    await dotenv.load(fileName: fileName);
  }

  static String get fileName =>
      kReleaseMode ? ".env.production" : ".env.development";

  static String get apiUrl =>
      dotenv.get('API_URL', fallback: 'KEY API_URL no existente');

  static String get apiNativeUrl =>
      dotenv.get('API_NATIVE_URL', fallback: 'KEY API_NATIVE_URL no existente');

  static String get jwtSecret =>
      dotenv.get('JWT_SECRET', fallback: 'KEY JWT_SECRET no existente');

  static String get version =>
      dotenv.get('VERSION', fallback: 'KEY VERSION no existente');

  /// URL pública de la app admin web (ej. https://admin.turni.app/). Arma
  /// los links de invitación cuando la app no corre en web; en web, si falta,
  /// se usa la URL actual. También acepta `--dart-define=ADMIN_WEB_URL=...`
  /// (en local, para que los links abran otra instancia sin DEV_ADMIN_TOKEN).
  static String? get adminWebUrl {
    const fromDefine = String.fromEnvironment('ADMIN_WEB_URL');
    final value = (fromDefine.isNotEmpty ? fromDefine : dotenv.maybeGet('ADMIN_WEB_URL'))?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static String get googleClientId =>
      dotenv.get('GOOGLE_CLIENT_ID', fallback: 'KEY VERSION no existente');
}
