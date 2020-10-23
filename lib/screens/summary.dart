import 'dart:io';
import 'package:flutter/material.dart';
import 'package:jedzdobrze/util/extract_ingredients.dart';

import 'splash.dart';
import 'select.dart';

// image picker
import 'package:image_picker_gallery_camera/image_picker_gallery_camera.dart';

class SummaryScreen extends StatefulWidget {
  SummaryScreen(this.resultImagePath, this.data);

  final String resultImagePath;
  final SpreadsheetData data;

  @override
  State<SummaryScreen> createState() =>
      SummaryScreenState(resultImagePath, data);
}

class SummaryScreenState extends State<SummaryScreen> {
  final String resultImagePath;
  final SpreadsheetData data;

  SummaryScreenState(this.resultImagePath, this.data);

  Future<Table> ingredientTable;

  @override
  void initState() {
    super.initState();
    ingredientTable = createIngredientTable(data, resultImagePath);
  }

  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Składniki'),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Padding(
            padding: EdgeInsets.all(15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FutureBuilder(
                    future: ingredientTable,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return snapshot.data;
                      } else if (snapshot.hasError) {
                        return snapshot.error;
                      }
                      return CircularProgressIndicator();
                    }),
                ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: Row(children: [
                      Icon(Icons.arrow_back),
                      Text('Wróć do początku'),
                    ])),
              ],
            )),
      ),
    );
  }
}
