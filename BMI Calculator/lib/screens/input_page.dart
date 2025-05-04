import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'constants.dart';
enum Gender { male, female }
class InputPage extends StatefulWidget {
  @override
  _InputPageState createState() => _InputPageState();
}
class _InputPageState extends State<InputPage> {
  Gender? selectedGender;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BMI Calculator'),
        backgroundColor: Color(0xFF0A0E21),
      ),
      backgroundColor: Color(0xFF0A0E21),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedGender = Gender.male;
                });
              },
              child: Container(
                color: selectedGender == Gender.male
                    ? Colors.blue
                    : Color(0xFF1D1E33),
                child: Center(
                  child: Icon(
                    FontAwesomeIcons.mars,
                    size: 80.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedGender = Gender.female;
                });
              },
              child: Container(
                color: selectedGender == Gender.female
                    ? Colors.pink
                    : Color(0xFF1D1E33),
                child: Center(
                  child: Icon(
                    FontAwesomeIcons.venus,
                    size: 80.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _InputPageState extends State<InputPage> {
  Gender? selectedGender;

  Widget buildGenderCard(Gender gender, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedGender = gender;
          });
        },
        child: Container(
          color: selectedGender == gender ? Colors.blue : Color(0xFF1D1E33),
          child: Center(
            child: Icon(
              icon,
              size: 80.0,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... [AppBar and other widgets]
      body: Column(
        children: [
          Row(
            children: [
              buildGenderCard(Gender.male, FontAwesomeIcons.mars),
              buildGenderCard(Gender.female, FontAwesomeIcons.venus),
            ],
          ),
          // ... [Other widgets]
        ],
      ),
    );
  }
}
