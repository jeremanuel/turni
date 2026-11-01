// Service worker de Firebase Cloud Messaging para la app admin en web.
// Corre en un contexto JS aislado (no puede leer la config del lado Dart),
// por eso repite la misma config que `_webFirebaseOptions` en
// `lib/core/services/push_notification_service.dart` — si esa config
// cambia (rotación de API key, otro proyecto Firebase, etc.), hay que
// actualizarla acá también.

importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBj2EK2zMLZorcSeZSAnULi0lhbhYdwLiw',
  authDomain: 'turni-48aa4.firebaseapp.com',
  projectId: 'turni-48aa4',
  storageBucket: 'turni-48aa4.firebasestorage.app',
  messagingSenderId: '843039300029',
  appId: '1:843039300029:web:d6677caff072f70e2a9ad4',
  measurementId: 'G-QLB6SCJTYE',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Mensaje en background:', payload);

  // Si el mensaje trae `notification` (los del back siempre), la notificación
  // ya la mostró el SDK antes de llamar a este handler: mostrarla acá también
  // hacía que llegara doble. Solo un mensaje de datos se muestra a mano.
  if (payload.notification) return;
  const data = payload.data || {};
  if (!data.title) return;
  return self.registration.showNotification(data.title, {
    body: data.body,
    icon: '/icons/Icon-192.png',
    data,
  });
});
