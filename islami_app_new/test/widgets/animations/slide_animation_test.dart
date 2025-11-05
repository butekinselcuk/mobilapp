import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_new/widgets/animations/slide_animation.dart';

void main() {
  group('SlideAnimation Widget Tests', () {
    testWidgets('SlideAnimation renders child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideAnimation(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('SlideAnimation slides from right by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideAnimation(
              duration: Duration(milliseconds: 100),
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // İlk frame'de sağda olmalı
      await tester.pump();
      final slideTransition = tester.widget<SlideTransition>(find.byType(SlideTransition));
      expect(slideTransition.position.value.dx, equals(1.0));
      expect(slideTransition.position.value.dy, equals(0.0));
    });

    testWidgets('SlideAnimation slides from left when direction is left', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideAnimation(
              direction: SlideDirection.left,
              duration: Duration(milliseconds: 100),
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // İlk frame'de solda olmalı
      await tester.pump();
      final slideTransition = tester.widget<SlideTransition>(find.byType(SlideTransition));
      expect(slideTransition.position.value.dx, equals(-1.0));
      expect(slideTransition.position.value.dy, equals(0.0));
    });

    testWidgets('SlideAnimation slides from up when direction is up', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideAnimation(
              direction: SlideDirection.up,
              duration: Duration(milliseconds: 100),
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // İlk frame'de yukarıda olmalı
      await tester.pump();
      final slideTransition = tester.widget<SlideTransition>(find.byType(SlideTransition));
      expect(slideTransition.position.value.dx, equals(0.0));
      expect(slideTransition.position.value.dy, equals(-1.0));
    });

    testWidgets('SlideAnimation slides from down when direction is down', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideAnimation(
              direction: SlideDirection.down,
              duration: Duration(milliseconds: 100),
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // İlk frame'de aşağıda olmalı
      await tester.pump();
      final slideTransition = tester.widget<SlideTransition>(find.byType(SlideTransition));
      expect(slideTransition.position.value.dx, equals(0.0));
      expect(slideTransition.position.value.dy, equals(1.0));
    });

    testWidgets('SlideAnimation animates to center position', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideAnimation(
              duration: Duration(milliseconds: 100),
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // Animasyonu başlat ve tamamlanmasını bekle
      await tester.pumpAndSettle();

      // Son durumda merkez pozisyonda olmalı
      final slideTransition = tester.widget<SlideTransition>(find.byType(SlideTransition));
      expect(slideTransition.position.value.dx, equals(0.0));
      expect(slideTransition.position.value.dy, equals(0.0));
    });

    testWidgets('SlideAnimation respects delay parameter', (WidgetTester tester) async {
      const delay = Duration(milliseconds: 100);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideAnimation(
              delay: delay,
              duration: Duration(milliseconds: 100),
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // İlk frame
      await tester.pump();
      
      // Delay süresi boyunca başlangıç pozisyonunda kalmalı
      await tester.pump(Duration(milliseconds: 50));
      final slideTransition1 = tester.widget<SlideTransition>(find.byType(SlideTransition));
      expect(slideTransition1.position.value.dx, equals(1.0));
      
      // Delay sonrası animasyon tamamlanmalı
      await tester.pumpAndSettle();
      final slideTransition2 = tester.widget<SlideTransition>(find.byType(SlideTransition));
      expect(slideTransition2.position.value.dx, equals(0.0));
    });

    testWidgets('SlideAnimation uses custom curve', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideAnimation(
              curve: Curves.bounceIn,
              duration: Duration(milliseconds: 100),
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.byType(SlideAnimation), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('SlideAnimation with custom offset', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideAnimation(
              offset: 2.0,
              duration: Duration(milliseconds: 100),
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // İlk frame'de custom offset kullanmalı
      await tester.pump();
      final slideTransition = tester.widget<SlideTransition>(find.byType(SlideTransition));
      expect(slideTransition.position.value.dx, equals(2.0));
    });

    testWidgets('SlideAnimation disposes controller properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlideAnimation(
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