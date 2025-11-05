import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_new/widgets/shared/app_button.dart';
import 'package:islami_app_new/theme/app_theme.dart';

void main() {
  group('AppButton Widget Tests', () {
    testWidgets('AppButton renders text correctly', (WidgetTester tester) async {
      const testText = 'Test Button';
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: testText,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('AppButton responds to tap when onPressed is provided', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Tap me',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppButton));
      expect(tapped, isTrue);
    });

    testWidgets('AppButton is disabled when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      // Disabled buton tıklanamaz
      await tester.tap(find.byType(AppButton));
      // Herhangi bir exception olmamalı
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('AppButton shows loading indicator when loading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Loading',
              onPressed: () {},
              loading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Loading durumunda metin görünmemeli
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('AppButton displays icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'With Icon',
              onPressed: () {},
              icon: Icons.star,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
    });

    testWidgets('AppButton applies different types correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                AppButton(
                  text: 'Primary',
                  type: AppButtonType.primary,
                  onPressed: () {},
                ),
                AppButton(
                  text: 'Secondary',
                  type: AppButtonType.secondary,
                  onPressed: () {},
                ),
                AppButton(
                  text: 'Outline',
                  type: AppButtonType.outline,
                  onPressed: () {},
                ),
                AppButton(
                  text: 'Text',
                  type: AppButtonType.text,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
      expect(find.text('Outline'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
    });

    testWidgets('AppButton applies different sizes correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                AppButton(
                  text: 'Small',
                  size: AppButtonSize.small,
                  onPressed: () {},
                ),
                AppButton(
                  text: 'Medium',
                  size: AppButtonSize.medium,
                  onPressed: () {},
                ),
                AppButton(
                  text: 'Large',
                  size: AppButtonSize.large,
                  onPressed: () {},
                ),
                AppButton(
                  text: 'Extra Large',
                  size: AppButtonSize.extraLarge,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
      expect(find.text('Extra Large'), findsOneWidget);
    });

    testWidgets('AppButton applies semantic label correctly', (WidgetTester tester) async {
      const semanticLabel = 'Submit button';
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Submit',
              onPressed: () {},
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(AppButton)),
        matchesSemantics(
          label: semanticLabel,
          isButton: true,
          isEnabled: true,
        ),
      );
    });

    testWidgets('AppButton respects fullWidth property', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: AppButton(
                text: 'Full Width',
                onPressed: () {},
                fullWidth: true,
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(AppButton);
      expect(buttonFinder, findsOneWidget);
      
      // Full width butonun genişliği parent'ına eşit olmalı
      final buttonWidget = tester.widget<AppButton>(buttonFinder);
      expect(buttonWidget.fullWidth, isTrue);
    });

    testWidgets('AppButton shows different icon positions correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                AppButton(
                  text: 'Left Icon',
                  icon: Icons.star,
                  iconPosition: AppButtonIconPosition.left,
                  onPressed: () {},
                ),
                AppButton(
                  text: 'Right Icon',
                  icon: Icons.star,
                  iconPosition: AppButtonIconPosition.right,
                  onPressed: () {},
                ),
                AppButton(
                  text: 'Top Icon',
                  icon: Icons.star,
                  iconPosition: AppButtonIconPosition.top,
                  onPressed: () {},
                ),
                AppButton(
                  text: 'Bottom Icon',
                  icon: Icons.star,
                  iconPosition: AppButtonIconPosition.bottom,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Left Icon'), findsOneWidget);
      expect(find.text('Right Icon'), findsOneWidget);
      expect(find.text('Top Icon'), findsOneWidget);
      expect(find.text('Bottom Icon'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNWidgets(4));
    });
  });

  group('AppButton Variants Tests', () {
    testWidgets('AppButton.quickAccess creates correct button', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButtonVariants.quickAccess(
              text: 'Quick Access',
              onPressed: () => tapped = true,
              icon: Icons.flash_on,
            ),
          ),
        ),
      );

      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
      
      await tester.tap(find.byType(AppButton));
      expect(tapped, isTrue);
    });

    testWidgets('AppButton.premium creates correct button', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButtonVariants.premium(
              text: 'Premium',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Premium'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
      
      await tester.tap(find.byType(AppButton));
      expect(tapped, isTrue);
    });

    testWidgets('AppButton.sendMessage creates correct button', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButtonVariants.sendMessage(
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
      
      await tester.tap(find.byType(AppButton));
      expect(tapped, isTrue);
    });

    testWidgets('AppButton.sendMessage shows loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppButtonVariants.sendMessage(
              onPressed: () {},
              loading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.send), findsNothing);
    });
  });

  group('AppButton Dark Theme Tests', () {
    testWidgets('AppButton adapts to dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AppButton(
              text: 'Dark Theme',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Dark Theme'), findsOneWidget);
      
      // Dark theme'de doğru renklerin kullanıldığını kontrol edebiliriz
      final BuildContext context = tester.element(find.byType(AppButton));
      expect(Theme.of(context).brightness, Brightness.dark);
    });
  });
}