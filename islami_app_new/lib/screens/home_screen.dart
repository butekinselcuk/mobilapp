import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math';
import 'library_screen.dart';
import 'journey_screen.dart';
import 'user_data_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'notification_permission.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../main.dart'; // flutterLocalNotificationsPlugin erişimi için
import 'qibla_compass_screen.dart'; // Kıble pusulası ekranı için
import '../widgets/shared/app_card.dart';
import '../widgets/shared/app_button.dart';
import '../widgets/shared/app_input.dart';
import '../widgets/shared/prayer_time_card.dart';
import '../widgets/shared/ai_assistant_card.dart';
import '../widgets/shared/quick_access_grid.dart';
import '../widgets/navigation/page_transitions.dart';
import '../utils/responsive.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Yeni: Placeholder ekran
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title ekranı yakında!')),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String> prayerTimes = {};
  String readableDate = '';
  String hijriDate = '';
  String city = 'İstanbul';
  String nextPrayer = '';
  String countdown = '';
  Timer? _timer;
  bool usingLocation = false;
  List<Map<String, dynamic>> turkeyCities = [];

  // AI asistanı için ek state
  final TextEditingController _aiController = TextEditingController();
  String? _aiAnswer;
  bool _aiLoading = false;
  String? _aiError;

  // Kullanıcı ilerlemesi için ek state
  double? zikrProgress;
  String? zikrTitle;
  int? zikrId;
  bool progressLoading = true;
  // Journey için rastgele modül
  Map<String, dynamic>? randomJourneyModule;
  bool journeyLoading = true;
  // Journey ilerleme
  String? journeyTitle;
  int? journeyModuleId;
  double? journeyProgress;
  // Kitaplık ilerleme
  String? libraryTitle;
  int? libraryId;
  String? libraryCategory;

  @override
  void initState() {
    super.initState();
    loadCitiesAndInit();
    fetchZikrProgress();
    fetchJourneyProgress();
    fetchLibraryProgress();
    fetchRandomJourneyModule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> loadCitiesAndInit() async {
    final citiesJson = await rootBundle.loadString('assets/turkey_cities.json');
    turkeyCities = List<Map<String, dynamic>>.from(json.decode(citiesJson));
    await tryGetLocationAndSetCity();
    fetchPrayerTimes();
  }

  Future<void> tryGetLocationAndSetCity() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      String nearest = findNearestCity(pos.latitude, pos.longitude);
      setState(() {
        city = nearest;
        usingLocation = true;
      });
    } catch (e) {
      // Konum alınamazsa varsayılan şehir kalır
    }
  }

  String findNearestCity(double lat, double lng) {
    double minDist = double.infinity;
    String nearest = city;
    for (final c in turkeyCities) {
      final d = distance(lat, lng, c['lat'], c['lng']);
      if (d < minDist) {
        minDist = d;
        nearest = c['name'];
      }
    }
    return nearest;
  }

  double distance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat/2) * sin(dLat/2) + cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon/2) * sin(dLon/2);
    final c = 2 * atan2(sqrt(a), sqrt(1-a));
    return R * c;
  }

  Future<void> fetchPrayerTimes() async {
    final url = 'https://api.aladhan.com/v1/timingsByCity?city=$city&country=Turkey&method=2';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final timings = data['data']['timings'];
      if (mounted) {
        setState(() {
          prayerTimes = {
            'İMSAK': timings['Fajr'],
            'GÜNEŞ': timings['Sunrise'],
            'ÖĞLE': timings['Dhuhr'],
            'İKİNDİ': timings['Asr'],
            'AKŞAM': timings['Maghrib'],
            'YATSI': timings['Isha'],
          };
          readableDate = data['data']['date']['readable'];
          hijriDate = "${data['data']['date']['hijri']['day']} ${data['data']['date']['hijri']['month']['en']} ${data['data']['date']['hijri']['year']}";
        });
        updateCountdown();
        _timer = Timer.periodic(Duration(seconds: 1), (_) => updateCountdown());
      }
    }
  }

  void updateCountdown() {
    if (!mounted) return;
    final now = DateTime.now();
    String? next;
    DateTime? nextTime;
    for (var entry in prayerTimes.entries) {
      final parts = entry.value.split(':');
      final t = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      if (t.isAfter(now)) {
        next = entry.key;
        nextTime = t;
        break;
      }
    }
    if (next == null) {
      // Gün bitti, ilk vakte geç
      final parts = prayerTimes.values.first.split(':');
      next = prayerTimes.keys.first;
      nextTime = DateTime(now.year, now.month, now.day + 1, int.parse(parts[0]), int.parse(parts[1]));
    }
    final diff = nextTime!.difference(now);
    if (mounted) {
      setState(() {
        nextPrayer = next!;
        countdown = "${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _askAI() async {
    await dotenv.load(fileName: "assets/.env");
    final question = _aiController.text.trim();
    if (question.isEmpty) return;
    setState(() {
      _aiLoading = true;
      _aiError = null;
      _aiAnswer = null;
    });
    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final endpoint = apiUrl.isNotEmpty ? '$apiUrl/api/ask' : '';
      // JWT token'ı oku ve header'a ekle
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('flutter_jwt_token') ?? '';
      print('DEBUG: JWT Token: $token');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      print('DEBUG: Headers: $headers');
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: json.encode({'question': question}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _aiAnswer = data['answer'];
          _aiLoading = false;
        });
      } else {
        setState(() {
          _aiError = 'Yanıt alınamadı: ${response.body}';
          _aiLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _aiError = 'Bir hata oluştu: $e';
        _aiLoading = false;
      });
    }
  }

  Future<void> fetchZikrProgress() async {
    await dotenv.load(fileName: "assets/.env");
    setState(() { progressLoading = true; });
    // Örnek: Kullanıcı favori zikirlerinden ilkini çekiyoruz (gerçek API ile değiştirilebilir)
    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
      final res = await http.get(
        Uri.parse('$apiUrl/user/favorites?type=zikr'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(json.decode(res.body));
        if (data.isNotEmpty) {
          final zikir = data.first;
          setState(() {
            zikrTitle = zikir['title'] ?? 'Zikir';
            zikrId = zikir['id'];
            zikrProgress = (zikir['progress'] ?? 0) / (zikir['target'] ?? 1);
            progressLoading = false;
          });
        } else {
          setState(() { zikrTitle = null; zikrId = null; zikrProgress = null; progressLoading = false; });
        }
      } else {
        setState(() { progressLoading = false; });
      }
    } catch (e) {
      setState(() { progressLoading = false; });
    }
  }

  Future<void> fetchRandomJourneyModule() async {
    await dotenv.load(fileName: "assets/.env");
    setState(() { journeyLoading = true; });
    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
      final res = await http.get(
        Uri.parse('$apiUrl/api/journey_modules'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(json.decode(res.body));
        if (data.isNotEmpty) {
          final random = (data..shuffle()).first;
          setState(() { randomJourneyModule = random; journeyLoading = false; });
        } else {
          setState(() { randomJourneyModule = null; journeyLoading = false; });
        }
      } else {
        setState(() { journeyLoading = false; });
      }
    } catch (e) {
      setState(() { journeyLoading = false; });
    }
  }

  Future<void> fetchJourneyProgress() async {
    await dotenv.load(fileName: "assets/.env");
    // Örnek: Kullanıcının journey ilerlemesini çek
    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
      final res = await http.get(
        Uri.parse('$apiUrl/user/journey_progress'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = List<Map<String, dynamic>>.from(json.decode(res.body));
        if (data.isNotEmpty) {
          final last = data.first;
          setState(() {
            journeyTitle = last['module_title'] ?? 'İlim Yolculuğu';
            journeyModuleId = last['module_id'];
            journeyProgress = (last['completed_step'] ?? 0) / ((last['total_steps'] ?? 1));
          });
        }
      }
    } catch (_) {}
  }

  Future<void> fetchLibraryProgress() async {
    await dotenv.load(fileName: "assets/.env");
    // Örnek: Kullanıcının kitaplıkta en son okuduğu dua/hadis/ayet
    // (API veya local storage ile entegre edilebilir)
    // Şimdilik dummy veri
    setState(() {
      libraryTitle = 'Subhanallah';
      libraryId = 1;
      libraryCategory = 'zikr';
    });
  }

  Future<void> _showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('test_channel', 'Test Bildirimleri',
            channelDescription: 'Test amaçlı bildirimler',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    String msg = 'Test bildirimi gönderildi';
    if (kIsWeb) {
      final permission = getWebNotificationPermission();
      if (permission == 'granted') {
        msg += ' (bildirim izni: Onaylandı)';
      } else if (permission == 'denied') {
        msg += ' (bildirim izni: Reddedildi)';
      } else {
        msg += ' (bildirim izni: Sorulmadı veya beklemede. Lütfen tarayıcıdan izin verin.)';
      }
    } else {
      msg += ' (mobilde sistem ayarlarından kontrol edebilirsiniz)';
    }
    try {
      await flutterLocalNotificationsPlugin.show(
        0,
        'Test Bildirimi',
        'Bu bir test bildirimidir.',
        platformChannelSpecifics,
      );
    } catch (e) {
      msg = 'Bildirim gönderilemedi. Lütfen bildirim izni verin.';
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> scheduleTestNotification() async {
    final now = DateTime.now().add(const Duration(seconds: 10));
    await flutterLocalNotificationsPlugin.zonedSchedule(
      9999,
      'Test Zamanlanmış Bildirim',
      'Bu bir zamanlanmış test bildirimidir.',
      tz.TZDateTime.from(now, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel',
          'Namaz Vakitleri',
          channelDescription: 'Namaz vakti hatırlatıcıları',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ana Sayfa',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: ResponsiveContainer(
        mobileMaxWidth: double.infinity,
        tabletMaxWidth: 800,
        desktopMaxWidth: 1200,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.responsivePadding(
            mobile: 16,
            tablet: 24,
            desktop: 32,
          )),
          child: ResponsiveBuilder(
            mobile: (context) => _buildMobileLayout(context),
            tablet: (context) => _buildTabletLayout(context),
            desktop: (context) => _buildDesktopLayout(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
            // Geçici Onboarding Test Butonu
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AppButton(
                text: 'Onboarding Test',
                type: AppButtonType.outline,
                size: AppButtonSize.small,
                onPressed: () {
                  Navigator.of(context).pushNamed('/onboarding');
                },
                semanticLabel: 'Onboarding test ekranını aç',
              ),
            ),
            // Namaz Vakitleri Kartı
            PrayerTimeCard(
              city: city,
              readableDate: readableDate,
              hijriDate: hijriDate,
              nextPrayer: nextPrayer,
              countdown: countdown,
              prayerTimes: prayerTimes,
              usingLocation: usingLocation,
              onPrayerTimeTap: _showPrayerSettingsDialog,
            ),
            SizedBox(height: 16),
            // AI Asistan Kartı
            AIAssistantCard(
              controller: _aiController,
              isLoading: _aiLoading,
              errorMessage: _aiError,
              answer: _aiAnswer,
              onSendMessage: _askAI,
              onExampleTap: (question) {
                _aiController.text = question;
                _askAI();
              },
              exampleQuestions: const [
                'Namazın şartları nelerdir?',
                'Oruçluyken misvak kullanılır mı?',
                'Zekat kimlere farzdır?',
                'Abdest nasıl alınır?',
              ],
            ),
            SizedBox(height: 16),
            // Kıble Pusulası Butonu
            AppCard(
              type: AppCardType.filled,
              borderRadius: 14,
              elevation: 1,
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              semanticLabel: 'Kıble pusulası butonu',
              onTap: () {
                context.pushIslamic(QiblaCompassScreen());
              },
              child: Row(
                children: [
                  Icon(Icons.explore, color: Theme.of(context).brightness == Brightness.dark ? AppColors.primaryLight : AppColors.primaryDark, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kıbleyi Göster', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).brightness == Brightness.dark ? AppColors.primaryLight : AppColors.primaryDark)),
                        Text('Kıble yönünü bulmak için tıklayın', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Theme.of(context).brightness == Brightness.dark ? AppColors.primaryLight : AppColors.primaryDark, size: 16),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Test Bildirimi Butonu
            AppButton(
              text: 'Test Bildirimi Gönder',
              type: AppButtonType.secondary,
              size: AppButtonSize.medium,
              icon: Icons.notifications_active,
              fullWidth: true,
              onPressed: () async {
                await scheduleTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('10 saniye sonra zamanlanmış test bildirimi gönderilecek.')),
                  );
                }
              },
              semanticLabel: 'Test bildirimi gönder',
            ),
            SizedBox(height: 16),
            // Hızlı Erişim Butonları
            QuickAccessGrid(
              items: [
                QuickAccessItems.quran(() {
                  context.pushWithTransition(
                    LibraryScreen(initialCategory: 'quran'),
                    type: PageTransitionType.slideRight,
                  );
                }),
                QuickAccessItems.hadith(() {
                  context.pushWithTransition(
                    LibraryScreen(initialCategory: 'hadis'),
                    type: PageTransitionType.slideRight,
                  );
                }),
                QuickAccessItems.prayer(() {
                  context.pushWithTransition(
                    LibraryScreen(initialCategory: 'dua'),
                    type: PageTransitionType.slideRight,
                  );
                }),
                QuickAccessItems.dhikr(() {
                  context.pushWithTransition(
                    LibraryScreen(initialCategory: 'zikr'),
                    type: PageTransitionType.slideRight,
                  );
                }),
                QuickAccessItems.qibla(() {
                  context.pushIslamic(QiblaCompassScreen());
                }),
                QuickAccessItems.journey(() {
                  context.pushIslamic(JourneyScreen());
                }),
              ],
              crossAxisCount: 3,
              animationDelay: const Duration(milliseconds: 150),
            ),
            SizedBox(height: 16),
            // İlim Yolculukları Kartı
            AppCard(
              type: AppCardType.standard,
              borderRadius: 20,
              elevation: 1,
              semanticLabel: 'İlim yolculukları kartı',
              child: ListTile(
                leading: Icon(Icons.explore, color: Colors.green),
                title: Text(journeyLoading 
                  ? 'Yükleniyor...' 
                  : (randomJourneyModule?['title'] ?? 'İlim Yolculuğu Bulunamadı'), style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: journeyLoading
                  ? null
                  : (randomJourneyModule != null 
                      ? Text(randomJourneyModule?['description'] ?? '')
                      : Text('Henüz journey modülü eklenmemiş.')),
                trailing: Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  if (randomJourneyModule != null) {
                    context.pushIslamic(JourneyScreen(initialModuleId: randomJourneyModule!['id']));
                  } else {
                    context.pushIslamic(JourneyScreen());
                  }
                },
              ),
            ),
            SizedBox(height: 12),
            // Kaldığın Yerden Devam Et Kartı
            buildContinueCard(),
            SizedBox(height: 12),
            // Özel Günler Kartı
            AppCard(
              type: AppCardType.standard,
              borderRadius: 20,
              elevation: 1,
              semanticLabel: 'Özel günler kartı',
              child: ListTile(
                leading: CircleAvatar(child: Text('🕋', style: TextStyle(fontSize: 20))),
                title: Text('Hicri Takvim', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('1 Şevval 2025 - Ramazan Bayramı - Yarın'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Özel Günler'),
                      content: Text('Yaklaşan dini günler ve bayramlar burada gösterilecek.'),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Kapat'))],
                    ),
                  );
                },
              ),
            ),
          ],
        );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        // Üst kısım - Namaz vakitleri ve AI asistan yan yana
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol taraf - Namaz vakitleri
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  PrayerTimeCard(
                    city: city,
                    readableDate: readableDate,
                    hijriDate: hijriDate,
                    nextPrayer: nextPrayer,
                    countdown: countdown,
                    prayerTimes: prayerTimes,
                    usingLocation: usingLocation,
                    onPrayerTimeTap: _showPrayerSettingsDialog,
                  ),
                  ResponsiveSpacing.height(context, mobile: 16, tablet: 20),
                  // Kıble pusulası kartı
                  _buildQiblaCard(),
                ],
              ),
            ),
            ResponsiveSpacing.width(context, mobile: 16, tablet: 20),
            // Sağ taraf - AI asistan
            Expanded(
              flex: 1,
              child: AIAssistantCard(
                controller: _aiController,
                isLoading: _aiLoading,
                errorMessage: _aiError,
                answer: _aiAnswer,
                onSendMessage: _askAI,
                onExampleTap: (question) {
                  _aiController.text = question;
                  _askAI();
                },
                exampleQuestions: const [
                  'Namazın şartları nelerdir?',
                  'Oruçluyken misvak kullanılır mı?',
                  'Zekat kimlere farzdır?',
                  'Abdest nasıl alınır?',
                ],
              ),
            ),
          ],
        ),
        
        ResponsiveSpacing.height(context, mobile: 16, tablet: 24),
        
        // Hızlı erişim butonları - tablet için 4 sütun
        QuickAccessGrid(
          items: _getQuickAccessItems(),
          crossAxisCount: 4,
          animationDelay: const Duration(milliseconds: 150),
        ),
        
        ResponsiveSpacing.height(context, mobile: 16, tablet: 24),
        
        // Alt kısım - Diğer kartlar
        _buildBottomCards(),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        // Üst kısım - 3 sütunlu layout
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol taraf - Namaz vakitleri
            Expanded(
              flex: 2,
              child: PrayerTimeCard(
                city: city,
                readableDate: readableDate,
                hijriDate: hijriDate,
                nextPrayer: nextPrayer,
                countdown: countdown,
                prayerTimes: prayerTimes,
                usingLocation: usingLocation,
                onPrayerTimeTap: _showPrayerSettingsDialog,
              ),
            ),
            ResponsiveSpacing.width(context, desktop: 24),
            // Orta - AI asistan
            Expanded(
              flex: 3,
              child: AIAssistantCard(
                controller: _aiController,
                isLoading: _aiLoading,
                errorMessage: _aiError,
                answer: _aiAnswer,
                onSendMessage: _askAI,
                onExampleTap: (question) {
                  _aiController.text = question;
                  _askAI();
                },
                exampleQuestions: const [
                  'Namazın şartları nelerdir?',
                  'Oruçluyken misvak kullanılır mı?',
                  'Zekat kimlere farzdır?',
                  'Abdest nasıl alınır?',
                ],
              ),
            ),
            ResponsiveSpacing.width(context, desktop: 24),
            // Sağ taraf - Hızlı erişim
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildQiblaCard(),
                  ResponsiveSpacing.height(context, desktop: 16),
                  QuickAccessGrid(
                    items: _getQuickAccessItems().take(6).toList(),
                    crossAxisCount: 2,
                    animationDelay: const Duration(milliseconds: 150),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        ResponsiveSpacing.height(context, desktop: 32),
        
        // Alt kısım - Diğer kartlar
        _buildBottomCards(),
      ],
    );
  }

  Widget _buildQiblaCard() {
    return AppCard(
      type: AppCardType.filled,
      borderRadius: 14,
      elevation: 1,
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      semanticLabel: 'Kıble pusulası butonu',
      onTap: () {
        context.pushIslamic(QiblaCompassScreen());
      },
      child: Row(
        children: [
          Icon(Icons.explore, color: Theme.of(context).brightness == Brightness.dark ? AppColors.primaryLight : AppColors.primaryDark, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kıbleyi Göster', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).brightness == Brightness.dark ? AppColors.primaryLight : AppColors.primaryDark)),
                Text('Kıble yönünü bulmak için tıklayın', style: TextStyle(color: AppColors.primary, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Theme.of(context).brightness == Brightness.dark ? AppColors.primaryLight : AppColors.primaryDark, size: 16),
        ],
      ),
    );
  }

  List<QuickAccessItem> _getQuickAccessItems() {
    return [
      QuickAccessItems.quran(() {
        context.pushWithTransition(
          LibraryScreen(initialCategory: 'quran'),
          type: PageTransitionType.slideRight,
        );
      }),
      QuickAccessItems.hadith(() {
        context.pushWithTransition(
          LibraryScreen(initialCategory: 'hadis'),
          type: PageTransitionType.slideRight,
        );
      }),
      QuickAccessItems.prayer(() {
        context.pushWithTransition(
          LibraryScreen(initialCategory: 'dua'),
          type: PageTransitionType.slideRight,
        );
      }),
      QuickAccessItems.dhikr(() {
        context.pushWithTransition(
          LibraryScreen(initialCategory: 'zikr'),
          type: PageTransitionType.slideRight,
        );
      }),
      QuickAccessItems.qibla(() {
        context.pushIslamic(QiblaCompassScreen());
      }),
      QuickAccessItems.journey(() {
        context.pushIslamic(JourneyScreen());
      }),
    ];
  }

  Widget _buildBottomCards() {
    return Column(
      children: [
        // Test bildirimi butonu
        AppButton(
          text: 'Test Bildirimi Gönder',
          type: AppButtonType.secondary,
          size: AppButtonSize.medium,
          icon: Icons.notifications_active,
          fullWidth: true,
          onPressed: () async {
            await scheduleTestNotification();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('10 saniye sonra zamanlanmış test bildirimi gönderilecek.')),
              );
            }
          },
          semanticLabel: 'Test bildirimi gönder',
        ),
        
        ResponsiveSpacing.height(context, mobile: 16, tablet: 20, desktop: 24),
        
        // İlim yolculukları ve diğer kartlar
        ResponsiveBuilder(
          mobile: (context) => Column(
            children: [
              _buildJourneyCard(),
              ResponsiveSpacing.height(context, mobile: 12),
              buildContinueCard(),
              ResponsiveSpacing.height(context, mobile: 12),
              _buildSpecialDaysCard(),
            ],
          ),
          tablet: (context) => Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildJourneyCard()),
                  ResponsiveSpacing.width(context, tablet: 16),
                  Expanded(child: buildContinueCard()),
                ],
              ),
              ResponsiveSpacing.height(context, tablet: 16),
              _buildSpecialDaysCard(),
            ],
          ),
          desktop: (context) => Row(
            children: [
              Expanded(child: _buildJourneyCard()),
              ResponsiveSpacing.width(context, desktop: 24),
              Expanded(child: buildContinueCard()),
              ResponsiveSpacing.width(context, desktop: 24),
              Expanded(child: _buildSpecialDaysCard()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyCard() {
    return AppCard(
      type: AppCardType.standard,
      borderRadius: 20,
      elevation: 1,
      semanticLabel: 'İlim yolculukları kartı',
      child: ListTile(
        leading: Icon(Icons.explore, color: Colors.green),
        title: Text(journeyLoading 
          ? 'Yükleniyor...' 
          : (randomJourneyModule?['title'] ?? 'İlim Yolculuğu Bulunamadı'), style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: journeyLoading
          ? null
          : (randomJourneyModule != null 
              ? Text(randomJourneyModule?['description'] ?? '')
              : Text('Henüz journey modülü eklenmemiş.')),
        trailing: Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          if (randomJourneyModule != null) {
            context.pushIslamic(JourneyScreen(initialModuleId: randomJourneyModule!['id']));
          } else {
            context.pushIslamic(JourneyScreen());
          }
        },
      ),
    );
  }

  Widget _buildSpecialDaysCard() {
    return AppCard(
      type: AppCardType.standard,
      borderRadius: 20,
      elevation: 1,
      semanticLabel: 'Özel günler kartı',
      child: ListTile(
        leading: CircleAvatar(child: Text('🕋', style: TextStyle(fontSize: 20))),
        title: Text('Hicri Takvim', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('1 Şevval 2025 - Ramazan Bayramı - Yarın'),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Özel Günler'),
              content: Text('Yaklaşan dini günler ve bayramlar burada gösterilecek.'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Kapat'))],
            ),
          );
        },
      ),
    );
  }

  void _showPrayerSettingsDialog(String name, String time) {
    showDialog(
      context: context,
      builder: (context) => PrayerSettingsDialog(prayerName: name, prayerTime: time),
    );
  }

  // home_screen.dart
  // Kaldığın Yerden Devam Et kartı: Önce zikir, yoksa journey, yoksa kitaplıkta en son kaldığın içeriği gösterir.
  Widget buildContinueCard() {
    if (progressLoading) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.play_arrow, color: AppColors.primary),
          title: Text('Yükleniyor...', style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: SizedBox(width: 60, child: LinearProgressIndicator()),
        ),
      );
    }
    // Öncelik: Zikir > Journey > Kitaplık
    if (zikrProgress != null && zikrId != null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.play_arrow, color: AppColors.primary),
          title: Text(zikrTitle ?? 'Kaldığın yerden devam et', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('$zikrTitle > %${((zikrProgress ?? 0) * 100).toInt()}'),
          trailing: SizedBox(width: 60, child: LinearProgressIndicator(value: zikrProgress, color: AppColors.primary, backgroundColor: Theme.of(context).colorScheme.surfaceVariant)),
          onTap: () {
            context.pushWithTransition(
              LibraryScreen(initialCategory: 'zikr', initialId: zikrId),
              type: PageTransitionType.fade,
            );
          },
        ),
      );
    } else if (journeyProgress != null && journeyModuleId != null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.explore, color: AppColors.primary),
          title: Text(journeyTitle ?? 'Kaldığın yerden devam et', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('$journeyTitle > %${((journeyProgress ?? 0) * 100).toInt()}'),
          trailing: SizedBox(width: 60, child: LinearProgressIndicator(value: journeyProgress, color: AppColors.primary, backgroundColor: Theme.of(context).colorScheme.surfaceVariant)),
          onTap: () {
            context.pushIslamic(JourneyScreen(initialModuleId: journeyModuleId));
          },
        ),
      );
    } else if (libraryTitle != null && libraryId != null && libraryCategory != null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.book, color: AppColors.primary),
          title: Text(libraryTitle ?? 'Kaldığın yerden devam et', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('$libraryTitle'),
          onTap: () {
            context.pushWithTransition(
              LibraryScreen(initialCategory: libraryCategory, initialId: libraryId),
              type: PageTransitionType.fade,
            );
          },
        ),
      );
    } else {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.play_arrow, color: AppColors.primary),
          title: Text('Kaldığın yerden devam et', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Devam eden içerik yok. Hemen başlamak için tıkla!'),
          onTap: () {
            context.pushWithTransition(
              LibraryScreen(initialCategory: 'zikr'),
              type: PageTransitionType.slideUp,
            );
          },
        ),
      );
    }
  }
}

class PrayerSettingsDialog extends StatefulWidget {
  final String prayerName;
  final String prayerTime;
  const PrayerSettingsDialog({required this.prayerName, required this.prayerTime, Key? key}) : super(key: key);
  @override
  State<PrayerSettingsDialog> createState() => _PrayerSettingsDialogState();
}

class _PrayerSettingsDialogState extends State<PrayerSettingsDialog> {
  bool _notificationEnabled = false;
  int _minutesBefore = 10;
  String _selectedSound = 'Varsayılan';
  final List<String> _soundOptions = ['Varsayılan', 'Ezan', 'Bip', 'Titreşim'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    int minVal = 0, maxVal = 60;
    int loaded = prefs.getInt('notif_${widget.prayerName}_minutes') ?? 10;
    setState(() {
      _notificationEnabled = prefs.getBool('notif_${widget.prayerName}_enabled') ?? false;
      _minutesBefore = loaded.clamp(minVal, maxVal);
      _selectedSound = prefs.getString('notif_${widget.prayerName}_sound') ?? 'Varsayılan';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_${widget.prayerName}_enabled', _notificationEnabled);
    await prefs.setInt('notif_${widget.prayerName}_minutes', _minutesBefore);
    await prefs.setString('notif_${widget.prayerName}_sound', _selectedSound);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.prayerName} ayarları kaydedildi.')),
    );
    await _planNotification();
  }

  Future<void> _planNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('last_city') ?? 'İstanbul';
    final url = 'https://api.aladhan.com/v1/timingsByCity?city=$city&country=Turkey&method=2';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return;
    final data = json.decode(response.body);
    final timings = data['data']['timings'];
    final now = DateTime.now();
    final vakitMap = {
      'İMSAK': timings['Fajr'],
      'GÜNEŞ': timings['Sunrise'],
      'ÖĞLE': timings['Dhuhr'],
      'İKİNDİ': timings['Asr'],
      'AKŞAM': timings['Maghrib'],
      'YATSI': timings['Isha'],
    };
    final t = vakitMap[widget.prayerName];
    if (t == null) return;
    final parts = t.split(':');
    // Cihazın local saatine göre DateTime oluştur
    DateTime vakitTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    if (vakitTime.isBefore(now)) {
      vakitTime = vakitTime.add(Duration(days: 1));
    }
    final notifTime = vakitTime.subtract(Duration(minutes: _minutesBefore));
    if (notifTime.isAfter(now) && _notificationEnabled) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        100 + widget.prayerName.hashCode,
        '${widget.prayerName} Vakti Yaklaşıyor',
        '${widget.prayerName} namazı için $_minutesBefore dakika kaldı.',
        tz.TZDateTime.from(notifTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_id',
            'Test Kanalı',
            channelDescription: 'Test açıklaması',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            sound: _selectedSound == 'Varsayılan' ? null : RawResourceAndroidNotificationSound(_selectedSound.toLowerCase()),
            playSound: true,
            enableVibration: _selectedSound == 'Titreşim',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.prayerName} Ayarları'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            value: _notificationEnabled,
            onChanged: (v) => setState(() => _notificationEnabled = v),
            title: Text('Bildirim Açık'),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text('Kaç dakika önce:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _minutesBefore.toDouble(),
                  min: 0,
                  max: 60,
                  divisions: 12,
                  label: '$_minutesBefore dk',
                  onChanged: (v) => setState(() => _minutesBefore = v.round()),
                ),
              ),
              SizedBox(width: 8),
              Text('$_minutesBefore dk'),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text('Bildirim Sesi:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedSound,
                  isExpanded: true,
                  items: _soundOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedSound = v!),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        AppButton(
          text: 'İptal',
          type: AppButtonType.text,
          size: AppButtonSize.medium,
          onPressed: () => Navigator.pop(context),
          semanticLabel: 'İptal',
        ),
        AppButton(
          text: 'Kaydet',
          type: AppButtonType.primary,
          size: AppButtonSize.medium,
          onPressed: _saveSettings,
          semanticLabel: 'Ayarları kaydet',
        ),
      ],
    );
  }
}