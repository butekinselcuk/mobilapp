import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_new/utils/accessibility.dart';

void main() {
  group('AccessibilityHelper Tests', () {
    testWidgets('createSemanticLabel creates proper labels', (WidgetTester tester) async {
      final label = AccessibilityHelper.createSemanticLabel(
        action: 'düğme',
        item: 'Kaydet',
        state: 'etkin',
        hint: 'formu kaydetmek için tıklayın',
      );

      expect(label, 'Kaydet, düğme, etkin, formu kaydetmek için tıklayın');
    });

    testWidgets('buttonLabel creates proper button labels', (WidgetTester tester) async {
      final label = AccessibilityHelper.buttonLabel(
        text: 'Gönder',
        state: 'yükleniyor',
        hint: 'mesajı göndermek için tıklayın',
      );

      expect(label, 'Gönder, düğme, yükleniyor, mesajı göndermek için tıklayın');
    });

    testWidgets('inputLabel creates proper input labels', (WidgetTester tester) async {
      final label = AccessibilityHelper.inputLabel(
        fieldName: 'E-posta',
        isRequired: true,
        currentValue: 'test@example.com',
        hint: 'geçerli bir e-posta adresi girin',
      );

      expect(label, 'E-posta, metin alanı, zorunlu, geçerli bir e-posta adresi girin');
    });

    testWidgets('cardLabel creates proper card labels', (WidgetTester tester) async {
      final label = AccessibilityHelper.cardLabel(
        title: 'Namaz Vakitleri',
        subtitle: 'Bugünkü namaz saatleri',
        action: 'detayları görmek için tıklayın',
      );

      expect(label, 'Namaz Vakitleri, Bugünkü namaz saatleri, detayları görmek için tıklayın');
    });

    testWidgets('progressLabel creates proper progress labels', (WidgetTester tester) async {
      final label = AccessibilityHelper.progressLabel(
        task: 'Dosya yükleme',
        progress: 0.75,
      );

      expect(label, 'Dosya yükleme, %75 tamamlandı');
    });

    testWidgets('tabLabel creates proper tab labels', (WidgetTester tester) async {
      final label = AccessibilityHelper.tabLabel(
        tabName: 'Ana Sayfa',
        currentIndex: 0,
        totalTabs: 5,
        isSelected: true,
      );

      expect(label, 'Ana Sayfa sekmesi, 1 / 5, seçili');
    });

    testWidgets('linkLabel creates proper link labels', (WidgetTester tester) async {
      final label = AccessibilityHelper.linkLabel(
        text: 'Daha fazla bilgi',
        destination: 'Yardım',
      );

      expect(label, 'Daha fazla bilgi, bağlantı, Yardım sayfasına git');
    });
  });

  group('AccessibleWidget Tests', () {
    testWidgets('AccessibleWidget renders with semantic label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleWidget(
              semanticLabel: 'Test widget',
              hint: 'Bu bir test widget\'ıdır',
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AccessibleWidget), findsOneWidget);
      expect(find.byType(Semantics), findsOneWidget);
    });

    testWidgets('AccessibleWidget handles tap events', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleWidget(
              semanticLabel: 'Tappable widget',
              onTap: () => tapped = true,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AccessibleWidget));
      expect(tapped, isTrue);
    });

    testWidgets('AccessibleWidget excludes semantics when requested', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleWidget(
              semanticLabel: 'Test widget',
              excludeSemantics: true,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AccessibleWidget), findsOneWidget);
      // Semantics should be excluded
      expect(find.byType(Semantics), findsNothing);
    });
  });

  group('AccessibleButton Tests', () {
    testWidgets('AccessibleButton renders with semantic label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              semanticLabel: 'Test button',
              tooltip: 'Bu bir test butonu',
              onPressed: () {},
              child: Text('Test'),
            ),
          ),
        ),
      );

      expect(find.byType(AccessibleButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('AccessibleButton handles press events', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              semanticLabel: 'Test button',
              onPressed: () => pressed = true,
              child: Text('Press me'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, isTrue);
    });

    testWidgets('AccessibleButton is disabled when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              semanticLabel: 'Disabled button',
              onPressed: null,
              child: Text('Disabled'),
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });

  group('AccessibleCard Tests', () {
    testWidgets('AccessibleCard renders with semantic label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleCard(
              semanticLabel: 'Test card',
              tooltip: 'Bu bir test kartı',
              child: Text('Card content'),
            ),
          ),
        ),
      );

      expect(find.byType(AccessibleCard), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('AccessibleCard handles tap events', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleCard(
              semanticLabel: 'Tappable card',
              onTap: () => tapped = true,
              child: Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('AccessibleCard shows selected state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleCard(
              semanticLabel: 'Selected card',
              selected: true,
              child: Text('Selected'),
            ),
          ),
        ),
      );

      expect(find.byType(AccessibleCard), findsOneWidget);
    });
  });

  group('AccessibleListTile Tests', () {
    testWidgets('AccessibleListTile renders with semantic label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleListTile(
              semanticLabel: 'Test list item',
              leading: Icon(Icons.star),
              title: Text('Title'),
              subtitle: Text('Subtitle'),
              trailing: Icon(Icons.arrow_forward),
            ),
          ),
        ),
      );

      expect(find.byType(AccessibleListTile), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('AccessibleListTile handles tap events', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleListTile(
              semanticLabel: 'Tappable list item',
              title: Text('Tap me'),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });
  });

  group('FocusManager Tests', () {
    test('getFocusNode creates and returns focus nodes', () {
      final node1 = FocusManager.getFocusNode('test1');
      final node2 = FocusManager.getFocusNode('test2');
      final node1Again = FocusManager.getFocusNode('test1');

      expect(node1, isNotNull);
      expect(node2, isNotNull);
      expect(node1, same(node1Again)); // Should return the same instance
      expect(node1, isNot(same(node2))); // Should be different instances

      // Cleanup
      FocusManager.disposeAll();
    });

    test('createFocusChain creates list of focus nodes', () {
      final chain = FocusManager.createFocusChain(['node1', 'node2', 'node3']);

      expect(chain, hasLength(3));
      expect(chain[0], isNotNull);
      expect(chain[1], isNotNull);
      expect(chain[2], isNotNull);

      // Cleanup
      FocusManager.disposeAll();
    });

    test('disposeFocusNode removes specific node', () {
      FocusManager.getFocusNode('test');
      FocusManager.disposeFocusNode('test');

      // Getting the same key should create a new node
      final newNode = FocusManager.getFocusNode('test');
      expect(newNode, isNotNull);

      // Cleanup
      FocusManager.disposeAll();
    });
  });

  group('AccessibilityTestHelper Tests', () {
    test('hasValidSemanticLabel validates labels correctly', () {
      expect(AccessibilityTestHelper.hasValidSemanticLabel(null), isFalse);
      expect(AccessibilityTestHelper.hasValidSemanticLabel(''), isFalse);
      expect(AccessibilityTestHelper.hasValidSemanticLabel('ab'), isFalse);
      expect(AccessibilityTestHelper.hasValidSemanticLabel('abc'), isTrue);
      expect(AccessibilityTestHelper.hasValidSemanticLabel('Valid label'), isTrue);
    });

    test('hasValidFocusOrder validates focus chains', () {
      expect(AccessibilityTestHelper.hasValidFocusOrder([]), isFalse);
      expect(AccessibilityTestHelper.hasValidFocusOrder([FocusNode()]), isTrue);
      expect(AccessibilityTestHelper.hasValidFocusOrder([FocusNode(), FocusNode()]), isTrue);
    });

    test('isAccessible returns true for placeholder implementation', () {
      expect(AccessibilityTestHelper.isAccessible(Container()), isTrue);
    });
  });

  group('AccessibilityExtensions Tests', () {
    testWidgets('Context extensions work correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // These methods should not throw errors
              expect(() => context.announceToScreenReader('Test message'), returnsNormally);
              expect(() => context.announceWithHaptic('Test message'), returnsNormally);
              expect(() => context.focusNext(), returnsNormally);
              expect(() => context.focusPrevious(), returnsNormally);
              expect(() => context.unfocus(), returnsNormally);
              
              return Container();
            },
          ),
        ),
      );
    });
  });
}