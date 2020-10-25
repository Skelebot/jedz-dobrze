import 'package:flutter/material.dart';

import 'splash.dart';

import 'package:jedzdobrze/util/extract_ingredients.dart';

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

  Future<Widget> ingredientTable;

  @override
  void initState() {
    super.initState();
    ingredientTable = createIngredientTable(data, resultImagePath);
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Składniki'), actions: <Widget>[
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () => {
              // Pop screens until we arrive back at the main screen
              Navigator.popUntil(context, (route) => route.isFirst)
            },
          )
        ]),
        body: Center(
            child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
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
                          print(snapshot.error);
                          return snapshot.error;
                        }
                        return Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Center(
                                      child: Padding(
                                          padding: EdgeInsets.all(15.0),
                                          child: CircularProgressIndicator())),
                                  Text("Odczytywanie składników...",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      )),
                                ]));
                      }),
                  ElevatedButton(
                      onPressed: () {
                        // Pop screens until we arrive back at the main screen
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.arrow_back),
                        Text('Wróć do początku'),
                      ])),
                ],
              )),
        )));
  }
}
