import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_new/widgets/shared/prayer_time_card.dart';
import 'package:islami_app_new/theme/app_theme.dart';

void main() {
  group('PrayerTimeCard Widget Tests', () {
    late Map<String, String> testPrayerTimes;

    setUp(() {
      testPrayerTimes = {
        'Fajr': '05:30',
        'Dhuhr': '12:45',
        'Asr': '15:30',
        'Maghrib': '18:15',
        'Isha': '19:45',
      };
    });

    testWidgets('PrayerTimeCard renders with basic information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrayerTimeCard(
              city: 'İstanbul',
              readableDate: '15 Ocak 2024, Pazartesi',
              hijriDate: '5 Recep 1445',
              nextPrayer: 'Öğle',
              countdown: '2 saat 30 dakika',
              prayerTimes: testPrayerTimes,
              usingLocation: true,
              onPrayerTimeTap: (name, time) {},
            ),
          ),
        ),
      );

      expect(find.byType(PrayerTimeCard), findsOneWidget);
      expect(find.text('İstanbul'), findsOneWidget);
      expect(find.text('15 Ocak 2024, Pazartesi'), findsOneWidget);
      expect(find.text('5 Recep 1445'), findsOneWidget);
    });

    testWidgets('PrayerTimeCard shows next prayer information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrayerTimeCard(
              city: 'İstanbul',
              readableDate: '15 Ocak 2024, Pazartesi',
              hijriDate: '5 Recep 1445',
              nextPrayer: 'Öğle',
              countdown: '2 saat 30 dakika',
              prayerTimes: testPrayerTimes,
              usingLocation: true,
              onPrayerTimeTap: (name, time) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Öğle'), findsWidgets);
      expect(find.textContaining('2 saat 30 dakika'), findsOneWidget);
    });

    testWidgets('PrayerTimeCard displays all prayer times', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrayerTimeCard(
              city: 'İstanbul',
              readableDate: '15 Ocak 2024, Pazartesi',
              hijriDate: '5 Recep 1445',
              nextPrayer: 'Öğle',
              countdown: '2 saat 30 dakika',
              prayerTimes: testPrayerTimes,
              usingLocation: true,
              onPrayerTimeTap: (name, time) {},
            ),
          ),
        ),
      );

      expect(find.text('05:30'), findsOneWidget);
      expect(find.text('12:45'), findsOneWidget);
      expect(find.text('15:30'), findsOneWidget);
      expect(find.text('18:15'), findsOneWidget);
      expect(find.text('19:45'), findsOneWidget);
    });

    testWidgets('PrayerTimeCard handles prayer time tap', (WidgetTester tester) async {
      String tappedPrayer = '';
      String tappedTime = '';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrayerTimeCard(
              city: 'İstanbul',
              readableDate: '15 Ocak 2024, Pazartesi',
              hijriDate: '5 Recep 1445',
              nextPrayer: 'Öğle',
              countdown: '2 saat 30 dakika',
              prayerTimes: testPrayerTimes,
              usingLocation: true,
              onPrayerTimeTap: (name, time) {
                tappedPrayer = name;
                tappedTime = time;
              },
            ),
          ),
        ),
      );

      // Fajr prayer time'a tıkla
      await tester.tap(find.text('05:30'));
      
      expect(tappedPrayer, isNotEmpty);
      expect(tappedTime, equals('05:30'));
    });

    testWidgets('PrayerTimeCard shows location indicator when using location', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrayerTimeCard(
              city: 'İstanbul',
              readableDate: '15 Ocak 2024, Pazartesi',
              hijriDate: '5 Recep 1445',
              nextPrayer: 'Öğle',
              countdown: '2 saat 30 dakika',
              prayerTimes: testPrayerTimes,
              usingLocation: true,
              onPrayerTimeTap: (name, time) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('PrayerTimeCard shows different icon when not using location', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrayerTimeCard(
              city: 'İstanbul',
              readableDate: '15 Ocak 2024, Pazartesi',
              hijriDate: '5 Recep 1445',
              nextPrayer: 'Öğle',
              countdown: '2 saat 30 dakika',
              prayerTimes: testPrayerTimes,
              usingLocation: false,
              onPrayerTimeTap: (name, time) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });

    testWidgets('PrayerTimeCard handles empty prayer times', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrayerTimeCard(
              city: 'İstanbul',
              readableDate: '15 Ocak 2024, Pazartesi',
              hijriDate: '5 Recep 1445',
              nextPrayer: '',
              countdown: '',
              prayerTimes: {},
              usingLocation: true,
              onPrayerTimeTap: (name, time) {},
            ),
          ),
        ),
      );

      expect(find.byType(PrayerTimeCard), findsOneWidget);
      expect(find.text('İstanbul'), findsOneWidget);
    });

    testWidgets('PrayerTimeCard shows loading state when countdown is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrayerTimeCard(
              city: 'İstanbul',
              readableDate: '15 Ocak 2024, Pazartesi',
              hijriDate: '5 Recep 1445',
              nextPrayer: '',
              countdown: '',
              prayerTimes: testPrayerTimes,
              usingLocation: true,
              onPrayerTimeTap: (name, time) {},
            ),
          ),
        ),
      );

      expect(find.byType(PrayerTimeCard), findsOneWidget);
    });

    testWidgets('PrayerTimeCard displays hijri date correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrayerTimeCard(
              city: 'İstanbul',
              readableDate: '15 Ocak 2024, Pazartesi',
              hijriDate: '5 Recep 1445',
              nextPrayer: 'Öğle',
              countdown: '2 saat 30 dakika',
              prayerTimes: testPrayerTimes,
              usingLocation: true,
              onPrayerTimeTap: (name, time) {},
            ),
          ),
        ),
      );

      expect(find.text('5 Recep 1445'), findsOneWidget);
    });

    testWidgets('PrayerTimeCard handles long city names', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrayerTimeCard(
              city: 'Kahramanmaraş/Afşin',
              readableDate: '15 Ocak 2024, Pazartesi',
              hijriDate: '5 Recep 1445',
              nextPrayer: 'Öğle',
              countdown: '2 saat 30 dakika',
              prayerTimes: testPrayerTimes,
              usingLocation: true,
              onPrayerTimeTap: (name, time) {},
            ),
          ),
        ),
      );

      expect(find.text('Kahramanmaraş/Afşin'), findsOneWidget);
    });

    testWidgets('PrayerTimeCard shows correct prayer names in Turkish', (WidgetTester tester) async {
      final turkishPrayerTimes = {
        'İmsak': '05:00',
        'Güneş': '06:30',
        'Öğle': '12:45',
        'İkindi': '15:30',
        'Akşam': '18:15',
        'Yatsı': '19:45',
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PrayerTimeCard(
              city: 'İstanbul',
              readableDate: '15 Ocak 2024, Pazartesi',
              hijriDate: '5 Recep 1445',
              nextPrayer: 'Öğle',
              countdown: '2 saat 30 dakika',
              prayerTimes: turkishPrayerTimes,
              usingLocation: true,
              onPrayerTimeTap: (name, time) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('İmsak'), findsWidgets);
      expect(find.textContaining('Güneş'), findsWidgets);
      expect(find.textContaining('Öğle'), findsWidgets);
      expect(find.textContaining('İkindi'), findsWidgets);
      expect(find.textContaining('Akşam'), findsWidgets);
      expect(find.textContaining('Yatsı'), findsWidgets);
    });
  });
}