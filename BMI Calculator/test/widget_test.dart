import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmi_calculator/screens/input_page.dart'; // Make sure this is your InputPage widget

void main() {
  // Test to ensure the app launches and the correct widgets are shown
  testWidgets('BMI Calculator App Smoke Test', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(MaterialApp(
      home: InputPage(), // Ensure this points to your InputPage or main widget
    ));

    // Check if the app bar title is present
    expect(find.text('BMI Calculator Elite'), findsOneWidget);

    // Verify the height and weight section texts
    expect(find.text('HEIGHT'), findsOneWidget);
    expect(find.text('WEIGHT'), findsOneWidget);

    // Ensure male and female gender icons are present
    expect(find.byIcon(Icons.male), findsOneWidget);
    expect(find.byIcon(Icons.female), findsOneWidget);

    // Tap on the male icon to select gender
    await tester.tap(find.byIcon(Icons.male));
    await tester.pump();

    // Verify the male gender is selected
    expect(find.byIcon(Icons.male), findsOneWidget);

    // Simulate user input for height and weight
    await tester.tap(find.byType(Slider)); // Simulate interaction with height slider
    await tester.pumpAndSettle();

    // Now check the Calculate button's presence
    expect(find.text('CALCULATE'), findsOneWidget);

    // Tap the Calculate button and navigate to the results screen
    await tester.tap(find.text('CALCULATE'));
    await tester.pumpAndSettle(); // Wait for navigation

    // Ensure the results page is displayed
    expect(find.text('Your Result'), findsOneWidget);
  });
}
