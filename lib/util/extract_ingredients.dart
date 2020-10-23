import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:jedzdobrze/screens/splash_screen.dart';

import 'package:path/path.dart' as path;

import 'package:simple_ocr_plugin/simple_ocr_plugin.dart';
import 'package:diacritic/diacritic.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'dart:async';
import 'package:flutter/services.dart';

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
  var regexp = RegExp(r'[\?!\"\[\];]', caseSensitive: false);
  extractedText = extractedText.replaceAll(regexp, '');
  // Replace sequences of words that may as well be a comma with a comma
  regexp = RegExp(r'(w tym)|[\n\(\)\.]', caseSensitive: false);
  extractedText = extractedText.replaceAll(regexp, ',');
  // Fix up spaced E additions
  regexp = RegExp(r'e (?=\d\d\d)', caseSensitive: false);
  extractedText = extractedText.replaceAll(regexp, 'e');
  // Remove any percentages
  regexp = RegExp(r'((,|\d)+%)', caseSensitive: false);
  extractedText = extractedText.replaceAll(regexp, '');
  // Replace weird misunderstandings
  var repl = {
    r'(\|)': 'l',
    r'stadniki': '',
    r'skladniki': '',
    r'(?<!,)( *)dwutlenek': ',dwutlenek',
    r'(?<!,)( *)kwas': ',kwas',
    r'(?<!,)( *)aromat': ',aromat',
    r'(?<!,)( *)aromaty': ',aromaty',
    r'aromat:': '',
    r'kwas:': '',
    r'barwnik:': '',
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
    if (output[0].score > 0.8) {
      // If we found exactly the thing we were looking for, return it without doing
      // any more corrections
      return output[0].text.replaceAll('_', ' ');
    }
    words = words.map((word) {
      // Autocorrect single words using fuzzy matching and levenshtein distance
      final output = data.dictionary.search(word);
      if (output[0].score > 0.8) {
        //if (output[0].text.split(' ').length == 1) {
        //  // If we are nearly sure this is the word, return the corrected version,
        //  // but only if the corrected word is a single word
        //  return output[0].text;
        //}
        return output[0].text;
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

Future<Table> createIngredientTable(
    SpreadsheetData data, String imagePath) async {
  List<String> ingredients = await extractIngredients(data, imagePath);
  print("Extracted ingredients: " + ingredients.toString());

  // Remove empty ingredients
  ingredients.retainWhere((element) => element.trim() != '');

  List<String> marks = List(ingredients.length);

  for (var i = 0; i < ingredients.length; i++) {
    var ingredient = ingredients[i];
    var index = data.values.indexWhere((item) {
      return item[1] == ingredient || item[2] == ingredient;
    });
    if (index == -1) {
      marks[i] = "Nie znaleziono";
    } else {
      marks[i] = data.values[index][3];
    }
    print(marks[i]);
  }

  print("marks collected");

  List<TableRow> rows = List(ingredients.length);

  for (var i = 0; i < ingredients.length; i++) {
    var ingredient = ingredients[i];
    var mark = marks[i];
    print(ingredient);
    print(mark);
    rows[i] = TableRow(children: [
      TableCell(
          child:
              Padding(padding: EdgeInsets.all(10.0), child: Text(ingredient))),
      TableCell(
          child: Padding(padding: EdgeInsets.all(10.0), child: Text(mark))),
    ]);
  }

  return Table(
    border: TableBorder.all(style: BorderStyle.solid, color: Color(0xffdddddd)),
    children: rows,
  );
}
