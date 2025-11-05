import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_new/utils/responsive.dart';

void main() {
  group('ResponsiveHelper Tests', () {
    testWidgets('getDeviceType returns correct device type for mobile', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final deviceType = ResponsiveHelper.getDeviceType(context);
              expect(deviceType, DeviceType.mobile);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('getDeviceType returns correct device type for tablet', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final deviceType = ResponsiveHelper.getDeviceType(context);
              expect(deviceType, DeviceType.tablet);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('getDeviceType returns correct device type for desktop', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final deviceType = ResponsiveHelper.getDeviceType(context);
              expect(deviceType, DeviceType.desktop);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('isMobile returns true for mobile devices', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isMobile(context), isTrue);
              expect(ResponsiveHelper.isTablet(context), isFalse);
              expect(ResponsiveHelper.isDesktop(context), isFalse);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('isTablet returns true for tablet devices', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isMobile(context), isFalse);
              expect(ResponsiveHelper.isTablet(context), isTrue);
              expect(ResponsiveHelper.isDesktop(context), isFalse);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('isDesktop returns true for desktop devices', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveHelper.isMobile(context), isFalse);
              expect(ResponsiveHelper.isTablet(context), isFalse);
              expect(ResponsiveHelper.isDesktop(context), isTrue);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('getGridColumns returns correct columns for different devices', (WidgetTester tester) async {
      // Mobile test
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final columns = ResponsiveHelper.getGridColumns(
                context,
                mobileColumns: 1,
                tabletColumns: 2,
                desktopColumns: 3,
              );
              expect(columns, 1);
              return Container();
            },
          ),
        ),
      );

      // Tablet test
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final columns = ResponsiveHelper.getGridColumns(
                context,
                mobileColumns: 1,
                tabletColumns: 2,
                desktopColumns: 3,
              );
              expect(columns, 2);
              return Container();
            },
          ),
        ),
      );

      // Desktop test
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final columns = ResponsiveHelper.getGridColumns(
                context,
                mobileColumns: 1,
                tabletColumns: 2,
                desktopColumns: 3,
              );
              expect(columns, 3);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('getResponsivePadding returns correct padding for different devices', (WidgetTester tester) async {
      // Mobile test
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final padding = ResponsiveHelper.getResponsivePadding(
                context,
                mobilePadding: 16.0,
                tabletPadding: 24.0,
                desktopPadding: 32.0,
              );
              expect(padding, 16.0);
              return Container();
            },
          ),
        ),
      );

      // Tablet test
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final padding = ResponsiveHelper.getResponsivePadding(
                context,
                mobilePadding: 16.0,
                tabletPadding: 24.0,
                desktopPadding: 32.0,
              );
              expect(padding, 24.0);
              return Container();
            },
          ),
        ),
      );

      // Desktop test
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final padding = ResponsiveHelper.getResponsivePadding(
                context,
                mobilePadding: 16.0,
                tabletPadding: 24.0,
                desktopPadding: 32.0,
              );
              expect(padding, 32.0);
              return Container();
            },
          ),
        ),
      );
    });
  });

  group('MediaQueryExtensions Tests', () {
    testWidgets('MediaQuery extensions work correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.screenWidth, 360.0);
              expect(context.screenHeight, 640.0);
              expect(context.isMobile, isTrue);
              expect(context.isTablet, isFalse);
              expect(context.isDesktop, isFalse);
              expect(context.isPortrait, isTrue);
              expect(context.isLandscape, isFalse);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('Landscape detection works correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(640, 360));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(context.isLandscape, isTrue);
              expect(context.isPortrait, isFalse);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('Responsive helper methods work correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final padding = context.responsivePadding(
                mobile: 16.0,
                tablet: 24.0,
                desktop: 32.0,
              );
              expect(padding, 16.0);

              final fontSize = context.responsiveFontSize(
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              );
              expect(fontSize, 14.0);

              final iconSize = context.responsiveIconSize(
                mobile: 24.0,
                tablet: 28.0,
                desktop: 32.0,
              );
              expect(iconSize, 24.0);

              return Container();
            },
          ),
        ),
      );
    });
  });

  group('ResponsiveBuilder Tests', () {
    testWidgets('ResponsiveBuilder shows correct widget for mobile', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            mobile: (context) => const Text('Mobile'),
            tablet: (context) => const Text('Tablet'),
            desktop: (context) => const Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('ResponsiveBuilder shows correct widget for tablet', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            mobile: (context) => const Text('Mobile'),
            tablet: (context) => const Text('Tablet'),
            desktop: (context) => const Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('ResponsiveBuilder shows correct widget for desktop', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            mobile: (context) => const Text('Mobile'),
            tablet: (context) => const Text('Tablet'),
            desktop: (context) => const Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsOneWidget);
    });

    testWidgets('ResponsiveBuilder falls back correctly when specific builder is missing', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            mobile: (context) => const Text('Mobile'),
            desktop: (context) => const Text('Desktop'),
            // tablet builder is missing
          ),
        ),
      );

      // Should fall back to desktop since tablet is missing
      expect(find.text('Desktop'), findsOneWidget);
    });
  });

  group('ResponsiveValue Tests', () {
    testWidgets('ResponsiveValue returns correct value for different devices', (WidgetTester tester) async {
      const responsiveValue = ResponsiveValue<int>(
        mobile: 1,
        tablet: 2,
        desktop: 3,
      );

      // Mobile test
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(responsiveValue.getValue(context), 1);
              return Container();
            },
          ),
        ),
      );

      // Tablet test
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(responsiveValue.getValue(context), 2);
              return Container();
            },
          ),
        ),
      );

      // Desktop test
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(responsiveValue.getValue(context), 3);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('ResponsiveValue falls back correctly when values are missing', (WidgetTester tester) async {
      const responsiveValue = ResponsiveValue<int>(
        mobile: 1,
        // tablet and desktop values are missing
      );

      // Tablet test - should fall back to mobile
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(responsiveValue.getValue(context), 1);
              return Container();
            },
          ),
        ),
      );

      // Desktop test - should fall back to mobile
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(responsiveValue.getValue(context), 1);
              return Container();
            },
          ),
        ),
      );
    });
  });

  group('ResponsiveContainer Tests', () {
    testWidgets('ResponsiveContainer applies correct padding for mobile', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveContainer(
            mobilePadding: const EdgeInsets.all(16),
            tabletPadding: const EdgeInsets.all(24),
            desktopPadding: const EdgeInsets.all(32),
            child: const Text('Content'),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, const EdgeInsets.all(16));
    });
  });

  group('ResponsiveSpacing Tests', () {
    testWidgets('ResponsiveSpacing.height creates correct SizedBox', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ResponsiveSpacing.height(
                context,
                mobile: 8.0,
                tablet: 12.0,
                desktop: 16.0,
              );
            },
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.height, 8.0);
    });

    testWidgets('ResponsiveSpacing.width creates correct SizedBox', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ResponsiveSpacing.width(
                context,
                mobile: 8.0,
                tablet: 12.0,
                desktop: 16.0,
              );
            },
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 8.0);
    });
  });
}