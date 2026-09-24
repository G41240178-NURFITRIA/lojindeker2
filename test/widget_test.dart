import 'package:flutter_test/flutter_test.dart';
import 'package:d_care/features/auth/screens/login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('LoginScreen loads and displays role selector and login elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pump();

    // Verify role selector pills
    expect(find.text('Pasien'), findsOneWidget);
    expect(find.text('Dokter'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);

    // Verify Lupa password?
    expect(find.text('Lupa password?'), findsOneWidget);
  });
}
