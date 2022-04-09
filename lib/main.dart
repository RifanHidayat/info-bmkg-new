import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:b_lind/session/session.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:b_lind/splash_screen.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localstorage/localstorage.dart';
import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';

final FlutterTts flutterTts = FlutterTts();
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize firebase
  await Firebase.initializeApp();
  await initializeService();

  // you can just pass the function like this
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.subscribeToTopic('TopicToListen');

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);
  // var appDocumentDirectory =
  // await pathProvider.getApplicationDocumentsDirectory();
  //
  // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // SharedPreferences.setMockInitialValues({});
  runApp(MyApp());
}

void onIosBackground() {
  WidgetsFlutterBinding.ensureInitialized();
  print('FLUTTER BACKGROUND FETCH');
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
}

void onStart() {
  WidgetsFlutterBinding.ensureInitialized();

  final service = FlutterBackgroundService();
  service.onDataReceived.listen((event) {
    if (event["action"] == "setAsForeground") {
      service.setForegroundMode(true);
      return;
    }

    if (event["action"] == "setAsBackground") {
      service.setForegroundMode(false);
    }

    if (event["action"] == "stopService") {
      service.stopBackgroundService();
    }
  });

  // bring to foreground
  service.setForegroundMode(true);
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    await Firebase.initializeApp();

    if (!(await service.isServiceRunning())) timer.cancel();

    _MyAppState().getDataPref();

    // test using external plugin
    // final deviceInfo = DeviceInfoPlugin();
    // String device;
    // if (Platform.isAndroid) {
    //   final androidInfo = await deviceInfo.androidInfo;
    //   device = androidInfo.model;
    // }
    //
    // if (Platform.isIOS) {
    //   final iosInfo = await deviceInfo.iosInfo;
    //   device = iosInfo.model;
    // }

    // service.sendData({
    //   "current_date": DateTime.now().toIso8601String(),
    //   "device": device,
    // });
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // you need to initialize firebase first
  var magnitude = message.data['magnitude'];
  var distance = message.data['distance'];
  var info = 'gempa berkekuatan ' +
      message.data['magnitude'] +
      ' Magnitudo, pada ' +
      message.data['date'] +
      ' jam ' +
      message.data['time'] +
      ' di  ' +
      message.data['region'] +
      ', ' +
      message.data['distance'] +
      ' KM dari anda, ' +
      message.data['potency'] +
      '';

  if ((double.parse(magnitude.toString()) > 3 &&
          int.parse(distance.toString()) <= 150) ||
      (double.parse(magnitude.toString()) > 5 &&
          int.parse(distance.toString()) <= 250)) {
    flutterTts.speak(info);
  }
  showNotification(info, distance, magnitude, message);

  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

Future showNotification(info, distance, magnitude, title) async {
  if ((double.parse(magnitude.toString()) > 3 &&
          int.parse(distance.toString()) <= 150) ||
      (double.parse(magnitude.toString()) > 5 &&
          int.parse(distance.toString()) <= 250)) {
    flutterTts.speak(info);
  }

  flutterLocalNotificationsPlugin.show(
      0,
      title,
      info,
      NotificationDetails(
        android: AndroidNotificationDetails("0", "gempa",
            playSound: true,
            priority: Priority.high,
            importance: Importance.high,
            icon: '@mipmap/ic_launcher'

            // TODO add a proper drawable resource to android, for now using
            //      one that already exists in example app.
            ),
      ),
      payload: "${info}");
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var date, time;
  final LocalStorage storage = new LocalStorage('info');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InfoBMKG',
      home: SplashScreen(),
    );
  }

  void getDataPref() async {
    date = storage.getItem('date');
    time = storage.getItem('time');
    getData(date, time);
  }

  void getData(var date, time) async {
    try {
      Xml2Json xml2json = new Xml2Json();
      Position position = await Geolocator.getLastKnownPosition();

      var koordinat;
      final response = await http
          .get(Uri.parse("https://data.bmkg.go.id/DataMKG/TEWS/autogempa.xml"));

      xml2json.parse(response.body);
      var jsondata = xml2json.toGData();
      var data = json.decode(jsondata);

      var bmkgDate = data['Infogempa']['gempa']['Tanggal'][r'$t'];
      var bmkgTime = data['Infogempa']['gempa']['Jam'][r'$t'];
      var bmkgReligion = data['Infogempa']['gempa']['Wilayah'][r'$t'];
      var bmkgPotency = data['Infogempa']['gempa']['Potensi'][r'$t'];
      var bmkgMagnitude = data['Infogempa']['gempa']['Magnitude'][r'$t'];

      koordinat = data['Infogempa']['gempa']['point']['coordinates'][r'$t'];
      var indexKoma = koordinat.indexOf(',');
      var latGempa = double.parse(koordinat.substring(0, indexKoma));
      var longGempa = double.parse(koordinat.substring(indexKoma + 1));
      double distanceInMeters = Geolocator.distanceBetween(
          position.latitude, position.longitude, latGempa, longGempa);
      var info = 'gempa berkekuatan ' +
          bmkgMagnitude +
          ' Magnitudo, pada ' +
          bmkgDate +
          ' jam ' +
          bmkgTime +
          ' di  ' +
          bmkgReligion +
          ', ' +
          distanceInMeters.toString() +
          ' KM dari anda, ' +
          bmkgPotency +
          '';
      if ((date != bmkgDate.toString()) && (time != bmkgTime.toString())) {
        storage.setItem("date", bmkgDate.toString());
        storage.setItem('time', bmkgTime.toString());
        var jarakGempa = (distanceInMeters / 1000).round();
        print("data ${data['Infogempa']}");
        if (double.parse(bmkgMagnitude) > 5.0) {
          showNotification(info, jarakGempa.toInt(), bmkgMagnitude,
              "Info Gempa Dan ${bmkgPotency}");
        } else if ((double.parse(bmkgMagnitude) >= 3.0) && (jarakGempa) < 150) {
          showNotification(info, jarakGempa.toInt(), bmkgMagnitude,
              "Info Gempa Dan ${bmkgPotency}");
        }
      }
    } catch (e) {
      print("error ${e}");
    }
  }
}
