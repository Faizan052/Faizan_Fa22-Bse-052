import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_app/main.dart';

void main() {
  testWidgets('Medicine CRUD Test', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(MyApp());

    // Verify the app starts with the 'Add Medicine' button
    expect(find.text('Add Medicine'), findsOneWidget);

    // Tap the 'Add Medicine' button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify the Add Medicine dialog appears
    expect(find.text('Add Medicine'), findsOneWidget);

    // Enter a new medicine name and price
    await tester.enterText(find.byType(TextField).at(0), 'Aspirin');
    await tester.enterText(find.byType(TextField).at(1), '100');
    await tester.enterText(find.byType(TextField).at(2), '50');
    await tester.enterText(find.byType(TextField).at(3), '10');

    // Submit the form by tapping 'Add' button
    await tester.tap(find.text('Add'));
    await tester.pump();

    // Verify the medicine is added to the list
    expect(find.text('Aspirin'), findsOneWidget);
    expect(find.text('Sale: \$100.0 | Purchase: \$50.0 | Qty: 10'), findsOneWidget);
  });
}
