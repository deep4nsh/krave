// File generated manually for krave-124 Firebase project.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDjf_w0-Kfb0SGyXUA41xqPHkO4Tul6JKw',
    appId: '1:325148399429:android:8043a5577416c64672102c',
    messagingSenderId: '325148399429',
    projectId: 'krave-124',
    storageBucket: 'krave-124.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDjf_w0-Kfb0SGyXUA41xqPHkO4Tul6JKw',
    appId: '1:325148399429:android:8043a5577416c64672102c',
    messagingSenderId: '325148399429',
    projectId: 'krave-124',
    storageBucket: 'krave-124.firebasestorage.app',
    iosBundleId: 'com.krave.riderApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDjf_w0-Kfb0SGyXUA41xqPHkO4Tul6JKw',
    appId: '1:325148399429:android:8043a5577416c64672102c',
    messagingSenderId: '325148399429',
    projectId: 'krave-124',
    storageBucket: 'krave-124.firebasestorage.app',
    authDomain: 'krave-124.firebaseapp.com',
  );
}
