import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:simple_ocr_plugin/simple_ocr_plugin.dart';
import 'package:image/image.dart' as image;
import 'package:diacritic/diacritic.dart';

import 'splash_screen.dart';

// Robie jebany performance
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hackaton Zdrowie',
      theme: ThemeData(
        brightness: Brightness.dark,
        accentColor: const Color(0xfffac800),
        primaryColor: const Color(0xfffac800),
        // Używamy tego jako koloru tekstu bo nie ogarniam o co chodzi z kolorami we flutterze
        cursorColor: const Color(0xfffcfcfc),
        fontFamily: 'Roboto',
        primarySwatch: Colors.amber,
        // TODO: Wymienić tą czcionkę jak komuś zależy
        textTheme: Typography.whiteHelsinki,
      ),
      // Odpal SplashScreen
      home: SplashScreen(),
    );
  }
}

class HackatonHome extends StatefulWidget {
  HackatonHome({Key key, this.title, this.args}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final MainAppArguments args;

  @override
  HackatonHomeState createState() => HackatonHomeState(args);
}

class HackatonHomeState extends State<HackatonHome> {
  String _extractedText;
  final MainAppArguments arguments;

  HackatonHomeState(this.arguments);

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String extractedText;
    String extractedTextGrayscale;

    try {
      final Directory directory = await getTemporaryDirectory();
      final String imagePath = join(
        directory.path,
        "tmp_1.jpg",
      );
      final file = await rootBundle.load('assets/test/cola.jpg');
      final Uint8List bytes = file.buffer.asUint8List(
        file.offsetInBytes,
        file.lengthInBytes,
      );
      await File(imagePath).writeAsBytes(bytes);

      extractedText = await SimpleOcrPlugin.performOCR(imagePath);
      final json = jsonDecode(extractedText);
      extractedText = json['text'];

      // Try a grayscaled image for better results
      //var img = image.decodeImage(File(imagePath).readAsBytesSync());
      //var grayscaled = image.grayscale(img);
      //final grayscalePath = join(directory.path, "tmp_grayscale.jpg");
      //File(grayscalePath).writeAsBytesSync(image.encodeJpg(grayscaled));
      //extractedTextGrayscale = await SimpleOcrPlugin.performOCR(grayscalePath);
      //final jsong = jsonDecode(extractedTextGrayscale);
      //extractedTextGrayscale = jsong['text'];

      // Autocorrect
      extractedText = removeDiacritics(extractedText);
      // Remove interpunction
      var regexp = RegExp(r'[\?!\"\[\]]', caseSensitive: false);
      extractedText = extractedText.replaceAll(regexp, '');
      // Replace sequences of words that may as well be a comma with a comma
      regexp = RegExp(r'(w tym)|[:\n\(\)\.]', caseSensitive: false);
      extractedText = extractedText.replaceAll(regexp, ',');
      // Now replace duplicate commas resulting from the previous regexp
      regexp = RegExp(r',+', caseSensitive: false);
      extractedText = extractedText.replaceAll(regexp, ',');
      // Fix up spaced E additions
      regexp = RegExp(r'e (?=\d\d\d)', caseSensitive: false);
      extractedText = extractedText.replaceAll(regexp, 'e');
      // Remove any percentages
      regexp = RegExp(r'((,|\d)+%)', caseSensitive: false);
      extractedText = extractedText.replaceAll(regexp, '');
      // Replace weird misunderstandings
      var repl = {
        r'(\|)': '',
      };
      for (var pair in repl.entries) {
        regexp = RegExp(pair.key, caseSensitive: false);
        extractedText = extractedText.replaceAll(regexp, pair.value);
      }

      var ingredients = extractedText.split(',').map((ingredient) {
        var words = ingredient.trim().split(' ');
        // Remove duplicate words
        words = words.map((w) => w.trim().toLowerCase()).toSet().toList();
        words = words.map((word) {
          // Autocorrect single words using fuzzy matching and levenshtein distance
          final output = arguments.dictionary.search(word);
          if (output[0].score > 0.7) {
            // If we are nearly sure this is the word, return the corrected version
            return output[0].text;
          } else {
            // Give up
            return word;
          }
        }).toList();
        return words.join(' ');
      }).toList();

      extractedText = ingredients.toString();
    } on PlatformException {
      extractedText = 'Failed to extract text';
    }

    setState(() {
      _extractedText = extractedText; // + '\n' + extractedTextGrayscale;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      // TODO: Wywalić to jeżeli nie potrzebujemy dużego napisu zajmującego miejsce na ekranie
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Extracted text: ',
          ),
          Image(
            image: AssetImage(
              'assets/test/cola.jpg',
            ),
          ),
          _extractedText == null
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xffffffff)))
              : Text('$_extractedText',
                  style: Theme.of(context).textTheme.bodyText1),
        ],
      )),
      // ActionButton na środku
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: FloatingActionButton.extended(
            onPressed: () {},
            tooltip: 'Skanuj',
            elevation: 3.0,
            icon: Icon(Icons.camera, color: Theme.of(context).cursorColor),
            label: Text('SKANUJ', style: Theme.of(context).textTheme.button),
            backgroundColor: Theme.of(context).buttonColor,
          )),
    );
  }
}
