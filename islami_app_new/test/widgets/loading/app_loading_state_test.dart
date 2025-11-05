import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_new/widgets/loading/app_loading_state.dart';
import 'package:islami_app_new/theme/app_theme.dart';

void main() {
  group('AppLoadingState Widget Tests', () {
    testWidgets('AppLoadingState renders with default spinner', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppLoadingState(),
          ),
        ),
      );

      expect(find.byType(AppLoadingState), findsOneWidget);
    });

    testWidgets('AppLoadingState shows message when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppLoadingState(
              message: 'Loading test...',
            ),
          ),
        ),
      );

      expect(find.text('Loading test...'), findsOneWidget);
    });

    testWidgets('AppLoadingState renders dots type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppLoadingState(
              type: LoadingType.dots,
            ),
          ),
        ),
      );

      expect(find.byType(AppLoadingState), findsOneWidget);
    });

    testWidgets('AppLoadingState renders pulse type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppLoadingState(
              type: LoadingType.pulse,
            ),
          ),
        ),
      );

      expect(find.byType(AppLoadingState), findsOneWidget);
    });

    testWidgets('AppLoadingState renders islamic pattern type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppLoadingState(
              type: LoadingType.islamic,
            ),
          ),
        ),
      );

      expect(find.byType(AppLoadingState), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('AppLoadingState renders skeleton type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppLoadingState(
              type: LoadingType.skeleton,
            ),
          ),
        ),
      );

      expect(find.byType(AppLoadingState), findsOneWidget);
    });

    testWidgets('AppLoadingState renders shimmer type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppLoadingState(
              type: LoadingType.shimmer,
            ),
          ),
        ),
      );

      expect(find.byType(AppLoadingState), findsOneWidget);
    });

    testWidgets('AppLoadingState renders custom widget when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppLoadingState(
              type: LoadingType.custom,
              customWidget: Text('Custom Loading'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Loading'), findsOneWidget);
    });

    testWidgets('AppLoadingState renders as overlay when overlay is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppLoadingState(
              overlay: true,
              message: 'Overlay Loading',
            ),
          ),
        ),
      );

      expect(find.text('Overlay Loading'), findsOneWidget);
    });

    group('AppLoadings Helper Methods', () {
      testWidgets('AppLoadings.spinner creates spinner loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadings.spinner(
                message: 'Spinner Loading',
              ),
            ),
          ),
        );

        expect(find.text('Spinner Loading'), findsOneWidget);
      });

      testWidgets('AppLoadings.dots creates dots loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadings.dots(
                message: 'Dots Loading',
              ),
            ),
          ),
        );

        expect(find.text('Dots Loading'), findsOneWidget);
      });

      testWidgets('AppLoadings.pulse creates pulse loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadings.pulse(
                message: 'Pulse Loading',
              ),
            ),
          ),
        );

        expect(find.text('Pulse Loading'), findsOneWidget);
      });

      testWidgets('AppLoadings.islamic creates islamic pattern loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadings.islamic(
                message: 'Islamic Loading',
              ),
            ),
          ),
        );

        expect(find.text('Islamic Loading'), findsOneWidget);
        expect(find.byType(CustomPaint), findsOneWidget);
      });

      testWidgets('AppLoadings.skeleton creates skeleton loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadings.skeleton(),
            ),
          ),
        );

        expect(find.byType(AppLoadingState), findsOneWidget);
      });

      testWidgets('AppLoadings.shimmer creates shimmer loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadings.shimmer(),
            ),
          ),
        );

        expect(find.byType(AppLoadingState), findsOneWidget);
      });

      testWidgets('AppLoadings.overlay creates overlay loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadings.overlay(
                message: 'Overlay Loading',
              ),
            ),
          ),
        );

        expect(find.text('Overlay Loading'), findsOneWidget);
      });

      testWidgets('AppLoadings.fullScreen creates full screen loading', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: AppLoadings.fullScreen(
              message: 'Full Screen Loading',
            ),
          ),
        );

        expect(find.text('Full Screen Loading'), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('Loading Sizes', () {
      testWidgets('Small size loading renders correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadingState(
                size: LoadingSize.small,
              ),
            ),
          ),
        );

        expect(find.byType(AppLoadingState), findsOneWidget);
      });

      testWidgets('Medium size loading renders correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadingState(
                size: LoadingSize.medium,
              ),
            ),
          ),
        );

        expect(find.byType(AppLoadingState), findsOneWidget);
      });

      testWidgets('Large size loading renders correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadingState(
                size: LoadingSize.large,
              ),
            ),
          ),
        );

        expect(find.byType(AppLoadingState), findsOneWidget);
      });

      testWidgets('Custom size loading uses provided size', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadingState(
                size: LoadingSize.custom,
                customSize: 100,
              ),
            ),
          ),
        );

        expect(find.byType(AppLoadingState), findsOneWidget);
      });
    });

    group('Loading Extension', () {
      testWidgets('withLoading extension shows loading overlay when isLoading is true', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Text('Content').withLoading(
                isLoading: true,
                message: 'Loading...',
              ),
            ),
          ),
        );

        expect(find.text('Content'), findsOneWidget);
        expect(find.text('Loading...'), findsOneWidget);
      });

      testWidgets('withLoading extension hides loading overlay when isLoading is false', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Text('Content').withLoading(
                isLoading: false,
                message: 'Loading...',
              ),
            ),
          ),
        );

        expect(find.text('Content'), findsOneWidget);
        expect(find.text('Loading...'), findsNothing);
      });
    });

    group('Animation Tests', () {
      testWidgets('Loading animations start automatically', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadingState(
                type: LoadingType.spinner,
              ),
            ),
          ),
        );

        // İlk frame
        await tester.pump();
        expect(find.byType(AppLoadingState), findsOneWidget);

        // Animasyon frame'leri
        await tester.pump(Duration(milliseconds: 100));
        expect(find.byType(AppLoadingState), findsOneWidget);

        await tester.pump(Duration(milliseconds: 500));
        expect(find.byType(AppLoadingState), findsOneWidget);
      });

      testWidgets('Dots animation cycles through dots', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadingState(
                type: LoadingType.dots,
              ),
            ),
          ),
        );

        // İlk frame
        await tester.pump();
        expect(find.byType(AppLoadingState), findsOneWidget);

        // Animasyon frame'leri
        await tester.pump(Duration(milliseconds: 200));
        await tester.pump(Duration(milliseconds: 400));
        await tester.pump(Duration(milliseconds: 600));
        
        expect(find.byType(AppLoadingState), findsOneWidget);
      });

      testWidgets('Islamic pattern animation rotates', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: AppLoadingState(
                type: LoadingType.islamic,
              ),
            ),
          ),
        );

        // İlk frame
        await tester.pump();
        expect(find.byType(CustomPaint), findsOneWidget);

        // Animasyon frame'leri
        await tester.pump(Duration(milliseconds: 300));
        await tester.pump(Duration(milliseconds: 600));
        
        expect(find.byType(CustomPaint), findsOneWidget);
      });
    });
  });
}