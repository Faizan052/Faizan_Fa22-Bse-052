import 'package:flutter/material.dart';
import '../components/reusable_card.dart';
import '../components/icon_content.dart';
import '../constants.dart';
import 'results_page.dart';
import '../components/bottom_button.dart';
import '../components/round_icon_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../calculator_brain.dart';

enum Gender { male, female }

class InputPage extends StatefulWidget {
  @override
  _InputPageState createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  Gender? selectedGender;
  int heightCm = 180;
  int weight = 60;
  int age = 20;
  bool useFeetInches = false;
  int heightFeet = 5;
  int heightInches = 11;

  int get heightInCm {
    if (useFeetInches) {
      return ((heightFeet * 12 + heightInches) * 2.54).round();
    }
    return heightCm;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text('BMI CALCULATOR'),
    ),
    body: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Expanded(
        child: Row(
          children: <Widget>[
            Expanded(
              child: ReusableCard(
                color: selectedGender == Gender.male
                    ? kActiveCardColor
                    : kInactiveCardColor,
                cardChild: IconContent(
                  icon: FontAwesomeIcons.mars,
                  label: 'MALE',
                ),
                onPress: () {
                  setState(() {
                    selectedGender = Gender.male;
                  });
                },
              ),
            ),
            Expanded(
              child: ReusableCard(
                color: selectedGender == Gender.female
                    ? kActiveCardColor
                    : kInactiveCardColor,
                cardChild: IconContent(
                  icon: FontAwesomeIcons.venus,
                  label: 'FEMALE',
                ),
                onPress: () {
                  setState(() {
                    selectedGender = Gender.female;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: ReusableCard(
          color: kActiveCardColor,
          cardChild: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('HEIGHT', style: kLabelTextStyle),
              SwitchListTile(
                title: Text(
                  useFeetInches ? 'Feet/Inches' : 'Centimeters',
                  style: TextStyle(color: Colors.white70),
                ),
                value: useFeetInches,
                onChanged: (value) {
                  setState(() {
                    useFeetInches = value;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    useFeetInches
                        ? '$heightFeet ft $heightInches in'
                        : '$heightCm cm',
                    style: kNumberTextStyle,
                  ),
                ],
              ),
              Slider(
                value: useFeetInches
                    ? (heightFeet * 12 + heightInches).toDouble()
                    : heightCm.toDouble(),
                min: useFeetInches ? 36 : 120,
                max: useFeetInches ? 84 : 220,
                onChanged: (double newValue) {
                  setState(() {
                    if (useFeetInches) {
                      int totalInches = newValue.round();
                      heightFeet = totalInches ~/ 12;
                      heightInches = totalInches % 12;
                    } else {
                      heightCm = newValue.round();
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
      Expanded(
        child: Row(
          children: <Widget>[
            Expanded(
              child: ReusableCard(
                color: kActiveCardColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('WEIGHT', style: kLabelTextStyle),
                    Text(weight.toString(), style: kNumberTextStyle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        RoundIconButton(
                          icon: FontAwesomeIcons.minus,
                          onPressed: () {
                            setState(() {
                              weight--;
                            });
                          },
                        ),
                        SizedBox(width: 10.0),
                        RoundIconButton(
                          icon: FontAwesomeIcons.plus,
                          onPressed: () {
                            setState(() {
                              weight++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ReusableCard(
                color: kActiveCardColor,
                cardChild: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('AGE', style: kLabelTextStyle),
                    Text(age.toString(), style: kNumberTextStyle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        RoundIconButton(
                          icon: FontAwesomeIcons.minus,
                          onPressed: () {
                            setState(() {
                              age--;
                            });
                          },
                        ),
                        SizedBox(width: 10.0),
                        RoundIconButton(
                          icon: FontAwesomeIcons.plus,
                          onPressed: () {
                            setState(() {
                              age++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      BottomButton(
        buttonTitle: 'CALCULATE',
        onTap: () {
          CalculatorBrain calc =
          CalculatorBrain(heightCm: heightInCm, weight: weight);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ResultsPage(
                bmiResult: calc.calculateBMI(),
                resultText: calc.getResult(),
                interpretation: calc.getInterpretation(),
              ),
              transitionsBuilder:
                  (_, Animation<double> animation, __, Widget child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
      ),
    ],
    ),
    );
  }
}
