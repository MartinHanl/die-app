import 'package:die/OurMainPage.dart';
import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

import './MainPage.dart';

void main() => runApp(new Application());
class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OurMainPage(),
      theme: FlexThemeData.light(scheme: FlexScheme.shark),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.shark),
      themeMode: ThemeMode.system,
    );
  }
}
