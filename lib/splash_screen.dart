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

// For fuzzy search and string similarity for OCR autocorrect
import 'package:woozy_search/woozy_search.dart';

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
        const FILE_ID = '1rYHaldH_ioyVDEwUJGyhutpMIU6VzyCECUIX9wAr9u4';

        var url =
            'https://docs.google.com/spreadsheets/export?id=$FILE_ID&key=$API_KEY&exportFormat=csv';
        var response = await http.get(url);
        // 200 as in HTTP's "OK"
        if (response.statusCode == 200) {
          var string = convert.utf8.decode(response.bodyBytes);
          values = const CsvToListConverter().convert(string);
          // Remove the first row
          values.removeAt(0);
          file.writeAsString(ListToCsvConverter().convert(values));
          print('File found and downloaded');
        } else {
          print('Request failed with status: ${response.statusCode}.');
        }
      }
    } on SocketException catch (ex) {
      print('Could not connect: ');
      print('ex: $ex');
    }

    final woozy = _setupAutocorrect(values);

    //Create the home screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => HackatonHome(
              title: "Zdrowie the aplikacja",
              args: MainAppArguments(values, woozy)),
          settings: RouteSettings(arguments: MainAppArguments(values, woozy))),
    );
  }

  Woozy<String> _setupAutocorrect(List<List<dynamic>> values) {
    var woozy = Woozy<String>(caseSensitive: false, limit: 5);
    print('adding entries');
    for (final row in values) {
      //woozy.addEntry(row[1], value: row[3]);
      // Nazwa (e + numer)
      woozy.addEntry(row[1]);
      // Nazwa potoczna (tylko jeżeli to jedno słowo)
      if (row[2].split(' ').length == 1) {
        woozy.addEntry(row[2]);
      }
      // Additional autocorrect
      if (row[5] != null) {
        woozy.addEntry(row[5]);
      }
    }
    print('done adding entries');
    return woozy;
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

class MainAppArguments {
  final List<List<dynamic>> values;
  final Woozy<String> dictionary;

  MainAppArguments(this.values, this.dictionary);
}
