import 'package:b_lind/scraper_bmkg.dart';
import 'package:b_lind/nlp_test.dart';
import 'package:flutter_test/flutter_test.dart';
//mport 'package:b_lind/model/viewmodel.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  //print(await UdaraService().udara());
  //print(await GempaService().gempa());
  //print(await CuacaService().cuaca());
  print(await GPSService().gps());
  //print(await ServiceNLP().nlp());
}
