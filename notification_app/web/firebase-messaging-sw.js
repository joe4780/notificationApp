// firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

// Initialize Firebase with my app's configuration
firebase.initializeApp({
  apiKey: "AIzaSyCtDOKuN4d1gprPXytHY5yMnaRmJy7mhiE",
  authDomain: "notificationsapp-a3306.firebaseapp.com",
  projectId: "notificationsapp-a3306",
  storageBucket: "notificationsapp-a3306.appspot.com",
  messagingSenderId: "731488632895",
  appId: "1:731488632895:web:6c7274bc43b10e2aeeb88a",
  measurementId: "G-KCEV8X8MRV",
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message ', payload);
  // Customize notification
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/firebase-logo.png',
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Service Worker lifecycle events
self.addEventListener('install', (event) => {
  console.log('Service Worker installed');
});

self.addEventListener('activate', (event) => {
  console.log('Service Worker activated');
});

self.addEventListener('fetch', (event) => {
});