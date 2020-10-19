import 'package:flutter/material.dart';

class SelectScreen extends StatefulWidget {
  SelectScreen(this.image);

  // image to select from
  final Image image;

  @override
  State<StatefulWidget> createState() => SelectScreenState(image);
}

class SelectScreenState extends State<SelectScreen> {
  SelectScreenState(this.image);

  // image to select from
  final Image image;

  // TODO: drawing on image

  // TODO: add text & reset/send buttons
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          // displayed image
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[image],
      )),
    );
  }
}
