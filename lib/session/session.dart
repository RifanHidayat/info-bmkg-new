import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session{
  void save({var date,time}) async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("date", date);
    sharedPreferences.setString('time', time);

  }
}