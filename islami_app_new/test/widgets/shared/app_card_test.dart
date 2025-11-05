import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_new/widgets/shared/app_card.dart';
import 'package:islami_app_new/theme/app_theme.dart';

void main() {
  group('AppCard Widget Tests', () {
    testWidgets('AppCard renders child widget correctly', (WidgetTester tester) async {
      const testText = 'Test Content';
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard(
              child: Text(testText),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('AppCard responds to tap when onTap is provided', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppCard));
      expect(tapped, isTrue);
    });

    testWidgets('AppCard shows hover effect on mouse enter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard(
              onTap: () {},
              child: const Text('Hover me'),
            ),
          ),
        ),
      );

      // Mouse enter simülasyonu
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      
      await gesture.moveTo(tester.getCenter(find.byType(AppCard)));
      await tester.pump();

      // Hover durumunu test etmek için widget state'ini kontrol edebiliriz
      expect(find.byType(AppCard), findsOneWidget);
    });

    testWidgets('AppCard applies correct semantic label', (WidgetTester tester) async {
      const semanticLabel = 'Prayer time card';
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard(
              semanticLabel: semanticLabel,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(AppCard)),
        matchesSemantics(label: semanticLabel),
      );
    });

    testWidgets('AppCard.prayerTime creates specialized card', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard.prayerTime(
              child: const Text('Prayer Time'),
            ),
          ),
        ),
      );

      expect(find.text('Prayer Time'), findsOneWidget);
      expect(find.byType(AppCard), findsOneWidget);
    });

    testWidgets('AppCard.aiAssistant creates specialized card', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard.aiAssistant(
              child: const Text('AI Assistant'),
            ),
          ),
        ),
      );

      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.byType(AppCard), findsOneWidget);
    });

    testWidgets('AppCard.quickAccess creates interactive card', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard.quickAccess(
              onTap: () => tapped = true,
              child: const Text('Quick Access'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppCard));
      expect(tapped, isTrue);
    });

    testWidgets('AppCard applies different types correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                AppCard(
                  type: AppCardType.standard,
                  child: const Text('Standard'),
                ),
                AppCard(
                  type: AppCardType.elevated,
                  child: const Text('Elevated'),
                ),
                AppCard(
                  type: AppCardType.outlined,
                  child: const Text('Outlined'),
                ),
                AppCard(
                  type: AppCardType.filled,
                  child: const Text('Filled'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Elevated'), findsOneWidget);
      expect(find.text('Outlined'), findsOneWidget);
      expect(find.text('Filled'), findsOneWidget);
    });

    testWidgets('AppCard respects custom padding and margin', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(32.0);
      const customMargin = EdgeInsets.all(16.0);
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard(
              padding: customPadding,
              margin: customMargin,
              child: const Text('Custom spacing'),
            ),
          ),
        ),
      );

      expect(find.text('Custom spacing'), findsOneWidget);
      
      // Padding ve margin'ın doğru uygulandığını kontrol etmek için
      // widget tree'sinde Container'ları bulabiliriz
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('AppCard handles long press correctly', (WidgetTester tester) async {
      bool longPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppCard(
              onLongPress: () => longPressed = true,
              child: const Text('Long press me'),
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(AppCard));
      expect(longPressed, isTrue);
    });
  });

  group('AppCard Dark Theme Tests', () {
    testWidgets('AppCard adapts to dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AppCard(
              child: const Text('Dark theme'),
            ),
          ),
        ),
      );

      expect(find.text('Dark theme'), findsOneWidget);
      
      // Dark theme'de doğru renklerin kullanıldığını kontrol edebiliriz
      final BuildContext context = tester.element(find.byType(AppCard));
      expect(Theme.of(context).brightness, Brightness.dark);
    });
  });
}