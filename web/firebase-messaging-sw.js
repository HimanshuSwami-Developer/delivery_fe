// Handles FCM push notifications while the web app is backgrounded/closed.
// Must live at the site root (not under /web) and use the same config as
// lib/firebase_options.dart's `web` FirebaseOptions.
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyD4eIyLrAOzm7slZyYMRbTqr6iNP_96BkQ',
  appId: '1:262502507472:web:6eba10f2ded38027748fd5',
  messagingSenderId: '262502507472',
  projectId: 'aapnobazar-6295d',
  authDomain: 'aapnobazar-6295d.firebaseapp.com',
  storageBucket: 'aapnobazar-6295d.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? 'Aapno Bazar';
  const options = {
    body: payload.notification?.body,
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});
