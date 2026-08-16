// Service worker de Firebase Cloud Messaging para la app admin en web.
// Corre en un contexto JS aislado (no puede leer la config del lado Dart),
// por eso repite la misma config que `_webFirebaseOptions` en
// `lib/core/services/push_notification_service.dart` — si esa config
// cambia (rotación de API key, otro proyecto Firebase, etc.), hay que
// actualizarla acá también.

importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCuetMWR3LtuEP9Eq9Fc0t3NAr0lNV5rLc',
  authDomain: 'turnibeta.firebaseapp.com',
  projectId: 'turnibeta',
  storageBucket: 'turnibeta.firebasestorage.app',
  messagingSenderId: '458036544256',
  appId: '1:458036544256:web:6481b1f7ee5cebe071a9e5',
  measurementId: 'G-B5VG4SFY3F',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Mensaje en background:', payload);

  // Registrar `onBackgroundMessage` le saca a Firebase el manejo automático
  // de mostrar la notificación del sistema — a partir de acá es
  // responsabilidad nuestra, si no el mensaje llega pero nunca se ve nada.
  const notification = payload.notification || {};
  self.registration.showNotification(notification.title || 'Turni', {
    body: notification.body,
    icon: '/icons/Icon-192.png',
    data: payload.data,
  });
});
