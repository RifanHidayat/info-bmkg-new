import 'dart:async';
import 'dart:convert';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:b_lind/home.dart';
import 'package:b_lind/page_gempa.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:vibration/vibration.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

class TutorialPage extends StatefulWidget {
  final List dataGempa;
  final List dataUdara;
  final List dataCuaca;
  final List dataKota;
  final List dataKotaHome;
  final String position;
  final int intGPS;
  final dynamic indexTime;

  TutorialPage(
      {Key key,
      @required this.dataGempa,
      this.dataUdara,
      this.dataCuaca,
      this.dataKota,
      this.dataKotaHome,
      this.intGPS,
      this.position,
      this.indexTime})
      : super(key: key);

  @override
  _TutorialPageState createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  String bahasa = 'id-ID';
  String teksTutorial1 = "selamat datang di info B M K G untuk tunanetra. ";
  String teksTutorial2 =
      "aplikasi ini akan memudahkan anda untuk mendapatkan informasi prakiraan cuaca hari ini dan besok di wilayah anda, gempa terkini diatas 5 magnitudo dan info kualitas udara, ";
  String teksTutorial3 =
      " Halaman utama aplikasi terdapat tombol mikrofon, ketika tombol di klik akan timbul suara klik dan bergetar, kemudian anda bisa bertanya tentang seputar informasi cuaca di tempat anda, gempa dan kualitas udara, ";
  String teksTutorial4 =
      "seperti, gempa yang terkini. atau. polusi udara di wilayah medan. atau. cuaca hari ini gimana ?.";
  String teksTutorial5 =
      " aplikasi akan memberikan informasi yang anda minta dalam bentuk suara. jika anda menslide ke kiri layar, terdapat menu tombol informasi cuaca diwilayah lain, tombol informasi gempa terkini, tombol informasi kualitas udara. Semoga aplikasi ini dapat membantu anda dalam mendapatkan informasi prakiraan cuaca, gempa bumi, dan kualitas udara. tekan tombol skip dibawah untuk masuk ke menu utama.";
  dynamic languages;
  String language;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  String newVoiceText;
  TtsState ttsState = TtsState.stopped;
  var duration = const Duration(seconds: 2);
  var token = "";
  Timer timer;

  get isPlaying => ttsState == TtsState.playing;

  get isStopped => ttsState == TtsState.stopped;
  stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts flutterTts = FlutterTts();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future _speakTutor1() async {
    speech.stop();
    flutterTts.setLanguage(bahasa);
    flutterTts.setPitch(pitch);
    teksTutorial1 = "selamat datang di info B M K G untuk tunanetra. ";
    teksTutorial2 =
        "aplikasi ini akan memudahkan anda untuk mendapatkan informasi prakiraan cuaca hari ini dan besok di wilayah anda, gempa terkini diatas 5 magnitudo dan info kualitas udara, ";
    flutterTts.speak(teksTutorial1 + teksTutorial2);
  }

  Future _speakTutor2() async {
    flutterTts.setLanguage(bahasa);
    flutterTts.setPitch(pitch);
    teksTutorial3 =
        " Halaman utama aplikasi terdapat tombol mikrofon, ketika tombol di klik akan timbul suara klik dan bergetar, kemudian anda bisa bertanya tentang seputar informasi cuaca di tempat anda, gempa dan kualitas udara, ";
    teksTutorial4 =
        "seperti, gempa yang terkini. atau. polusi udara di wilayah medan. atau. cuaca hari ini gimana ?.";
    flutterTts.speak(teksTutorial3 + teksTutorial4);
  }

  Future _speakTutor3() async {
    flutterTts.setLanguage(bahasa);
    flutterTts.setPitch(pitch);
    teksTutorial5 =
        " aplikasi akan memberikan informasi yang anda minta dalam bentuk suara. jika anda menslide ke kiri layar, terdapat menu tombol informasi cuaca diwilayah lain, tombol informasi gempa terkini, tombol informasi kualitas udara. Semoga aplikasi ini dapat membantu anda dalam mendapatkan informasi prakiraan cuaca, gempa bumi, dan kualitas udara. tekan tombol skip dibawah untuk masuk ke menu utama.";

    flutterTts.speak(teksTutorial5);
  }

  Future _stop() async {
    await flutterTts.stop();
  }

  Future _timer2F() async {
    var timer2 = Timer(const Duration(seconds: 16), () async {
      await _speakTutor2();
    });
  }

  Future _timer3F() async {
    var timer3 = Timer(const Duration(seconds: 38), () async {
      await _speakTutor3();
    });
  }

  Future<void> setupInteractedMessage() async {
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = new IOSInitializationSettings();
    var initSetttings = new InitializationSettings(android: android, iOS: iOS);
    flutterLocalNotificationsPlugin.initialize(initSetttings,
        onSelectNotification: onSelectNotification);
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotification(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    FirebaseMessaging.onBackgroundMessage((message) {
      print("_messaging onBackgroundMessage: $message");
      flutterTts.speak(message.notification.body);
      return;
    });
  }

  void _handleMessage(RemoteMessage message) {
    flutterTts.speak(message.notification.body);
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => GempaPage(dataGempa: widget.dataGempa)),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    FirebaseMessaging.instance.getToken().then((value) {
      token = value;
      print("token ${value}");
    });
    WidgetsFlutterBinding.ensureInitialized();
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    Workmanager().registerPeriodicTask("2", "simplePeriodicTask",
        frequency: Duration(minutes: 15));

    setupInteractedMessage();
  }

  void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) {
      sendData(token);

      return Future.value(true);
    });
  }

  Future showNotification(message) async {
    flutterTts.speak(message.notification.body);
    RemoteNotification notification = message.notification;
    AndroidNotification android = message.notification?.android;

    if (notification != null && android != null) {
      showNotification(notification);
    }
    flutterLocalNotificationsPlugin.show(
        0,
        notification.title,
        notification.body,
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
        payload: "${message.notification.body}");
  }

  Future onSelectNotification(var payload) async {
    flutterTts.stop();
    //flutterTts.speak(payload.toString());
    flutterTts.speak(payload);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => GempaPage(dataGempa: widget.dataGempa)),
    );
  }

  Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // showNotification(message);
    _TutorialPageState().showNotification(message);

    /// return await _TutorialPageState().showNotification(message);
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(80),
            child: AppBar(
              backgroundColor: Color(0xfffffc00),
              title: Container(
                alignment: Alignment.center,
                child: Semantics(
                  label: 'halaman tutorial',
                  child: ExcludeSemantics(
                    child: Text('Tutorial',
                        style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'fauna one',
                            fontSize: 40,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Semantics(
                  container: true,
                  label: 'tombol tutorial aplikasi info BMKG',
                  child: Container(
                    height: MediaQuery.of(context).size.height / 3,
                    child: FittedBox(
                      child: AvatarGlow(
                          animate: true,
                          glowColor: Colors.black,
                          endRadius: 35.0,
                          duration: const Duration(milliseconds: 2000),
                          repeatPauseDuration:
                              const Duration(milliseconds: 100),
                          child: ExcludeSemantics(
                            child: FloatingActionButton(
                                heroTag: 'btn1',
                                backgroundColor: Color(0xfffffc00),
                                onPressed: () async {
                                  if (await Vibration.hasVibrator()) {
                                    Vibration.vibrate(duration: 100);
                                  }
                                  speech.stop();

                                  await _speakTutor1();
                                },
                                child: Icon(
                                  Icons.play_arrow_sharp,
                                  color: Colors.black,
                                )),
                          )),
                    ),
                  ),
                ),
                Semantics(
                    container: true,
                    label: 'tombol skip tutorial',
                    child: Container(
                      height: MediaQuery.of(context).size.height / 3,
                      child: FittedBox(
                        child: AvatarGlow(
                          animate: true,
                          glowColor: Colors.black,
                          endRadius: 35.0,
                          duration: const Duration(milliseconds: 2000),
                          repeatPauseDuration:
                              const Duration(milliseconds: 100),
                          child: ExcludeSemantics(
                            child: FloatingActionButton(
                              heroTag: 'btn2',
                              backgroundColor: Color(0xfffffc00),
                              onPressed: () async {
                                if (await Vibration.hasVibrator()) {
                                  Vibration.vibrate(duration: 100);
                                }

                                _stop();
                                Navigator.pushReplacement(context,
                                    MaterialPageRoute(builder: (context) {
                                  return HomePage(
                                    dataGempa: widget.dataGempa,
                                    dataUdara: widget.dataUdara,
                                    dataCuaca: widget.dataCuaca,
                                    dataKota: widget.dataKota,
                                    dataKotaHome: widget.dataKotaHome,
                                    dataGPS: widget.position,
                                    intGPS: widget.intGPS,
                                    indexTime: widget.indexTime,
                                  );
                                }));
                              },
                              child: Text('SKIP',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontFamily: 'fira sans',
                                      fontSize: 20,
                                      color: Colors.black)),
                            ),
                          ),
                        ),
                      ),
                    ))
              ],
            ),
          ),
        ));
  }

  void sendData(token) async {
    var magnitudo = widget.dataGempa[0][1].toString();
    var distance = widget.dataGempa[0][4].toString();
    var serverKey =
        'AAAA1jksY9g:APA91bH-w1gc0SLbJkhLbWkbnwTJl1ZM2RELlzNRvWQtzkIJAQrgWNsNdrRy9jz47ZRpsWX9J4XTVSk5SPqII2VcfmgHR7GsLL1MBisghnOYyWuGr7YNR9k4l2UkFD44RWJyU92quofN';

    var info = 'gempa berkekuatan ' +
        widget.dataGempa[0][0].toString() +
        ' Magnitudo,\n pada ' +
        widget.dataGempa[0][1].toString() +
        ' jam ' +
        widget.dataGempa[0][2].toString() +
        ' di  ' +
        widget.dataGempa[0][3].toString() +
        ', ' +
        widget.dataGempa[0][4].toString() +
        ' KM dari anda, ' +
        widget.dataGempa[0][5].toString() +
        '';
    if ((int.parse(magnitudo) >= 5 && int.parse(distance) <= 150) ||
        (int.parse(magnitudo) > 5 && int.parse(distance) <= 250)) {
      try {
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'key=$serverKey',
          },
          body: jsonEncode(
            <String, dynamic>{
              'notification': <String, dynamic>{
                'body': '${info}',
                'title': 'Title'
              },
              'priority': 'high',
              'data': <String, dynamic>{
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'id': '1',
                'status': 'done'
              },
              'to': token,
            },
          ),
        );
      } catch (e) {
        print("error push notification");
      }
    }
  }
}
