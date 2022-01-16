import 'package:die/OurMainPage.dart';
import 'package:flutter/material.dart';

import './MainPage.dart';

void main() => runApp(new Application());

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OurMainPage(),
      theme: ThemeData.light().copyWith(primaryColor: Colors.orange),
      darkTheme: ThemeData.dark().copyWith(primaryColor: Colors.deepOrange),
      themeMode: ThemeMode.system,
    );
  }
}
