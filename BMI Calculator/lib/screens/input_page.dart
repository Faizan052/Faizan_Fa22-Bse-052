import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() => runApp(BMICalculator());

class BMICalculator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InputPage(),
    );
  }
}

class InputPage extends StatefulWidget {
  @override
  _InputPageState createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  bool isMaleSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BMI Calculator'),
        backgroundColor: Color(0xFF0A0E21),
      ),
      backgroundColor: Color(0xFF0A0E21),
      body: GestureDetector(
        onTap: () {
          setState(() {
            isMaleSelected = !isMaleSelected;
          });
        },
        child: Center(
          child: Icon(
            isMaleSelected ? FontAwesomeIcons.mars : FontAwesomeIcons.venus,
            size: 100.0,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
