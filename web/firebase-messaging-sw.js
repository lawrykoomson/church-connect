importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey:            "AIzaSyAQ6XPQaVoHk58dVSQ96-q0RFGfTqzI2ZU",
  authDomain:        "church-management-system-d7d3a.firebaseapp.com",
  projectId:         "church-management-system-d7d3a",
  storageBucket:     "church-management-system-d7d3a.appspot.com",
  messagingSenderId: "909935097617",
  appId:             "1:909935097617:android:a99e28c3e379c221d7beb0",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Background message received:', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(
    notificationTitle,
    notificationOptions,
  );
});