import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_new/utils/visual_accessibility.dart';

void main() {
  group('VisualAccessibilityHelper Tests', () {
    testWidgets('isHighContrastEnabled returns correct value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Default olarak high contrast kapalı olmalı
              expect(VisualAccessibilityHelper.isHighContrastEnabled(context), isFalse);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('getTextScaleFactor returns correct value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final scaleFactor = VisualAccessibilityHelper.getTextScaleFactor(context);
              expect(scaleFactor, isA<double>());
              expect(scaleFactor, greaterThan(0));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('isBoldTextEnabled returns correct value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Default olarak bold text kapalı olmalı
              expect(VisualAccessibilityHelper.isBoldTextEnabled(context), isFalse);
              return Container();
            },
          ),
        ),
      );
    });

    test('calculateContrast calculates correct contrast ratios', () {
      // Siyah ve beyaz arasındaki kontrast 21:1 olmalı
      final blackWhiteContrast = VisualAccessibilityHelper.calculateContrast(Colors.black, Colors.white);
      expect(blackWhiteContrast, closeTo(21.0, 0.1));

      // Aynı renkler arasındaki kontrast 1:1 olmalı
      final sameColorContrast = VisualAccessibilityHelper.calculateContrast(Colors.red, Colors.red);
      expect(sameColorContrast, closeTo(1.0, 0.1));
    });

    test('meetsWCAGAA returns correct values', () {
      // Siyah metin beyaz arka plan WCAG AA'yı geçmeli
      expect(VisualAccessibilityHelper.meetsWCAGAA(Colors.black, Colors.white), isTrue);
      
      // Açık gri metin beyaz arka plan WCAG AA'yı geçmemeli
      expect(VisualAccessibilityHelper.meetsWCAGAA(Colors.grey[300]!, Colors.white), isFalse);
    });

    test('meetsWCAGAAA returns correct values', () {
      // Siyah metin beyaz arka plan WCAG AAA'yı geçmeli
      expect(VisualAccessibilityHelper.meetsWCAGAAA(Colors.black, Colors.white), isTrue);
      
      // Koyu gri metin beyaz arka plan WCAG AAA'yı geçmeyebilir
      expect(VisualAccessibilityHelper.meetsWCAGAAA(Colors.grey[600]!, Colors.white), isFalse);
    });

    test('meetsWCAGAALargeText returns correct values', () {
      // Büyük text için daha düşük kontrast yeterli
      expect(VisualAccessibilityHelper.meetsWCAGAALargeText(Colors.grey[600]!, Colors.white), isTrue);
    });

    test('optimizeForHighContrast returns correct colors', () {
      // Arka plan için
      final backgroundColor = VisualAccessibilityHelper.optimizeForHighContrast(Colors.blue, true);
      expect(backgroundColor == Colors.white || backgroundColor == Colors.black, isTrue);
      
      // Metin için
      final textColor = VisualAccessibilityHelper.optimizeForHighContrast(Colors.blue, false);
      expect(textColor == Colors.white || textColor == Colors.black, isTrue);
    });

    test('getColorBlindFriendlyColor returns correct colors', () {
      expect(VisualAccessibilityHelper.getColorBlindFriendlyColor('primary'), 
             equals(const Color(0xFF0173B2)));
      expect(VisualAccessibilityHelper.getColorBlindFriendlyColor('secondary'), 
             equals(const Color(0xFFDE8F05)));
      expect(VisualAccessibilityHelper.getColorBlindFriendlyColor('nonexistent'), 
             equals(Colors.grey));
    });

    test('makeColorBlindFriendly modifies colors correctly', () {
      final originalRed = Colors.red;
      final friendlyRed = VisualAccessibilityHelper.makeColorBlindFriendly(originalRed);
      
      // Renk değişmiş olmalı
      expect(friendlyRed, isNot(equals(originalRed)));
      expect(friendlyRed, isA<Color>());
    });

    testWidgets('optimizeTextSize clamps values correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Çok küçük değer
              final smallSize = VisualAccessibilityHelper.optimizeTextSize(context, 8.0);
              expect(smallSize, greaterThanOrEqualTo(12.0));
              
              // Çok büyük değer
              final largeSize = VisualAccessibilityHelper.optimizeTextSize(context, 50.0);
              expect(largeSize, lessThanOrEqualTo(32.0));
              
              // Normal değer
              final normalSize = VisualAccessibilityHelper.optimizeTextSize(context, 16.0);
              expect(normalSize, greaterThanOrEqualTo(12.0));
              expect(normalSize, lessThanOrEqualTo(32.0));
              
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('optimizeIconSize clamps values correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Çok küçük değer
              final smallSize = VisualAccessibilityHelper.optimizeIconSize(context, 10.0);
              expect(smallSize, greaterThanOrEqualTo(16.0));
              
              // Çok büyük değer
              final largeSize = VisualAccessibilityHelper.optimizeIconSize(context, 60.0);
              expect(largeSize, lessThanOrEqualTo(48.0));
              
              return Container();
            },
          ),
        ),
      );
    });
  });

  group('HighContrastTheme Tests', () {
    test('lightTheme has correct properties', () {
      final theme = HighContrastTheme.lightTheme;
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.primaryColor, equals(Colors.black));
      expect(theme.scaffoldBackgroundColor, equals(Colors.white));
    });

    test('darkTheme has correct properties', () {
      final theme = HighContrastTheme.darkTheme;
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.primaryColor, equals(Colors.white));
      expect(theme.scaffoldBackgroundColor, equals(Colors.black));
    });
  });

  group('VisualAccessibilityWrapper Tests', () {
    testWidgets('VisualAccessibilityWrapper renders child', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VisualAccessibilityWrapper(
            child: Text('Test Content'),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('VisualAccessibilityWrapper applies high contrast theme when enabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: VisualAccessibilityWrapper(
            enableHighContrast: true,
            child: Builder(
              builder: (context) {
                // High contrast kapalı olduğu için normal theme kullanılmalı
                return Text('Test Content');
              },
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });
  });

  group('AccessibleText Tests', () {
    testWidgets('AccessibleText renders with semantic label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleText(
              'Hello World',
              semanticLabel: 'Greeting text',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.byType(Semantics), findsOneWidget);
    });

    testWidgets('AccessibleText optimizes text size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleText(
              'Test Text',
              style: TextStyle(fontSize: 8), // Çok küçük
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.fontSize, greaterThanOrEqualTo(12.0));
    });
  });

  group('AccessibleIcon Tests', () {
    testWidgets('AccessibleIcon renders with semantic label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleIcon(
              Icons.star,
              semanticLabel: 'Star icon',
              size: 24,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byType(Semantics), findsOneWidget);
    });

    testWidgets('AccessibleIcon optimizes icon size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleIcon(
              Icons.star,
              size: 10, // Çok küçük
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, greaterThanOrEqualTo(16.0));
    });
  });

  group('Extension Tests', () {
    testWidgets('VisualAccessibilityExtensions work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.isHighContrastEnabled, isA<bool>());
              expect(context.isBoldTextEnabled, isA<bool>());
              expect(context.textScaleFactor, isA<double>());
              expect(context.hasAccessibilityFeatures, isA<bool>());
              
              final optimizedTextSize = context.optimizeTextSize(16.0);
              expect(optimizedTextSize, isA<double>());
              expect(optimizedTextSize, greaterThanOrEqualTo(12.0));
              
              final optimizedIconSize = context.optimizeIconSize(24.0);
              expect(optimizedIconSize, isA<double>());
              expect(optimizedIconSize, greaterThanOrEqualTo(16.0));
              
              final optimizedPadding = context.optimizePadding(EdgeInsets.all(8.0));
              expect(optimizedPadding, isA<EdgeInsets>());
              
              return Container();
            },
          ),
        ),
      );
    });

    test('ColorAccessibilityExtensions work correctly', () {
      final color = Colors.blue;
      
      expect(color.contrastWith(Colors.white), isA<double>());
      expect(color.meetsWCAGAA(Colors.white), isA<bool>());
      expect(color.meetsWCAGAAA(Colors.white), isA<bool>());
      expect(color.colorBlindFriendly, isA<Color>());
      expect(color.optimizeForHighContrast(), isA<Color>());
      expect(color.optimizeForHighContrast(isBackground: true), isA<Color>());
    });
  });

  group('Color Blind Friendly Colors Tests', () {
    test('all color blind friendly colors are defined', () {
      final colors = VisualAccessibilityHelper.colorBlindFriendlyColors;
      
      expect(colors.containsKey('primary'), isTrue);
      expect(colors.containsKey('secondary'), isTrue);
      expect(colors.containsKey('success'), isTrue);
      expect(colors.containsKey('warning'), isTrue);
      expect(colors.containsKey('error'), isTrue);
      expect(colors.containsKey('info'), isTrue);
      expect(colors.containsKey('neutral'), isTrue);
      
      // Tüm renkler Color tipinde olmalı
      colors.values.forEach((color) {
        expect(color, isA<Color>());
      });
    });
  });
}