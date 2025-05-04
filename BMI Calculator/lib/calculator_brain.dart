import 'dart:math';

class CalculatorBrain {
  CalculatorBrain({required this.heightCm, required this.weight});

  final int heightCm;
  final int weight;

  double _bmi = 0;

  String calculateBMI() {
    _bmi = weight / pow(heightCm / 100, 2);
    return _bmi.toStringAsFixed(1);
  }

  String getResult() {
    if (_bmi >= 25) {
      return 'Overweight';
    } else if (_bmi > 18.5) {
      return 'Normal';
    } else {
      return 'Underweight';
    }
  }

  String getInterpretation() {
    if (_bmi >= 25) {
      return 'Try to exercise more and watch your diet.';
    } else if (_bmi >= 18.5) {
      return 'Great job! You have a normal body weight.';
    } else {
      return 'You might need to eat a bit more for a healthy weight.';
    }
  }
}
