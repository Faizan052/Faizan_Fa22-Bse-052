import 'package:flutter/material.dart';
import 'screens/input_page.dart';

void main() => runApp(BMICalculator());

class BMICalculator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InputPage(),
      theme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF0A0E21), // Dark navy blue
        scaffoldBackgroundColor: Color(0xFF0A0E21), // Matching background
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1D1E33), // Dark purple for AppBar
        ),
        textTheme: TextTheme(
          bodyText1: TextStyle(color: Colors.white), // For general body text
          bodyText2: TextStyle(color: Colors.white70), // Slightly lighter
        ),
        accentColor: Color(0xFFEB1555), // Bright pink accent
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFEB1555), // FAB color
        ),
      ),
    );
  }
}
