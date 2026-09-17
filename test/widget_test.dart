import 'package:flutter_test/flutter_test.dart';
import 'package:d_care/main.dart';

void main() {
  testWidgets('Diabetes Care login screen loads and displays essential elements', (WidgetTester tester) async {
    await tester.pumpWidget(const DCareApp());
    await tester.pump();

    // Verify role selector pills
    expect(find.text('Pasien'), findsOneWidget);
    expect(find.text('Dokter'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);

    // Verify inputs
    expect(find.text('Pasien01'), findsOneWidget);

    // Verify Log In button and Forgot Password text
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Lupa password?'), findsOneWidget);

    // Tap Dokter role
    await tester.tap(find.text('Dokter'));
    await tester.pump();
    expect(find.text('Dr. Sarah'), findsOneWidget);
  });
}
