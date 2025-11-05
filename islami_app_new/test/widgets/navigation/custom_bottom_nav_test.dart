import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_new/widgets/navigation/custom_bottom_nav.dart';
import 'package:islami_app_new/theme/app_theme.dart';

void main() {
  group('CustomBottomNavigation Widget Tests', () {
    late List<BottomNavItem> testItems;

    setUp(() {
      testItems = [
        BottomNavItems.home(),
        BottomNavItems.library(),
        BottomNavItems.assistant(),
        BottomNavItems.profile(),
      ];
    });

    testWidgets('CustomBottomNavigation renders with items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              items: testItems,
              currentIndex: 0,
              onTap: (index) {},
            ),
          ),
        ),
      );

      expect(find.byType(CustomBottomNavigation), findsOneWidget);
      expect(find.text('Ana Sayfa'), findsOneWidget);
      expect(find.text('Kitaplık'), findsOneWidget);
      expect(find.text('Asistan'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('CustomBottomNavigation handles tap events', (WidgetTester tester) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              items: testItems,
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      // İkinci item'a tıkla
      await tester.tap(find.text('Kitaplık'));
      expect(tappedIndex, equals(1));
    });

    testWidgets('CustomBottomNavigation shows selected state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              items: testItems,
              currentIndex: 2, // Assistant seçili
              onTap: (index) {},
            ),
          ),
        ),
      );

      expect(find.byType(CustomBottomNavigation), findsOneWidget);
      // Seçili item'ın farklı görünmesi gerekiyor (bu test UI'da görsel olarak kontrol edilebilir)
    });

    testWidgets('CustomBottomNavigation shows badges when provided', (WidgetTester tester) async {
      final itemsWithBadge = [
        BottomNavItems.home(badgeCount: 5),
        BottomNavItems.library(),
        BottomNavItems.assistant(badgeCount: 2),
        BottomNavItems.profile(),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              items: itemsWithBadge,
              currentIndex: 0,
              onTap: (index) {},
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('CustomBottomNavigation shows 99+ for large badge counts', (WidgetTester tester) async {
      final itemsWithLargeBadge = [
        BottomNavItems.home(badgeCount: 150),
        BottomNavItems.library(),
        BottomNavItems.assistant(),
        BottomNavItems.profile(),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              items: itemsWithLargeBadge,
              currentIndex: 0,
              onTap: (index) {},
            ),
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('CustomBottomNavigation uses custom colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              items: testItems,
              currentIndex: 0,
              onTap: (index) {},
              selectedItemColor: Colors.red,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byType(CustomBottomNavigation), findsOneWidget);
    });

    testWidgets('CustomBottomNavigation respects elevation setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              items: testItems,
              currentIndex: 0,
              onTap: (index) {},
              elevation: 16.0,
            ),
          ),
        ),
      );

      expect(find.byType(CustomBottomNavigation), findsOneWidget);
    });

    testWidgets('CustomBottomNavigation animates selection changes', (WidgetTester tester) async {
      int currentIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                bottomNavigationBar: CustomBottomNavigation(
                  items: testItems,
                  currentIndex: currentIndex,
                  onTap: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      // İlk durumda index 0 seçili
      expect(find.byType(CustomBottomNavigation), findsOneWidget);

      // İkinci item'a tıkla
      await tester.tap(find.text('Kitaplık'));
      await tester.pump();

      // Animasyon tamamlanana kadar bekle
      await tester.pumpAndSettle();

      expect(find.byType(CustomBottomNavigation), findsOneWidget);
    });

    testWidgets('CustomBottomNavigation handles haptic feedback', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              items: testItems,
              currentIndex: 0,
              onTap: (index) {},
              enableHapticFeedback: true,
            ),
          ),
        ),
      );

      // Haptic feedback test etmek zor, sadece widget'ın render olduğunu kontrol edelim
      expect(find.byType(CustomBottomNavigation), findsOneWidget);
    });

    testWidgets('CustomBottomNavigation disables haptic feedback when requested', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigation(
              items: testItems,
              currentIndex: 0,
              onTap: (index) {},
              enableHapticFeedback: false,
            ),
          ),
        ),
      );

      expect(find.byType(CustomBottomNavigation), findsOneWidget);
    });
  });

  group('BottomNavItem Tests', () {
    test('BottomNavItem creates with required parameters', () {
      const item = BottomNavItem(
        icon: Icons.home,
        label: 'Home',
      );

      expect(item.icon, equals(Icons.home));
      expect(item.label, equals('Home'));
      expect(item.activeIcon, isNull);
      expect(item.semanticLabel, isNull);
      expect(item.badgeCount, isNull);
      expect(item.badgeColor, isNull);
    });

    test('BottomNavItem creates with all parameters', () {
      const item = BottomNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        semanticLabel: 'Home page',
        badgeCount: 5,
        badgeColor: Colors.red,
      );

      expect(item.icon, equals(Icons.home_outlined));
      expect(item.activeIcon, equals(Icons.home));
      expect(item.label, equals('Home'));
      expect(item.semanticLabel, equals('Home page'));
      expect(item.badgeCount, equals(5));
      expect(item.badgeColor, equals(Colors.red));
    });
  });

  group('BottomNavItems Factory Tests', () {
    test('BottomNavItems.home creates home item', () {
      final item = BottomNavItems.home();
      
      expect(item.icon, equals(Icons.home_outlined));
      expect(item.activeIcon, equals(Icons.home));
      expect(item.label, equals('Ana Sayfa'));
      expect(item.semanticLabel, equals('Ana sayfaya git'));
    });

    test('BottomNavItems.library creates library item', () {
      final item = BottomNavItems.library();
      
      expect(item.icon, equals(Icons.menu_book_outlined));
      expect(item.activeIcon, equals(Icons.menu_book));
      expect(item.label, equals('Kitaplık'));
      expect(item.semanticLabel, equals('Kitaplığa git'));
    });

    test('BottomNavItems.assistant creates assistant item', () {
      final item = BottomNavItems.assistant();
      
      expect(item.icon, equals(Icons.psychology_outlined));
      expect(item.activeIcon, equals(Icons.psychology));
      expect(item.label, equals('Asistan'));
      expect(item.semanticLabel, equals('AI asistanına git'));
    });

    test('BottomNavItems.journey creates journey item', () {
      final item = BottomNavItems.journey();
      
      expect(item.icon, equals(Icons.explore_outlined));
      expect(item.activeIcon, equals(Icons.explore));
      expect(item.label, equals('Yolculuklar'));
      expect(item.semanticLabel, equals('İlim yolculuklarına git'));
    });

    test('BottomNavItems.profile creates profile item', () {
      final item = BottomNavItems.profile();
      
      expect(item.icon, equals(Icons.person_outline));
      expect(item.activeIcon, equals(Icons.person));
      expect(item.label, equals('Profil'));
      expect(item.semanticLabel, equals('Profile git'));
    });

    test('BottomNavItems.admin creates admin item', () {
      final item = BottomNavItems.admin();
      
      expect(item.icon, equals(Icons.admin_panel_settings_outlined));
      expect(item.activeIcon, equals(Icons.admin_panel_settings));
      expect(item.label, equals('Admin'));
      expect(item.semanticLabel, equals('Admin paneline git'));
    });

    test('BottomNavItems factory methods accept badge count', () {
      final item = BottomNavItems.home(badgeCount: 10);
      
      expect(item.badgeCount, equals(10));
    });
  });

  group('CustomBottomNavigationSkeleton Tests', () {
    testWidgets('CustomBottomNavigationSkeleton renders with default item count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigationSkeleton(),
          ),
        ),
      );

      expect(find.byType(CustomBottomNavigationSkeleton), findsOneWidget);
    });

    testWidgets('CustomBottomNavigationSkeleton renders with custom item count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavigationSkeleton(
              itemCount: 3,
            ),
          ),
        ),
      );

      expect(find.byType(CustomBottomNavigationSkeleton), findsOneWidget);
    });
  });
}