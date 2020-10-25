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
  final minQueryScore = 0.5;

  final TextEditingController txtEditController = TextEditingController();

  void _onClearPress() {
    txtEditController.clear();
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

    // filter the response using the minQueryScore value
    var filteredResponse = [];
    for (var entry in queryResponse) {
      if (entry.score >= minQueryScore) {
        filteredResponse.add(entry);
      }
    }

    print(filteredResponse);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Wyszukaj składnik")),
      body: Column(
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
          // TODO: add showing the table
          SingleChildScrollView(),
        ],
      ),
    );
  }
}
