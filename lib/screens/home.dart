import 'package:flutter/material.dart';

import 'dart:io';

import 'splash.dart';
import 'select.dart';
import 'search.dart';

// image picker
import 'package:image_picker_gallery_camera/image_picker_gallery_camera.dart';

class HackatonHome extends StatefulWidget {
  HackatonHome({Key key, this.title, this.data}) : super(key: key);

  // app title
  final String title;
  // database
  final SpreadsheetData data;

  @override
  HackatonHomeState createState() => HackatonHomeState();
}

class HackatonHomeState extends State<HackatonHome> {
  // TODO: maybe add an option to scroll through the whole list?

  void _onSearchPress() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => SearchScreen(widget.data)));
  }

  void _onScanPress() async {
    var pickedImage = await _scanImage(ImgSource.Both);

    // create select_screen if image was picked
    if (pickedImage != null) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) =>
              SelectScreen(File(pickedImage.path), widget.data)));
    }
  }

  Future<dynamic> _scanImage(ImgSource source) async {
    // get image from source (gallery, camera or both)
    var pickedImage = await ImagePickerGC.pickImage(
      context: context,
      source: source,
      // camera styling
      cameraIcon: Icon(Icons.add_a_photo, color: Theme.of(context).accentColor),
      cameraText: Text(
        "Nowe",
        style: TextStyle(color: Colors.black),
      ),
      // gallery styling
      galleryIcon:
          Icon(Icons.add_photo_alternate, color: Theme.of(context).accentColor),
      galleryText: Text(
        "Z Galerii",
        style: TextStyle(color: Colors.black),
      ),
    );

    return pickedImage;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Image(image: AssetImage('assets/icon/icon.png')),
            onPressed: () => {},
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // TODO: add home page contents (like some text or something)
          children: <Widget>[
            Padding(
                padding: EdgeInsets.all(15.0),
                child: Image(image: AssetImage('assets/icon/icon.png'))),
            Text(
              'Witaj w aplikacji\n Jedz Dobrze!',
              textAlign: TextAlign.center,
              textScaleFactor: 2.5,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Padding(
                padding: EdgeInsets.all(15.0),
                child: Text(
                  'Zeskanuj skład produktu lub samemu wyszukaj jego składniki',
                  textAlign: TextAlign.center,
                  textScaleFactor: 1.5,
                ))
          ],
        ),
      ),
      // ActionButton na środku
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Padding(
              padding: EdgeInsets.all(15.0),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                FloatingActionButton.extended(
                  heroTag: "searchButton",
                  onPressed: _onSearchPress,
                  tooltip: 'Wyszukaj',
                  elevation: 3.0,
                  icon:
                      Icon(Icons.search, color: Theme.of(context).cursorColor),
                  label: Text('WYSZUKAJ',
                      style: Theme.of(context).textTheme.button),
                  backgroundColor: Theme.of(context).buttonColor,
                ),
                Spacer(),
                FloatingActionButton.extended(
                  heroTag: "scanButton",
                  onPressed: _onScanPress,
                  tooltip: 'Skanuj',
                  elevation: 3.0,
                  icon:
                      Icon(Icons.camera, color: Theme.of(context).cursorColor),
                  label:
                      Text('SKANUJ', style: Theme.of(context).textTheme.button),
                  backgroundColor: Theme.of(context).buttonColor,
                ),
              ]))),
    );
  }
}
