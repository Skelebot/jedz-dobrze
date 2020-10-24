import 'package:flutter/material.dart';

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
import 'home.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SplashScreenState();
  }
}

class SplashScreenState extends State<SplashScreen> {
  String _infoText = "Ładowanie...";

  Future<SpreadsheetData> _loadValuesState;

  @override
  void initState() {
    super.initState();
    _loadValuesState = _loadValues();
  }

  Future<SpreadsheetData> _loadValues() async {
    List<List<dynamic>> values;
    final dir = await getExternalStorageDirectory();
    File file = new File('${dir.path}/values.csv');

    // Check for internet connection
    try {
      _infoText = "Łączenie z internetem...";
      setState(() {});
      final result = await InternetAddress.lookup('example.com')
          .timeout(Duration(seconds: 2));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        // Connected
        _infoText = "Połączono.";
        setState(() {});

        _infoText = "Łączenie z bazą danych...";
        setState(() {});
        // Nie dotykać tego
        const API_KEY = 'AIzaSyC75LXD5ArCCWeP1_ptj-d_O0QtEng6Mr0';
        const FILE_ID = '1rYHaldH_ioyVDEwUJGyhutpMIU6VzyCECUIX9wAr9u4';

        var url =
            'https://docs.google.com/spreadsheets/export?id=$FILE_ID&key=$API_KEY&exportFormat=csv';
        var response = await http.get(url);

        _infoText = "Pobieranie bazy danych...";
        setState(() {});

        // 200 as in HTTP's "OK"
        if (response.statusCode == 200) {
          var string = convert.utf8.decode(response.bodyBytes);
          values = const CsvToListConverter().convert(string);
          // Remove the first row
          values.removeAt(0);
          file.writeAsString(ListToCsvConverter().convert(values));
          _infoText = "Pobrano dane.";
          setState(() {});
        } else {
          _infoText = "Pobieranie nieudane: kod ${response.statusCode}";
          await Future.delayed(Duration(seconds: 2));
        }
      }
    } on SocketException catch (ex) {
      _infoText = "Łączenie nieudane: błąd $ex";
      setState(() {});
      await Future.delayed(Duration(seconds: 2));
      print('Łączenie nieudane: błąd $ex');
    }

    _infoText = "Przygotowywanie danych...";
    setState(() {});
    final woozy = _setupAutocorrect(values);

    _infoText = "Dane gotowe.";
    setState(() {});
    return SpreadsheetData(values, woozy);
  }

  Woozy<String> _setupAutocorrect(List<List<dynamic>> values) {
    var woozy = Woozy<String>(caseSensitive: false, limit: 5);
    for (final row in values) {
      //woozy.addEntry(row[1], value: row[3]);
      // Nazwa (e + numer)
      woozy.addEntry(row[1]);
      // Każde słowo z nazwy potocznej
      woozy.addEntries(row[2].split(' '));
      // Nazwa potoczna z podłogami zamiast spacji
      String nazwaPotocznaSub = row[2].toString().replaceAll(' ', '_');
      woozy.addEntry(nazwaPotocznaSub);
      // Additional autocorrect
      if (row[5] != null) {
        woozy.addEntry(row[5]);
      }
    }
    return woozy;
  }

  // UI Splash screenu
  @override
  Widget build(BuildContext context) {
    // If the data has been loaded, advance to the main screen
    _loadValuesState.asStream().listen((data) {
      if (data != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  HackatonHome(title: "Jedz Dobrze", data: data),
              settings: RouteSettings(arguments: data)),
        );
      }
    });
    return Scaffold(
      body: Center(
        child: Container(
          padding: null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              new Text(
                "Jedz Dobrze",
                softWrap: true,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline,
              ),
              Padding(
                  padding: EdgeInsets.all(15.0),
                  // Infinitely spinning circle
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).accentColor),
                  )),
              Text('$_infoText'),
              //ElevatedButton(
              //    onPressed: null,
              //    child: Row(
              //      mainAxisSize: MainAxisSize.min,
              //      children: [Icon(Icons.cancel), Text("Anuluj")],
              //    ))
            ],
          ),
          alignment: Alignment(0.0, 0.0),
        ),
      ),
    );
  }
}

class SpreadsheetData {
  final List<List<dynamic>> values;
  final Woozy<String> dictionary;

  SpreadsheetData(this.values, this.dictionary);
}
