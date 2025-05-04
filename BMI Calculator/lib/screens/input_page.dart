import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() => runApp(BMICalculator());

class BMICalculator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF0A0E21),
        appBar: AppBar(
          title: Text('BMI Calculator'),
          backgroundColor: Color(0xFF0A0E21),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              FontAwesomeIcons.mars,
              size: 80.0,
              color: Colors.white,
            ),
            SizedBox(height: 15.0),
            Text(
              'MALE',
              style: TextStyle(
                fontSize: 18.0,
                color: Color(0xFF8D8E98),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
