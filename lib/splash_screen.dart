import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// For opening/writing/saving files
import 'dart:io';
import 'dart:convert' as convert;

// For finding file paths
import 'package:path_provider/path_provider.dart';
// For converting the spreadsheet to CSV (comma separated values)
import 'package:csv/csv.dart';

// For downloading the spreadsheet
import 'package:http/http.dart' as http;

// The main app
import 'main.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _loadValues();
  }

  void _loadValues() async {
    List<List<dynamic>> values;
    var loaded = false;
    //final dir = await getApplicationDocumentsDirectory();
    final dir = await getExternalStorageDirectory();
    File file = new File('${dir.path}/values.csv');

    // Check for internet connection
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(Duration(seconds: 3));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // Connected
        print('connected');

        // Nie dotykać tego
        const API_KEY = 'AIzaSyC75LXD5ArCCWeP1_ptj-d_O0QtEng6Mr0';
        const FILE_ID = '18o5ksqpHFfbiUEbZeR1aR4qwwf9de2Y7GxPaMqWLkoY';
        var url =
            'https://docs.google.com/spreadsheets/export?id=$FILE_ID&key=$API_KEY&exportFormat=csv';
        var response = await http.get(url);
        // 200 to http status code dla "OK"
        if (response.statusCode == 200) {
          var string = convert.utf8.decode(response.bodyBytes);
          values = const CsvToListConverter().convert(string);
          // Remove the first row
          values.removeAt(0);
          file.writeAsString(ListToCsvConverter().convert(values));
          print('File found and downloaded');
          loaded = true;
        } else {
          print('Request failed with status: ${response.statusCode}.');
        }
      }
    } on SocketException catch (ex) {
      print('Could not connect: ');
      print('ex: $ex');
    }

    if (!loaded) {
      if (await file.exists()) {
        // If we already downloaded a file, open it
        values = const CsvToListConverter().convert(await file.readAsString());
      } else {
        values = const CsvToListConverter()
            .convert(await rootBundle.loadString('assets/values.csv'));
      }
    }

    //Create the home screen
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        // TODO: Wymyśleć nazwę (albo usunąć pasek tytułu)
        builder: (context) => HackatonHome(title: "Zdrowie the aplikacja")));
  }

  // UI Splash screenu
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              new Text(
                // TODO: Wymyśleć nazwę
                "Zdrowie the aplikacja",
                softWrap: true,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline,
              ),
              Padding(
                  padding: EdgeInsets.all(15.0),
                  // Kręcące się w nieskończoność kółko
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).accentColor),
                  )),
            ],
          ),
          alignment: Alignment(0.0, 0.0),
        ),
      ),
    );
  }
}
