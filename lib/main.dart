import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jedz Dobrze',
      theme: ThemeData(
        brightness: Brightness.dark,
        accentColor: const Color(0xfffac800),
        primaryColor: const Color(0xfffac800),
        cursorColor: const Color(0xfffcfcfc),
        fontFamily: 'Roboto',
        primarySwatch: Colors.amber,
        textTheme: Typography.whiteHelsinki,
      ),
      // Odpal SplashScreen
      home: SplashScreen(),
    );
  }
}
