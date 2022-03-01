import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:b_lind/splash_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
final FlutterTts flutterTts = FlutterTts();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize firebase
  await Firebase.initializeApp();

  // you can just pass the function like this
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
  flutterTts.speak(message.notification.body);
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}


