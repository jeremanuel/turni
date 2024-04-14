
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static initEnvironment() async {
    await dotenv.load(fileName: fileName);
  }

  static String get fileName => kReleaseMode ? ".env.production" : ".env.development";

  static String get apiUrl => dotenv.get('API_URL', fallback: 'KEY API_URL no existente');

  static String get jwtSecret => dotenv.get('JWT_SECRET', fallback: 'KEY JWT_SECRET no existente');

  static String get version => dotenv.get('VERSION', fallback: 'KEY VERSION no existente');

  static String get googleClientId => dotenv.get('GOOGLE_CLIENT_ID', fallback: 'KEY VERSION no existente');


}
