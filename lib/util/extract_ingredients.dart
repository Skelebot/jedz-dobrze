import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:async';

import 'package:simple_ocr_plugin/simple_ocr_plugin.dart';
import 'package:diacritic/diacritic.dart';

import 'package:jedzdobrze/screens/splash.dart';
import 'package:woozy_search/woozy_search.dart';

Future<List<String>> extractIngredients(
    SpreadsheetData data, String imgPath) async {
  String extractedText = await SimpleOcrPlugin.performOCR(imgPath);
  final json = jsonDecode(extractedText);
  extractedText = json['text'];

  // Try a grayscaled image for better results
  //var img = image.decodeImage(File(imagePath).readAsBytesSync());
  //var grayscaled = image.grayscale(img);
  //final grayscalePath = join(directory.path, "tmp_grayscale.jpg");
  //File(grayscalePath).writeAsBytesSync(image.encodeJpg(grayscaled));
  //String extractedTextGrayscale = await SimpleOcrPlugin.performOCR(grayscalePath);
  //final jsong = jsonDecode(extractedTextGrayscale);
  //extractedTextGrayscale = jsong['text'];

  // Autocorrect
  extractedText = removeDiacritics(extractedText);
  // Remove interpunction
  var regexp = RegExp(r'[\?!\"\[\];\*]', caseSensitive: false);
  extractedText = extractedText.replaceAll(regexp, '');
  // Replace sequences of words that may as well be a comma with a comma
  regexp = RegExp(r'(w tym)|[\n\(\)\.]|(oraz)|( +i +)', caseSensitive: false);
  extractedText = extractedText.replaceAll(regexp, ',');
  // Fix up spaced E additions
  regexp = RegExp(r'e +(?=\d\d\d)', caseSensitive: false);
  extractedText = extractedText.replaceAll(regexp, 'e');
  // Remove any percentages
  regexp = RegExp(r'((,|\d)+%)', caseSensitive: false);
  extractedText = extractedText.replaceAll(regexp, '');
  // Fix groups of three numbers without an "e" before them
  regexp = RegExp(r'(?<!\d)\d\d\d(?!\d)', caseSensitive: false);
  extractedText = extractedText.replaceAllMapped(regexp, (match) {
    return 'e${match.group(0)}';
  });
  // Replace weird misunderstandings
  var repl = {
    r'\d\d\d\d+': '',
    r'(?<=(olej)) *roslinny': '',
    r'(?<=(olej)) *zwierzecy': '',
    r'(\|)': 'l',
    'naturaline': 'naturalne',
    r' +': ' ',
    r'skladniki': '',
    r'stadniki': '',
    r'tadniki': '',
    r'kladniki': '',
    r'skfadniki': '',
    r'aromat:': '',
    r'kwas:': '',
    r'barwnik:': '',
    r'produkt': '',
    r'moze': '',
    r'zawierac': '',
    r'(?<!,)( *)dwutlenek': ',dwutlenek',
    r'(?<!,)( *)kwas': ',kwas',
    r'(?<!,)( *)aromat': ',aromat',
    r'(?<!,)( *)aromaty': ',aromaty',
    r'^\d$': '',
    r'\d{1,2}': '',
  };

  for (var pair in repl.entries) {
    regexp = RegExp(pair.key, caseSensitive: false);
    extractedText = extractedText.replaceAll(regexp, pair.value);
  }
  // Replace duplicate commas resulting from the previous regexp's
  regexp = RegExp(r',* *,+', caseSensitive: false);
  extractedText = extractedText.replaceAll(regexp, ',');

  var ingredients = extractedText.split(',').map((ingredient) {
    var words = ingredient.trim().split(' ');
    print("pre correction: " + ingredient);
    // Remove duplicate words
    words = words.map((w) => w.trim().toLowerCase()).toSet().toList();
    // Search for the whole ingredient with underscores instead of spaces
    // (the way we added them while loading the spreadsheet)
    var search = words.join('_').trim();
    final output = data.dictionary.search(search);
    print(search + ": " + output[0].toString());
    if (output[0].score > 0.67) {
      // If we found exactly the thing we were looking for, return it without doing
      // any more corrections
      return output[0].text.replaceAll('_', ' ');
    }
    words = words.map((word) {
      // Autocorrect single words using fuzzy matching and levenshtein distance
      final output = data.dictionary.search(word);
      if (output[0].score > 0.67) {
        if (output[0].text.split(' ').length == 1) {
          // If we are nearly sure this is the word, return the corrected version,
          // but only if the corrected word is a single word
          return output[0].text;
        } else {
          return word;
        }
      } else {
        // Give up
        return word;
      }
    }).toList();
    // Dedup words again
    words = words.map((w) => w.trim().toLowerCase()).toSet().toList();

    print("post correction: " + words.join(' '));
    return words.join(' ');
  }).toList();

  return ingredients;
}

Future<Widget> createIngredientTable(
    SpreadsheetData data, String imagePath) async {
  List<String> ingredients = await extractIngredients(data, imagePath);
  print("Extracted ingredients: " + ingredients.toString());

  // Remove empty ingredients
  ingredients.retainWhere((element) => element.trim() != '');

  List<String> names = List(ingredients.length);
  List<String> long_names = List(ingredients.length);
  List<String> marks = List(ingredients.length);

  for (var i = 0; i < ingredients.length; i++) {
    var ingredient = ingredients[i];
    var nameIndex = data.values.indexWhere((item) {
      return item[1] == ingredient;
    });
    var longNameIndex = data.values.indexWhere((item) {
      return item[2] == ingredient;
    });
    if (nameIndex == -1 && longNameIndex == -1) {
      names[i] = ingredient;
      marks[i] = "Nie znaleziono";
      long_names[i] = "-";
    } else if (nameIndex == -1) {
      marks[i] = data.values[longNameIndex][3];
      names[i] = data.values[longNameIndex][1];
      long_names[i] = ingredient;
    } else {
      marks[i] = data.values[nameIndex][3];
      names[i] = ingredient;
      long_names[i] = data.values[nameIndex][2];
    }
  }

  print("marks collected");

  List<TableRow> rows = List();

  for (var i = 0; i < ingredients.length; i++) {
    // Capitalize the name
    var name = "${names[i][0].toUpperCase()}${names[i].substring(1)}";
    var longName = long_names[i];
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
          child: Padding(padding: EdgeInsets.all(10.0), child: Text(longName))),
      // Mark
      TableCell(
          child: Padding(padding: EdgeInsets.all(10.0), child: Text(mark))),
    ]));
  }

  // remove null rows
  rows.retainWhere((element) => element != null);

  // Calculate a mark for the whole product
  double dangerLevel = 0;
  for (final mark in marks) {
    switch (mark) {
      case "Nieszkodliwy":
        dangerLevel += 0.0;
        break;
      case "Nieszkodliwy (alergen)":
        dangerLevel += 0.1;
        break;
      case "Zalecana ostrożność":
        dangerLevel += 0.5;
        break;
      case "Podejrzany":
        dangerLevel += 1.0;
        break;
      case "Niebezpieczny":
        dangerLevel += 2.0;
        break;
    }
  }

  String productMark;
  if (dangerLevel < 1.0) {
    productMark = "Bardzo zdrowy";
  } else if (dangerLevel < 2.0) {
    productMark = "Zdrowy";
  } else if (dangerLevel < 3.0) {
    productMark = "Lekko niezdrowy";
  } else if (dangerLevel < 4.5) {
    productMark = "Niezdrowy";
  } else {
    productMark = "Bardzo niezdrowy";
  }

  // FIXME: i don't know if it still does that, but i've seen it overflow somehow
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
      Padding(
          padding: EdgeInsets.all(10.0),
          child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(
              "Ocena produkutu: ",
              textScaleFactor: 1.5,
            ),
            Text(
              productMark,
              textScaleFactor: 1.6,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ])))
    ],
  ));
}
