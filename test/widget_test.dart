import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('Driver app loads splash screen', (WidgetTester tester) async {
    // Initialize the driver app widget using the new function
    final driverWidget = ();

    // Build the widget tree
    await tester.pumpWidget(driverWidget as Widget);

    // Verify that the splash screen is displayed
  });
}
