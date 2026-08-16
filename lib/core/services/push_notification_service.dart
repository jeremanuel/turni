// ignore_for_file: avoid_print
//
// ---------------------------------------------------------------------------
// PASOS MANUALES PENDIENTES (config nativa de Firebase) — Fase 3
// ---------------------------------------------------------------------------
// Este servicio ya está listo para funcionar en cuanto exista un proyecto
// Firebase real. Hasta entonces, `Firebase.initializeApp()` falla en
// silencio (try/catch) y toda esta clase se vuelve no-op: no rompe
// `flutter run`/`flutter build` sin credenciales.
//
// Cuando el usuario cree el proyecto en la consola de Firebase, falta:
//
// Android:
//   1. Descargar `google-services.json` desde la consola de Firebase y
//      copiarlo a `android/app/google-services.json`.
//   2. En `android/build.gradle` (nivel raíz), agregar el classpath del
//      plugin de Google Services:
//        buildscript {
//          dependencies {
//            classpath 'com.google.gms:google-services:4.4.2'
//          }
//        }
//   3. En `android/app/build.gradle`, aplicar el plugin al final del
//      archivo (o en el bloque `plugins { }`):
//        apply plugin: 'com.google.gms.google-services'
//      (o `id "com.google.gms.google-services"` si se usa el bloque
//      `plugins { }` nuevo).
//   4. Verificar que `applicationId` en `android/app/build.gradle` coincida
//      con el paquete registrado en Firebase (hoy es
//      `com.example.turni`, probablemente haya que cambiarlo antes de
//      registrar la app en Firebase).
//
// iOS:
//   1. Descargar `GoogleService-Info.plist` desde la consola de Firebase y
//      agregarlo a `ios/Runner/` vía Xcode (con "Copy items if needed" y
//      target membership en "Runner").
//   2. En Xcode, habilitar las capabilities "Push Notifications" y
//      "Background Modes" → "Remote notifications" para el target Runner.
//   3. Subir la APNs Auth Key (o certificado) en la consola de Firebase,
//      sección Cloud Messaging del proyecto iOS.
//   4. Correr `pod install` dentro de `ios/` (requiere CocoaPods y que el
//      proyecto iOS esté completamente generado — a la fecha de este
//      comentario `ios/Runner/Info.plist` no existe en este repo, o sea
//      que el target iOS todavía no está inicializado del todo).
//
// Web (2026-08-12, proyecto Firebase real ya creado — "com.turni.admin"
// como nickname, config pegada abajo en `_webFirebaseOptions`):
//   - `web/firebase-messaging-sw.js` ya está armado con la misma config
//     (necesario porque el service worker corre en un contexto JS aislado,
//     no puede leer la config del lado Dart).
//   - VAPID key ya generada y cargada en `_webVapidKey` (usada solo en
//     `kIsWeb` dentro de `getToken()`).
// ---------------------------------------------------------------------------

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../infrastructure/localstorage/provider/local_storage.dart';
import '../config/app_router.dart';
import '../config/app_routes.dart';
import '../config/service_locator.dart';

/// Config del proyecto Firebase `turnibeta`, app Web "com.turni.admin".
/// Solo se usa en `kIsWeb` — Android/iOS toman su config de
/// `google-services.json`/`GoogleService-Info.plist` automáticamente.
const _webFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyCuetMWR3LtuEP9Eq9Fc0t3NAr0lNV5rLc',
  authDomain: 'turnibeta.firebaseapp.com',
  projectId: 'turnibeta',
  storageBucket: 'turnibeta.firebasestorage.app',
  messagingSenderId: '458036544256',
  appId: '1:458036544256:web:6481b1f7ee5cebe071a9e5',
  measurementId: 'G-B5VG4SFY3F',
);

/// Web Push certificate (VAPID key) del proyecto `turnibeta` — Project
/// Settings → Cloud Messaging → Web configuration. Necesaria para que
/// `FirebaseMessaging.instance.getToken()` funcione en el navegador.
const _webVapidKey =
    'BI5Tu5SWMap7OlPF2bQqZBcJ1NQFb8SoFRgjY9_SiZuNKLljXW37Aa0R5uxzhUfzkCWEomR8PrNBzmHdqRsYnk4';

/// Maneja el ciclo de vida de Firebase Cloud Messaging (FCM) en la app
/// admin: inicialización, permisos, obtención de token y manejo de tap en
/// la notificación.
///
/// Diseñado para no romper la app si todavía no existe un proyecto Firebase
/// real configurado (ver instrucciones arriba) — todos los métodos públicos
/// atrapan sus propios errores y devuelven valores "vacíos" en vez de
/// lanzar excepciones.
class PushNotificationService {
  PushNotificationService._();

  static bool _firebaseReady = false;

  /// Inicializa Firebase. Debe llamarse una sola vez, antes de `runApp`,
  /// con `WidgetsFlutterBinding.ensureInitialized()` ya invocado.
  ///
  /// Si no hay `google-services.json`/`GoogleService-Info.plist` reales
  /// (o el proyecto Firebase todavía no existe), esto falla en silencio:
  /// se loguea el error y el resto de la app sigue funcionando sin push.
  ///
  /// `Firebase.initializeApp()` en web no siempre *falla* cuando no puede
  /// completarse — en entornos con la red restringida hacia los servicios
  /// de Firebase/Google, se queda esperando indefinidamente sin lanzar
  /// ninguna excepción. Eso el try/catch de acá no lo detecta (no hay
  /// error, simplemente nunca resuelve) y bloqueaba `runApp()` para
  /// siempre — la app quedaba en blanco sin ningún error visible. El
  /// timeout convierte ese cuelgue silencioso en el mismo camino de "no
  /// está listo" que ya maneja el catch.
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: kIsWeb ? _webFirebaseOptions : null,
      ).timeout(const Duration(seconds: 5));
      _firebaseReady = true;
    } catch (error) {
      _firebaseReady = false;
      print(
        'PushNotificationService: Firebase no está configurado todavía '
        '(esperado en dev sin credenciales reales). Error: $error',
      );
    }
  }

  /// Registra los listeners de mensajes (foreground, tap en background y
  /// tap desde estado terminado). No-op si Firebase no pudo inicializarse.
  static void setupMessageHandlers() {
    if (!_firebaseReady) return;

    try {
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      }

      // Mensaje recibido con la app en foreground. Al ser un data message
      // (sin bloque "notification"), el SO no muestra nada automáticamente;
      // por ahora solo lo logueamos. Fase 4 podría mostrar un badge/banner
      // in-app acá si hace falta.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('PushNotificationService: mensaje en foreground: ${message.data}');
      });

      // Tap en la notificación con la app en background (no terminada).
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Tap en la notificación que abrió la app desde estado terminado.
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          _handleNotificationTap(message);
        }
      });

      _listenTokenRefresh();
    } catch (error) {
      print('PushNotificationService: error configurando handlers: $error');
    }
  }

  /// Re-registra el token contra el backend cuando FCM lo renueva (los
  /// tokens de FCM rotan periódicamente). Solo se suscribe una vez —
  /// llamado desde [setupMessageHandlers], no desde el login — y solo
  /// re-registra si hay una sesión guardada en ese momento (chequea el
  /// storage local en vez de depender de `AuthCubit` para no crear un
  /// import circular entre capas).
  static void _listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        final storedToken = await LocalStorage.read(LocalStorage.TOKEN_KEY);

        if (storedToken == null) return;

        await sl<AuthRepository>().registerDeviceToken(
          newToken,
          currentPlatform(),
        );
      } catch (error) {
        print('PushNotificationService: error en onTokenRefresh: $error');
      }
    });
  }

  /// Pide permiso de notificaciones y devuelve el token FCM actual, o
  /// `null` si Firebase no está configurado o el permiso fue denegado.
  static Future<String?> getToken() async {
    if (!_firebaseReady) return null;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission();

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!granted) return null;

      return await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
      );
    } catch (error) {
      print('PushNotificationService: error obteniendo token FCM: $error');
      return null;
    }
  }

  /// Plataforma esperada por el backend (`"android"|"ios"|"web"`).
  static String currentPlatform() {
    if (kIsWeb) return 'web';

    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  static void _handleNotificationTap(RemoteMessage message) {
    // TODO(Fase 4): cuando exista la UI de "solicitudes pendientes", si
    // message.data['type'] == 'SESSION_REQUEST_CREATED' navegar ahí
    // filtrado por message.data['session_id'] en vez de ir a la agenda
    // general.
    print('PushNotificationService: tap en notificación: ${message.data}');
    navigateToMainAgenda();
  }
}

/// Handler de mensajes en background. Debe ser una función de nivel
/// superior (no un método de instancia) para poder correr en el isolate
/// separado que usa FCM en Android.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Este código corre en un isolate aparte: no comparte el estado de
  // inicialización del isolate principal, así que hay que reinicializar
  // Firebase acá también.
  try {
    await Firebase.initializeApp();
  } catch (error) {
    print('PushNotificationService(bg): Firebase no configurado: $error');
    return;
  }

  print('PushNotificationService(bg): mensaje en background: ${message.data}');
}

/// Navega a la pantalla principal de agenda/turnos del admin.
///
/// Fase 4 todavía no tiene una pantalla de "solicitudes pendientes"; hasta
/// que exista, cualquier tap de notificación (de cualquier tipo) navega
/// acá. Cuando exista esa UI (Fase 4), este destino debería cambiar según
/// el `type`/`session_id` del payload de la notificación.
void navigateToMainAgenda() {
  try {
    rootRouter?.go(AppRoutes.SESSION_MANAGER_ROUTE['path']!);
  } catch (error) {
    print('PushNotificationService: error navegando desde push: $error');
  }
}
