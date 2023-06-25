import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:meetups/http/web.dart';
import 'package:meetups/models/device.dart';
import 'package:meetups/screens/events_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> setPushToken(String? token) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? prefsToken = prefs.getString('pushToken');
  bool? prefsSent = prefs.getBool('tokenSent');

  if ((token == prefsToken) || (prefsSent == true)) {
    return;
  }

  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String? brand;
  String? model;

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    brand = androidInfo.brand;
    model = androidInfo.model;
  }
  if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    brand = iosInfo.systemName;
    model = iosInfo.systemVersion;
  }

  Device device = Device(
    token: token,
    model: model,
    brand: brand,
  );
  sendDevice(device);
}

void showMyDialog(String message) {
  Widget okButton = OutlinedButton(
      onPressed: () => Navigator.pop(navigatorKey.currentContext!),
      child: Text('Ok'));
  AlertDialog alert =
      AlertDialog(title: Text('Promo'), content: Text(message), actions: [
    okButton,
  ]);
  showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return alert;
      });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings notificationSettings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if ([AuthorizationStatus.authorized, AuthorizationStatus.provisional]
      .contains(notificationSettings.authorizationStatus)) {
    await _startPushNotificationHandler(messaging);
  }

  runApp(App());
}

Future<void> _startPushNotificationHandler(FirebaseMessaging messaging) async {
  String? token = await messaging.getToken();
  await setPushToken(token);

  // Foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      print('Body: ${message.notification!.body}');
    }
  });

  // Background
  FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
    print('Got a message whilst in the background!');
    print('Message data: ${message.data}');
  });

// Terminated
  final notification = await FirebaseMessaging.instance.getInitialMessage();
  if (notification != null && notification.data['message']?.length > 0) {
    showMyDialog(notification.data['message']);
  }
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dev meetups',
      home: EventsScreen(),
      navigatorKey: navigatorKey,
    );
  }
}
