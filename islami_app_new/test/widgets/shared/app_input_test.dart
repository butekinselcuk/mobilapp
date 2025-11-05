import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_new/widgets/shared/app_input.dart';
import 'package:islami_app_new/theme/app_theme.dart';

void main() {
  group('AppInput Widget Tests', () {
    testWidgets('AppInput renders correctly with basic properties', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInput(
              controller: controller,
              label: 'Test Label',
              hint: 'Test Hint',
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('Test Hint'), findsOneWidget);
    });

    testWidgets('AppInput responds to text input', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInput(
              controller: controller,
              label: 'Test Input',
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(AppInput), 'Test text');
      expect(controller.text, 'Test text');
    });

    testWidgets('AppInput shows error text when provided', (WidgetTester tester) async {
      const errorText = 'This is an error';
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInput(
              label: 'Test Input',
              errorText: errorText,
            ),
          ),
        ),
      );

      expect(find.text(errorText), findsOneWidget);
    });

    testWidgets('AppInput shows prefix icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInput(
              label: 'Test Input',
              prefixIcon: Icons.email,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('AppInput shows suffix icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInput(
              label: 'Test Input',
              suffixIcon: Icons.search,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('AppInput toggles password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInput(
              label: 'Password',
              obscureText: true,
            ),
          ),
        ),
      );

      // Visibility toggle button should be present
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      
      // Tap the visibility toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();
      
      // Icon should change to visibility_off
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('AppInput calls onChanged when text changes', (WidgetTester tester) async {
      String? changedValue;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInput(
              label: 'Test Input',
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(AppInput), 'New text');
      expect(changedValue, 'New text');
    });

    testWidgets('AppInput calls onSubmitted when submitted', (WidgetTester tester) async {
      String? submittedValue;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInput(
              label: 'Test Input',
              onSubmitted: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(AppInput), 'Submit text');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(submittedValue, 'Submit text');
    });

    testWidgets('AppInput applies different types correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                AppInput(
                  label: 'Standard',
                  type: AppInputType.standard,
                ),
                AppInput(
                  label: 'Filled',
                  type: AppInputType.filled,
                ),
                AppInput(
                  label: 'Outlined',
                  type: AppInputType.outlined,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Filled'), findsOneWidget);
      expect(find.text('Outlined'), findsOneWidget);
    });

    testWidgets('AppInput applies different sizes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                AppInput(
                  label: 'Small',
                  size: AppInputSize.small,
                ),
                AppInput(
                  label: 'Medium',
                  size: AppInputSize.medium,
                ),
                AppInput(
                  label: 'Large',
                  size: AppInputSize.large,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
    });

    testWidgets('AppInput respects enabled property', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInput(
              label: 'Disabled Input',
              enabled: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('AppInput respects readOnly property', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInput(
              label: 'Read Only Input',
              readOnly: true,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.readOnly, isTrue);
    });

    testWidgets('AppInput applies semantic label correctly', (WidgetTester tester) async {
      const semanticLabel = 'Email input field';
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInput(
              label: 'Email',
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(AppInput)),
        matchesSemantics(
          label: semanticLabel,
          isTextField: true,
        ),
      );
    });
  });

  group('AppInput Variants Tests', () {
    testWidgets('AppInput.search creates search input', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInputVariants.search(
              controller: controller,
              hint: 'Search here',
            ),
          ),
        ),
      );

      expect(find.text('Search here'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('AppInput.email creates email input', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInputVariants.email(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('E-posta'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('AppInput.password creates password input', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInputVariants.password(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Şifre'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('AppInput.multiline creates multiline input', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInputVariants.multiline(
              controller: controller,
              label: 'Description',
            ),
          ),
        ),
      );

      expect(find.text('Description'), findsOneWidget);
      
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.maxLines, 4);
      expect(textField.minLines, 2);
    });

    testWidgets('AppInput.phone creates phone input', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInputVariants.phone(
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('Telefon'), findsOneWidget);
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
    });
  });

  group('AppInput Validation Tests', () {
    testWidgets('AppInput validates email format', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInputVariants.email(
              controller: controller,
            ),
          ),
        ),
      );

      // Enter invalid email
      await tester.enterText(find.byType(AppInput), 'invalid-email');
      await tester.pump();

      // Should show validation error
      expect(find.text('Geçerli bir e-posta adresi girin'), findsOneWidget);
    });

    testWidgets('AppInput validates password length', (WidgetTester tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppInputVariants.password(
              controller: controller,
            ),
          ),
        ),
      );

      // Enter short password
      await tester.enterText(find.byType(AppInput), '123');
      await tester.pump();

      // Should show validation error
      expect(find.text('Şifre en az 6 karakter olmalı'), findsOneWidget);
    });
  });

  group('AppInput Dark Theme Tests', () {
    testWidgets('AppInput adapts to dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AppInput(
              label: 'Dark Theme Input',
            ),
          ),
        ),
      );

      expect(find.text('Dark Theme Input'), findsOneWidget);
      
      // Dark theme'de doğru renklerin kullanıldığını kontrol edebiliriz
      final BuildContext context = tester.element(find.byType(AppInput));
      expect(Theme.of(context).brightness, Brightness.dark);
    });
  });
}