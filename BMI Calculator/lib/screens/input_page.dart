import 'package:flutter/material.dart';

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
        body: Center(
          child: Container(
            margin: EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: Color(0xFF1D1E33),
              borderRadius: BorderRadius.circular(10.0),
            ),
            height: 200.0,
            width: 200.0,
          ),
        ),
      ),
    );
  }
}
