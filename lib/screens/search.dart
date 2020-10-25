import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:woozy_search/woozy_search.dart' as woozy;

import 'splash.dart';

class SearchScreen extends StatefulWidget {
  final SpreadsheetData data;

  SearchScreen(this.data);

  @override
  State<StatefulWidget> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController txtEditController = TextEditingController();

  Widget _tableBody = Container();

  void _onClearPress() {
    // clear the text field and the table
    txtEditController.clear();
    setState(() {
      _tableBody = Container();
    });
  }

  void _onSubmit(String text) {
    _processQuery(text);
  }

  void _onSearchPress() {
    _processQuery(txtEditController.text);
  }

  void _processQuery(String query) {
    // search with the query typed into the TextField
    var queryResponse = widget.data.dictionary.search(query);

    // debug print
    print('found: $queryResponse');

    // if the query is e + someNumber - you have to be specific
    double minQueryScore = 0.5;
    if (query.toLowerCase().startsWith(new RegExp(r'e\d*'))) {
      minQueryScore = 0.9;
    }

    // filter the response using the minQueryScore value
    var filteredResponse = [];
    for (var entry in queryResponse) {
      if (entry.score >= minQueryScore) {
        filteredResponse.add(entry);
      }
    }

    // debug print
    print('filtered: $filteredResponse');

    // get a list of found ingredients
    List<String> ingredients = [];
    for (var entry in filteredResponse) {
      if (!ingredients.contains(entry.text.toLowerCase())) {
        ingredients.add(entry.text.toLowerCase());
      }
    }

    // extract names, longNames and marks from the database
    List<String> names = List(ingredients.length);
    List<String> longNames = List(ingredients.length);
    List<String> marks = List(ingredients.length);

    for (var i = 0; i < ingredients.length; i++) {
      var ingredient = ingredients[i];
      var nameIndex = widget.data.values.indexWhere((item) {
        return item[1] == ingredient;
      });
      var longNameIndex = widget.data.values.indexWhere((item) {
        return item[2] == ingredient;
      });
      if (nameIndex == -1 && longNameIndex == -1) {
        names[i] = ingredient;
        marks[i] = "Nie znaleziono";
        longNames[i] = "-";
      } else if (nameIndex == -1) {
        marks[i] = widget.data.values[longNameIndex][3];
        names[i] = widget.data.values[longNameIndex][1];
        longNames[i] = ingredient;
      } else {
        marks[i] = widget.data.values[nameIndex][3];
        names[i] = ingredient;
        longNames[i] = widget.data.values[nameIndex][2];
      }
    }

    Widget table = _createTable(names, longNames, ingredients, marks);

    setState(() {
      _tableBody = table;
    });
  }

  Widget _createTable(List<String> names, List<String> longNames,
      List<String> ingredients, List<String> marks) {
    List<TableRow> rows = List();

    for (var i = 0; i < ingredients.length; i++) {
      // Capitalize the name
      var name = "${names[i][0].toUpperCase()}${names[i].substring(1)}";
      var longName = longNames[i];
      var mark = marks[i];
      if (mark == "Nie znaleziono") {
        // Do not generate a row if the item hasn't been found
        // comment this if you want those items to show up
        continue;
      }
      rows.add(TableRow(children: [
        // Name
        TableCell(
            child: Padding(padding: EdgeInsets.all(10.0), child: Text(name))),
        // Lomg name
        TableCell(
            child:
                Padding(padding: EdgeInsets.all(10.0), child: Text(longName))),
        // Mark
        TableCell(
            child: Padding(padding: EdgeInsets.all(10.0), child: Text(mark))),
      ]));
    }

    // remove null rows
    rows.retainWhere((element) => element != null);
    // if found any ingredient
    if (rows.length > 0) {
      return SingleChildScrollView(
          child: Column(
        children: [
          Table(
              border: TableBorder.all(
                  style: BorderStyle.solid, color: Color(0xffdddddd)),
              children: [
                TableRow(children: [
                  TableCell(
                    child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text("Nazwa",
                            textScaleFactor: 1.5,
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ),
                  TableCell(
                    child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text("Opis",
                            textScaleFactor: 1.5,
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ),
                  TableCell(
                    child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text("Ocena",
                            textScaleFactor: 1.5,
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ),
                ]),
                // All the rows
                ...rows,
              ]),
        ],
      ));
    }
    // if found zero ingredients
    else {
      return Text(
        "Nie znaleziono podobnych składników",
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: Text("Wyszukaj składnik"), actions: <Widget>[
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () => {
              // Pop screens until we arrive back at the main screen
              Navigator.popUntil(context, (route) => route.isFirst)
            },
          )
        ]),
        body: Padding(
          padding: EdgeInsets.all(5.0),
          child: Column(
            children: [
              // text field
              TextField(
                onSubmitted: _onSubmit,
                controller: txtEditController,
                decoration: InputDecoration(
                    labelText: 'Wyszukaj po nazwie',
                    hintText: 'Podaj nazwę składnika'),
              ),
              // buttons
              Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      FlatButton(
                        onPressed: _onClearPress,
                        child: Text('WYCZYŚĆ',
                            style: Theme.of(context).textTheme.button),
                        shape: StadiumBorder(),
                        color: Theme.of(context).buttonColor,
                      ),
                      Spacer(),
                      FlatButton(
                        onPressed: _onSearchPress,
                        child: Text('WYSZUKAJ',
                            style: Theme.of(context).textTheme.button),
                        shape: StadiumBorder(),
                        color: Theme.of(context).buttonColor,
                      )
                    ],
                  )),
              // body
              Padding(padding: EdgeInsets.all(10.0), child: _tableBody)
            ],
          ),
        ));
  }
}
