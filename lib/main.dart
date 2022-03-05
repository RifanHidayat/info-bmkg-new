import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:b_lind/splash_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;

final FlutterTts flutterTts = FlutterTts();
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize firebase
  await Firebase.initializeApp();

  // you can just pass the function like this
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.subscribeToTopic('TopicToListen');

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  var appDocumentDirectory =
      await pathProvider.getApplicationDocumentsDirectory();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'InfoBMKG',
    home: SplashScreen(),
  ));
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
Future showNotification(info, distance, magnitude, message) async {
  if ((double.parse(magnitude.toString()) > 3 &&
      int.parse(distance.toString()) <= 150) ||
      (double.parse(magnitude.toString()) > 5 &&
          int.parse(distance.toString()) <= 250)) {
    flutterTts.speak(info);

  }

  //flutterTts.speak(info);
  // print("data notif ${message}");
  RemoteNotification notification = message.notification;
  AndroidNotification android = message.notification?.android;

  flutterLocalNotificationsPlugin.show(
      0,
      notification.title,
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