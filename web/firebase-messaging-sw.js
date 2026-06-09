importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBXx3V2Ai8f--lxakiI0HdTf9pIhT2aRko",
  authDomain: "cacau-da-neta.firebaseapp.com",
  projectId: "cacau-da-neta",
  storageBucket: "cacau-da-neta.firebasestorage.app",
  messagingSenderId: "594909165569",
  appId: "1:594909165569:web:89e6ae1c47aeba08b7a800"
});

const messaging = firebase.messaging();
messaging.onBackgroundMessage((payload) => {
  self.registration.showNotification(payload.notification.title, {
    body: payload.notification.body,
  });
});
