// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show Firebase, FirebaseOptions;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {

  static initFirebase(platform) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: platform);
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBBLtwFqiAPD4A9d8YBkZKRaPYbLKcB2VQ',
    appId: '1:213885725058:android:8cdcbd477a04743daa879b',
    messagingSenderId: '213885725058',
    projectId: 'flutter-fcm-864d4',
    storageBucket: 'flutter-fcm-864d4.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyByi1pe6AUzyVFoXMAETzo4LFIUGc3SxuM',
    appId: '1:213885725058:ios:51de146f7dbbb952aa879b',
    messagingSenderId: '213885725058',
    projectId: 'flutter-fcm-864d4',
    storageBucket: 'flutter-fcm-864d4.appspot.com',
    iosBundleId: 'com.example.pushnotifications',
  );
}