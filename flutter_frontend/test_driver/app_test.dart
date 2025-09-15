import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_frontend/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('AI Object Counter Integration Tests', () {
    testWidgets('App launches and shows main navigation', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify app title is displayed
      expect(find.text('AI Object Counter'), findsOneWidget);
      
      // Verify main navigation tabs are present
      expect(find.text('Upload & Count'), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Monitoring'), findsOneWidget);
      expect(find.text('Few-Shot Learning'), findsOneWidget);
      expect(find.text('Image Generation'), findsOneWidget);
      expect(find.text('Performance Analysis'), findsOneWidget);
    });

    testWidgets('Upload page shows object type input with suggestions', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Should be on upload page by default
      expect(find.text('Upload Image for Object Counting'), findsOneWidget);
      
      // Find the object type input field
      final objectTypeField = find.byType(TextField);
      expect(objectTypeField, findsOneWidget);
      
      // Tap on the input field
      await tester.tap(objectTypeField);
      await tester.pumpAndSettle();
      
      // Type a partial object type
      await tester.enterText(objectTypeField, 'car');
      await tester.pumpAndSettle();
      
      // Should show suggestions
      expect(find.text('car'), findsWidgets);
    });

    testWidgets('Results page shows empty state initially', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to results page
      await tester.tap(find.text('Results'));
      await tester.pumpAndSettle();
      
      // Should show empty state
      expect(find.text('No Results Yet'), findsOneWidget);
      expect(find.text('Upload an image to see counting results here.'), findsOneWidget);
    });

    testWidgets('History page loads and shows empty state', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to history page
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      
      // Should show history page
      expect(find.text('Counting History'), findsOneWidget);
    });

    testWidgets('Monitoring page shows system metrics', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to monitoring page
      await tester.tap(find.text('Monitoring'));
      await tester.pumpAndSettle();
      
      // Should show monitoring page
      expect(find.text('AI System Monitor'), findsOneWidget);
    });

    testWidgets('Few-Shot Learning page loads', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to few-shot learning page
      await tester.tap(find.text('Few-Shot Learning'));
      await tester.pumpAndSettle();
      
      // Should show few-shot learning page
      expect(find.text('Few-Shot Learning'), findsOneWidget);
    });

    testWidgets('Image Generation page loads', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to image generation page
      await tester.tap(find.text('Image Generation'));
      await tester.pumpAndSettle();
      
      // Should show image generation page
      expect(find.text('AI Image Generation'), findsOneWidget);
    });

    testWidgets('Performance Analysis page loads', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to performance analysis page
      await tester.tap(find.text('Performance Analysis'));
      await tester.pumpAndSettle();
      
      // Should show performance analysis page
      expect(find.text('Performance Analysis'), findsOneWidget);
    });
  });
}
