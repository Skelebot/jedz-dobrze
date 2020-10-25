import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // the app can bug out in horizontal mode.
  void _portraitModeOnly() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    _portraitModeOnly();

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
      // run SplashScreen
      home: SplashScreen(),
    );
  }
}
