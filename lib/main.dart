import 'package:flutter/material.dart';

import 'splash_screen.dart';
import 'select_screen.dart';

// image picker
import 'package:image_picker_gallery_camera/image_picker_gallery_camera.dart';



import 'dart:io';

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
  HackatonHome({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  HackatonHomeState createState() => HackatonHomeState();
}

class HackatonHomeState extends State<HackatonHome> {
  Image _image;

  void _scanImage(ImgSource source) async {
    // get image from source (gallery, camera or both)
    var pickedImage = await ImagePickerGC.pickImage(
      context: context,
      source: source,
      // camera styling
      cameraIcon: Icon(
        Icons.add_a_photo,
        color: Colors.red,
      ),
      cameraText: Text(
        "Nowe",
        style: TextStyle(color: Colors.black),
      ),

      // gallery styling
      galleryIcon: Icon(
        Icons.add_photo_alternate,
        color: Colors.red,
      ),
      galleryText: Text(
        "Z Galerii",
        style: TextStyle(color: Colors.black),
      ),
    );

    // create select_screen if image was picked
    if (pickedImage != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) =>
              SelectScreen(Image.file(File(pickedImage.path)))));
    }
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
          children: <Widget>[],
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
