import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parking/main.dart';
import 'package:parking/presentation/widgets/logo_widget.dart';

void main() {
  testWidgets('Parking App splash screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ParkingApp());

    // Verify that our app starts with the splash screen.
    expect(find.text('Parking App'), findsOneWidget);
    expect(find.text('Smart Parking Solutions'), findsOneWidget);
    expect(find.byType(LogoWidget), findsOneWidget);
  });

  testWidgets('Login screen navigation test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ParkingApp());

    // Wait for splash screen navigation to complete
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify that we're now on the login screen
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and Password fields
  });

  testWidgets('Signup screen navigation test', (WidgetTester tester) async {
    // Build our app and navigate to login first
    await tester.pumpWidget(const ParkingApp());
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Tap the Sign Up link
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Verify that we're now on the signup screen
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign up to get started'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4)); // Name, Email, Password, Confirm Password fields
  });

  testWidgets('Responsive design test - Login screen', (WidgetTester tester) async {
    // Set different screen sizes to test responsiveness
    tester.binding.setSurfaceSize(const Size(400, 800)); // Mobile
    
    await tester.pumpWidget(const ParkingApp());
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify layout adapts to screen size
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(Column), findsOneWidget);
    
    // Reset to default size
    tester.binding.setSurfaceSize(null);
  });
}
