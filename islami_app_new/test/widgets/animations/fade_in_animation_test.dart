import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_new/widgets/animations/fade_in_animation.dart';

void main() {
  group('FadeInAnimation Widget Tests', () {
    testWidgets('FadeInAnimation renders child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FadeInAnimation(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('FadeInAnimation starts with opacity 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FadeInAnimation(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // İlk frame'de opacity 0 olmalı
      final fadeTransition = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fadeTransition.opacity.value, equals(0.0));
    });

    testWidgets('FadeInAnimation animates to opacity 1', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FadeInAnimation(
              duration: Duration(milliseconds: 100),
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // Animasyonu başlat
      await tester.pump();
      
      // Animasyon tamamlanana kadar bekle
      await tester.pumpAndSettle();

      // Son durumda opacity 1 olmalı
      final fadeTransition = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fadeTransition.opacity.value, equals(1.0));
    });

    testWidgets('FadeInAnimation respects custom duration', (WidgetTester tester) async {
      const customDuration = Duration(milliseconds: 500);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FadeInAnimation(
              duration: customDuration,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // Animasyonu başlat
      await tester.pump();
      
      // Yarı süre sonra opacity 0 ile 1 arasında olmalı
      await tester.pump(Duration(milliseconds: 250));
      final fadeTransition = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fadeTransition.opacity.value, greaterThan(0.0));
      expect(fadeTransition.opacity.value, lessThan(1.0));
    });

    testWidgets('FadeInAnimation respects delay parameter', (WidgetTester tester) async {
      const delay = Duration(milliseconds: 100);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FadeInAnimation(
              delay: delay,
              duration: Duration(milliseconds: 100),
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // İlk frame
      await tester.pump();
      
      // Delay süresi boyunca opacity 0 kalmalı
      await tester.pump(Duration(milliseconds: 50));
      final fadeTransition1 = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fadeTransition1.opacity.value, equals(0.0));
      
      // Delay sonrası animasyon başlamalı
      await tester.pumpAndSettle();
      final fadeTransition2 = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fadeTransition2.opacity.value, equals(1.0));
    });

    testWidgets('FadeInAnimation uses custom curve', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FadeInAnimation(
              curve: Curves.bounceIn,
              duration: Duration(milliseconds: 100),
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.byType(FadeInAnimation), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('FadeInAnimation disposes controller properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FadeInAnimation(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // Widget'ı kaldır
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );

      // Hata olmamalı (controller dispose edilmiş olmalı)
      expect(tester.takeException(), isNull);
    });
  });
}