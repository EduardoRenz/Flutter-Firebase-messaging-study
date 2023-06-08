import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:meetups/http/web.dart';
import 'package:meetups/models/device.dart';
import 'package:meetups/screens/events_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? token = await messaging.getToken();
  await setPushToken(token);
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dev meetups',
      home: EventsScreen(),
    );
  }
}
