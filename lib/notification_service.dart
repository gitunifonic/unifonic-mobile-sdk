import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get_ip_address/get_ip_address.dart';

import 'package:notification_service/model/notification_update.dart';
import 'package:notification_service/service/http_service.dart';
import 'package:path_provider/path_provider.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

export 'notification_service.dart';

class NotificationService {
  static  Map<dynamic, dynamic> _payload = {};

  static late AndroidNotificationChannel channel;

  static bool _isFlutterLocalNotificationsInitialized = false;

  final _firebaseMessaging = FirebaseMessaging.instance;

  final streamCtlr = StreamController<String>.broadcast();
  final titleCtlr = StreamController<String>.broadcast();
  final bodyCtlr = StreamController<String>.broadcast();

  static var _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final httpService = HttpService();

  static var _buildContext;
  static var _userIdentifier;
  static RemoteNotification? remoteNotification;


  NotificationService(BuildContext context, String userIdentifier) {
    _buildContext = context;
    if (!kIsWeb) {
      _setupFlutterNotifications();
    }

    // handle when app in active state
    _forgroundNotification();

    // handle when app running in background state
    _backgroundNotification();

    // handle when app completely closed by the user
    _terminateNotification();

    //_loadEnvVariables();
  }

  Future<void> _loadEnvVariables() async {
    // You can use 'await' here
    await dotenv.load(fileName: 'config/.env');
  }

  @pragma('vm:entry-point')
  static Future<void>  _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    await _setupFlutterNotifications();
  }

  Future<Map<String, dynamic>> _registerDevice(
      Map<String, dynamic> deviceInfoRequestDTO) async {

    var localToken = await _firebaseMessaging.getToken();
    if (localToken != null) {
      deviceInfoRequestDTO["firebaseToken"] = localToken;
    }

    return await httpService.registerDevice(deviceInfoRequestDTO);
  }

  _getCountryFromLatAndLng(var latitude, var longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          latitude,
          longitude
      );

      Placemark place = placemarks[0];
      return place.country;
    } catch (e) {
      print(e);
    }
  }

  void registerDevice(Map<String, dynamic> deviceInfoRequestDTO) async {

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceInfoRequestDTO["deviceType"]= androidInfo.brand;
      deviceInfoRequestDTO["deviceModel"] = androidInfo.model;
      deviceInfoRequestDTO["deviceOs"] =  "ANDROID";
    } else {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceInfoRequestDTO["deviceType"]= "iPhone";
      deviceInfoRequestDTO["deviceModel"] = iosInfo.model;
      deviceInfoRequestDTO["deviceOs"] = "IOS";

      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        // Handle denied permission
        print('Location permission denied for IOS device');
        return;
      }
    }

    Position? position = await Geolocator.getLastKnownPosition();
    if (position != null) {
      deviceInfoRequestDTO["latitude"] =   position.latitude;
      deviceInfoRequestDTO["longitude"] =  position.longitude;
      deviceInfoRequestDTO["country"] =  "UAE"; //@TODO update
      //     _getCountryFromLatAndLng(
      //     position.latitude, position.longitude
      // );
    }


    deviceInfoRequestDTO["deviceLanguage"]= "US";

    deviceInfoRequestDTO["deviceTimezone"] = DateTime.now().timeZoneName;

    var ipAddress = IpAddress(type: RequestType.json);
    var data = await ipAddress.getIpAddress();
    deviceInfoRequestDTO["lastIpAddress"] =  data['ip'];

    _registerDevice(deviceInfoRequestDTO);
    _showEvent();
  }

  Future<void> _showEvent() async {
    _setupFlutterNotifications();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showFlutterNotification(message);
    });
  }

  // TODO: private methods
  Future<void> _onBackgroundMessage(RemoteMessage message) async {
    await Firebase.initializeApp();
  }

  Future<void> _showFlutterNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    remoteNotification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification == null || android == null || kIsWeb) {
      return;
    }
    String largeIconPath = "";
    var imgUrl = android.imageUrl;

    if (imgUrl != null) {
      largeIconPath = await _downloadAndSaveFile(imgUrl, 'largeIcon');
    }

    _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            // styleInformation: bigPictureStyleInformation,
            largeIcon: FilePathAndroidBitmap(largeIconPath),

            // TODO add a proper drawable resource to android, for now using
            //      one that already exists in example app.
            icon: 'ic_launcher',
          ),
        ),
        payload: message.data.toString());
    _payload = message.data;
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static onSelectNotification(NotificationResponse notificationResponse) async {
    print("in onSelectNotification");
    print(_payload.toString());


    if (_payload['targetUrl'] != null) {
      var arguments = {
        'title': remoteNotification?.title,
        'body': remoteNotification?.body
      };

      //@TODO add notification to local storage from here
      Navigator.of(_buildContext)
          .pushReplacementNamed(_payload['targetUrl'], arguments: arguments);
    }

    NotificationUpdateModel notificationUpdateModel = NotificationUpdateModel(
        notificationId: _payload['notificationId'],
        notificationStatus: "CLICKED",
        userIdentifier: _userIdentifier
    );

    httpService.updateStatus(notificationUpdateModel);
  }

  static Future<void> _setupFlutterNotifications() async {
    if (_isFlutterLocalNotificationsInitialized) {
      return;
    }
    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
      'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    /// Create an Android Notification Channel.
    ///
    /// We use this channel in the `AndroidManifest.xml` file to override the
    /// default FCM channel to enable heads up notifications.
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set up the onSelectNotification callback
    _flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: onSelectNotification,
      onDidReceiveBackgroundNotificationResponse: onSelectNotification,
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  _forgroundNotification() {
    FirebaseMessaging.onMessage.listen(
          (message) async {
        if (message.data.containsKey('data')) {
          // Handle data message
          streamCtlr.sink.add(message.data['data']);
        }
        if (message.data.containsKey('notification')) {
          // Handle notification message
          streamCtlr.sink.add(message.data['notification']);
        }
        // Or do other work.
        titleCtlr.sink.add(message.notification!.title!);
        bodyCtlr.sink.add(message.notification!.body!);
      },
    );
  }

  _backgroundNotification() {
    FirebaseMessaging.onMessageOpenedApp.listen(
          (message) async {
        if (message.data.containsKey('data')) {
          // Handle data message
          streamCtlr.sink.add(message.data['data']);
        }
        if (message.data.containsKey('notification')) {
          // Handle notification message
          streamCtlr.sink.add(message.data['notification']);
        }
        // Or do other work.
        titleCtlr.sink.add(message.notification!.title!);
        bodyCtlr.sink.add(message.notification!.body!);
      },
    );
  }

  _terminateNotification() async {
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      if (initialMessage.data.containsKey('data')) {
        // Handle data message
        streamCtlr.sink.add(initialMessage.data['data']);
      }
      if (initialMessage.data.containsKey('notification')) {
        // Handle notification message
        streamCtlr.sink.add(initialMessage.data['notification']);
      }
      // Or do other work.
      titleCtlr.sink.add(initialMessage.notification!.title!);
      bodyCtlr.sink.add(initialMessage.notification!.body!);
    }
  }


}
