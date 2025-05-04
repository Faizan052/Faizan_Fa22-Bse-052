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
// ... [Previous code]

class _InputPageState extends State<InputPage> {
  // ... [Previous variables]
  int height = 180;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... [AppBar and other widgets]
      body: Column(
        children: [
          // ... [Gender selection row]
          Expanded(
            child: Container(
              color: Color(0xFF1D1E33),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('HEIGHT', style: kLabelTextStyle),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        height.toString(),
                        style: TextStyle(
                          fontSize: 50.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(' cm', style: kLabelTextStyle),
                    ],
                  ),
                  Slider(
                    value: height.toDouble(),
                    min: 120.0,
                    max: 220.0,
                    activeColor: Colors.white,
                    inactiveColor: Color(0xFF8D8E98),
                    onChanged: (double newValue) {
                      setState(() {
                        height = newValue.round();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          // ... [Other widgets]
        ],
      ),
    );
  }
}


class _InputPageState extends State<InputPage> {

  int weight = 60;
  int age = 25;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... [AppBar and other widgets]
      body: Column(
        children: [
          // ... [Gender selection and height slider]
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Color(0xFF1D1E33),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('WEIGHT', style: kLabelTextStyle),
                        Text(
                          weight.toString(),
                          style: TextStyle(
                            fontSize: 50.0,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        // ... [Increment and decrement buttons]
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Color(0xFF1D1E33),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('AGE', style: kLabelTextStyle),
                        Text(
                          age.toString(),
                          style: TextStyle(
                            fontSize: 50.0,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        // ... [Increment and decrement buttons]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.pink,
            margin: EdgeInsets.only(top: 10.0),
            width: double.infinity,
            height: 80.0,
            child: Center(
              child: Text(
                'CALCULATE',
                style: TextStyle(
                  fontSize: 25.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ... [Within the calculate button's onTap]

onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => ResultPage(
bmiResult: calculateBMI(),
),
),
);
},
