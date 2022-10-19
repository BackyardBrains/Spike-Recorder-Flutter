import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseConfig {
  static FirebaseOptions? get platformOptions {
    if (kIsWeb) {
      // Web
      return const FirebaseOptions(
        apiKey: "AIzaSyCLnWX82fGBHvQWIHqEU2qfqGGgJHmIFJI",
        authDomain: "webspikerecorder.firebaseapp.com",
        projectId: "webspikerecorder",
        storageBucket: "webspikerecorder.appspot.com",
        messagingSenderId: "62668804297",
        appId: "1:62668804297:web:3fb6abbe2cfabf80523d18",
        measurementId: "G-BK6NLYYL50"        
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      // iOS and MacOS
      return const FirebaseOptions(
        appId: '1:448618578101:ios:cc6c1dc7a65cc83c',
        apiKey: 'AIzaSyAHAsf51D0A407EklG1bs-5wA7EbyfNFg0',
        projectId: 'react-native-firebase-testing',
        messagingSenderId: '448618578101',
        iosBundleId: 'com.invertase.testing',
        iosClientId:
            '448618578101-28tsenal97nceuij1msj7iuqinv48t02.apps.googleusercontent.com',
        androidClientId:
            '448618578101-a9p7bj5jlakabp22fo3cbkj7nsmag24e.apps.googleusercontent.com',
        databaseURL: 'https://react-native-firebase-testing.firebaseio.com',
        storageBucket: 'react-native-firebase-testing.appspot.com',
      );
    } else {
      // Android
      log("Analytics Dart-only initializer doesn't work on Android, please make sure to add the config file.");

      return null;
    }
  }
}