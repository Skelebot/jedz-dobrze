import 'dart:io';
import 'package:flutter/material.dart';

import 'splash.dart';
import 'select.dart';

// image picker
import 'package:image_picker_gallery_camera/image_picker_gallery_camera.dart';

class HackatonHome extends StatefulWidget {
  HackatonHome({Key key, this.title, this.data}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final SpreadsheetData data;

  @override
  HackatonHomeState createState() => HackatonHomeState(data);
}

class HackatonHomeState extends State<HackatonHome> {
  final SpreadsheetData data;

  HackatonHomeState(this.data);

  @override
  void initState() {
    super.initState();
  }

  void _scanImage(ImgSource source) async {
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

    // create select_screen if image was picked
    if (pickedImage != null) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) =>
              SelectScreen(Image.file(File(pickedImage.path)), data)));
    }
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
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                  labelText: 'Wyszukaj', hintText: 'Podaj nazwę składnika'),
            )
          ],
        ),
      ),
      // ActionButton na środku
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: FloatingActionButton.extended(
            onPressed: () => _scanImage(ImgSource.Both),
            tooltip: 'Skanuj',
            elevation: 3.0,
            icon: Icon(Icons.camera, color: Theme.of(context).cursorColor),
            label: Text('SKANUJ', style: Theme.of(context).textTheme.button),
            backgroundColor: Theme.of(context).buttonColor,
          )),
    );
  }
}
