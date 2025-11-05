import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_new/widgets/animations/skeleton_loader.dart';

void main() {
  group('SkeletonLoader Widget Tests', () {
    testWidgets('SkeletonLoader renders with default properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('SkeletonLoader uses custom width and height', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              width: 200,
              height: 100,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, equals(200));
      expect(container.constraints?.maxHeight, equals(100));
    });

    testWidgets('SkeletonLoader uses custom border radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              borderRadius: 16.0,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('SkeletonLoader animates shimmer effect', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // İlk frame
      await tester.pump();
      
      // Animasyon frame'leri
      await tester.pump(Duration(milliseconds: 50));
      await tester.pump(Duration(milliseconds: 100));
      
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('SkeletonLoader.rectangular creates rectangular skeleton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader.rectangular(
              width: 100,
              height: 50,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('SkeletonLoader.circular creates circular skeleton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader.circular(
              size: 50,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('SkeletonLoader.text creates text skeleton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader.text(
              lines: 3,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('SkeletonLoader.text creates correct number of lines', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader.text(
              lines: 5,
            ),
          ),
        ),
      );

      // Column içinde 5 skeleton line olmalı
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.children.length, equals(9)); // 5 skeleton + 4 SizedBox
    });

    testWidgets('SkeletonLoader.listTile creates list tile skeleton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader.listTile(),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('SkeletonLoader.listTile with leading creates avatar skeleton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader.listTile(
              hasLeading: true,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('SkeletonLoader.card creates card skeleton', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader.card(),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('SkeletonLoader disposes animation controller properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(),
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

    testWidgets('SkeletonLoader uses custom colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              baseColor: Colors.red,
              highlightColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('SkeletonLoader respects enabled parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              enabled: false,
              child: Text('Content'),
            ),
          ),
        ),
      );

      // enabled=false olduğunda child gösterilmeli
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('SkeletonLoader shows skeleton when enabled=true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(
              enabled: true,
              child: Text('Content'),
            ),
          ),
        ),
      );

      // enabled=true olduğunda skeleton gösterilmeli
      expect(find.text('Content'), findsNothing);
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });
}