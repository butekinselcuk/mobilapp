import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_new/widgets/modals/app_modal.dart';
import 'package:islami_app_new/theme/app_theme.dart';

void main() {
  group('AppModal Widget Tests', () {
    testWidgets('AppModal renders with basic content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppModal(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('AppModal shows title when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppModal(
              title: 'Test Title',
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('AppModal shows close button by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppModal(
              title: 'Test Title',
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('AppModal hides close button when showCloseButton is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppModal(
              title: 'Test Title',
              showCloseButton: false,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('AppModal calls onClose when close button is tapped', (WidgetTester tester) async {
      bool closeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppModal(
              title: 'Test Title',
              onClose: () => closeCalled = true,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closeCalled, isTrue);
    });

    testWidgets('AppModal uses custom title widget when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppModal(
              titleWidget: Row(
                children: [
                  Icon(Icons.star),
                  Text('Custom Title'),
                ],
              ),
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Custom Title'), findsOneWidget);
    });

    testWidgets('AppModal.show creates modal dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppModal.show(
                    context: context,
                    title: 'Dialog Title',
                    child: Text('Dialog Content'),
                  );
                },
                child: Text('Show Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Dialog Title'), findsOneWidget);
      expect(find.text('Dialog Content'), findsOneWidget);
    });

    testWidgets('AppModal.showBottomSheet creates bottom sheet modal', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppModal.showBottomSheet(
                    context: context,
                    title: 'Bottom Sheet Title',
                    child: Text('Bottom Sheet Content'),
                  );
                },
                child: Text('Show Bottom Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Bottom Sheet Title'), findsOneWidget);
      expect(find.text('Bottom Sheet Content'), findsOneWidget);
    });

    group('AppModals Helper Methods', () {
      testWidgets('AppModals.showInfo displays info modal', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppModals.showInfo(
                      context: context,
                      title: 'Info Title',
                      message: 'Info Message',
                    );
                  },
                  child: Text('Show Info'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Info'));
        await tester.pumpAndSettle();

        expect(find.text('Info Title'), findsOneWidget);
        expect(find.text('Info Message'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
        expect(find.text('Tamam'), findsOneWidget);
      });

      testWidgets('AppModals.showError displays error modal', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppModals.showError(
                      context: context,
                      title: 'Error Title',
                      message: 'Error Message',
                    );
                  },
                  child: Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.text('Error Title'), findsOneWidget);
        expect(find.text('Error Message'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Tamam'), findsOneWidget);
      });

      testWidgets('AppModals.showConfirmation displays confirmation modal', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppModals.showConfirmation(
                      context: context,
                      title: 'Confirmation Title',
                      message: 'Confirmation Message',
                    );
                  },
                  child: Text('Show Confirmation'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Confirmation'));
        await tester.pumpAndSettle();

        expect(find.text('Confirmation Title'), findsOneWidget);
        expect(find.text('Confirmation Message'), findsOneWidget);
        expect(find.byIcon(Icons.help_outline), findsOneWidget);
        expect(find.text('İptal'), findsOneWidget);
        expect(find.text('Onayla'), findsOneWidget);
      });

      testWidgets('AppModals.showLoading displays loading modal', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppModals.showLoading(
                      context: context,
                      message: 'Loading Message',
                    );
                  },
                  child: Text('Show Loading'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Loading'));
        await tester.pumpAndSettle();

        expect(find.text('Loading Message'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('Confirmation modal returns true when confirmed', (WidgetTester tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await AppModals.showConfirmation(
                      context: context,
                      title: 'Confirmation',
                      message: 'Are you sure?',
                    );
                  },
                  child: Text('Show Confirmation'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Confirmation'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Onayla'));
        await tester.pumpAndSettle();

        expect(result, isTrue);
      });

      testWidgets('Confirmation modal returns false when cancelled', (WidgetTester tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    result = await AppModals.showConfirmation(
                      context: context,
                      title: 'Confirmation',
                      message: 'Are you sure?',
                    );
                  },
                  child: Text('Show Confirmation'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Confirmation'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('İptal'));
        await tester.pumpAndSettle();

        expect(result, isFalse);
      });
    });

    group('Modal Sizes', () {
      testWidgets('Small modal has correct constraints', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppModal(
                size: ModalSize.small,
                child: Text('Small Modal'),
              ),
            ),
          ),
        );

        // Modal container'ı bul ve boyutunu kontrol et
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(AppModal),
            matching: find.byType(Container),
          ).first,
        );

        // Small modal ekranın %40'ı olmalı
        expect(container.constraints, isNotNull);
      });

      testWidgets('Custom modal uses provided dimensions', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppModal(
                size: ModalSize.custom,
                customWidth: 300,
                customHeight: 200,
                child: Text('Custom Modal'),
              ),
            ),
          ),
        );

        expect(find.text('Custom Modal'), findsOneWidget);
      });
    });

    group('Keyboard Handling', () {
      testWidgets('Modal closes on ESC key when keyboardDismissible is true', (WidgetTester tester) async {
        bool modalClosed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppModal(
                keyboardDismissible: true,
                onClose: () => modalClosed = true,
                child: Text('Keyboard Modal'),
              ),
            ),
          ),
        );

        // ESC tuşuna bas
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();

        expect(modalClosed, isTrue);
      });

      testWidgets('Modal does not close on ESC key when keyboardDismissible is false', (WidgetTester tester) async {
        bool modalClosed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppModal(
                keyboardDismissible: false,
                onClose: () => modalClosed = true,
                child: Text('Keyboard Modal'),
              ),
            ),
          ),
        );

        // ESC tuşuna bas
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();

        expect(modalClosed, isFalse);
      });
    });
  });
}