import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC06uffq_fiiZfBlkv19o5uMVggZ7SoJpI',
    appId: '1:594909165569:android:abefc81b55f93a6cb7a800',
    messagingSenderId: '594909165569',
    projectId: 'cacau-da-neta',
    storageBucket: 'cacau-da-neta.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBXx3V2Ai8f--lxakiI0HdTf9pIhT2aRko',
    appId: '1:594909165569:ios:5e8d2ecfc4bf19c2b7a800',
    messagingSenderId: '594909165569',
    projectId: 'cacau-da-neta',
    storageBucket: 'cacau-da-neta.firebasestorage.app',
    iosBundleId: 'com.cacau.daneta',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBXx3V2Ai8f--lxakiI0HdTf9pIhT2aRko',
    appId: '1:594909165569:web:89e6ae1c47aeba08b7a800',
    messagingSenderId: '594909165569',
    projectId: 'cacau-da-neta',
    authDomain: 'cacau-da-neta.firebaseapp.com',
    storageBucket: 'cacau-da-neta.firebasestorage.app',
  );
}
