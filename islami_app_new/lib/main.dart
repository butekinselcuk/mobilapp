import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'screens/user_data_screen.dart';
import 'screens/assistant_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/admin_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/journey_screen.dart';
import 'screens/library_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/theme_provider.dart';
// --- Push Notification ---
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show AndroidFlutterLocalNotificationsPlugin, AndroidInitializationSettings, AndroidNotificationDetails, InitializationSettings, NotificationDetails, UILocalNotificationDateInterpretation, DateTimeComponents, AndroidScheduleMode;
// --- Timezone ---
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';
// --- Yeni Tema Sistemi ---
import 'theme/app_theme.dart';
// --- Yeni Navigasyon Sistemi ---
import 'widgets/navigation/custom_bottom_nav.dart';
import 'widgets/navigation/page_transitions.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Bildirim kanalı oluştur
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'channel_id',
    'Test Kanalı',
    description: 'Test açıklaması',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Android 13+ için bildirim izni iste
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

Future<void> scheduleTestNotification() async {
  final now = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
  await flutterLocalNotificationsPlugin.zonedSchedule(
    999,
    'Test Bildirimi',
    '10 saniye sonra gelen mesaj',
    now,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'channel_id',
        'Test Kanalı',
        channelDescription: 'Test açıklaması',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exact,
  );
}

class SplashScreen extends StatefulWidget {
  final VoidCallback onLoaded;
  const SplashScreen({required this.onLoaded, Key? key}) : super(key: key);
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _startLoading() async {
    // Ağır işlemleri paralel başlat
    await Future.wait([
      Future.microtask(() => dotenv.load(fileName: "assets/.env")),
      Future.microtask(() => _initNotifications()),
      Future.delayed(Duration(milliseconds: 800)), // Logo animasyonu için kısa bekleme
    ]);
    widget.onLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Beyaz arkaplan
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mosque, size: 80, color: Colors.green[700]),
            SizedBox(height: 24),
            Text('İslami App', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green[900])),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Colors.green[700]),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  await dotenv.load(fileName: "assets/.env");
  await _initNotifications();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: IslamiApp(),
    ),
  );
}

class IslamiApp extends StatefulWidget {
  @override
  State<IslamiApp> createState() => _IslamiAppState();
}

class _IslamiAppState extends State<IslamiApp> {
  String? _jwtToken;
  bool _loading = true;
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    // Splash sonrası yükleme başlatılacak
  }

  void _onSplashLoaded() async {
    await _checkAuth();
    setState(() { _splashDone = true; });
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _jwtToken = prefs.getString('jwt_token');
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    setState(() {
      _jwtToken = null;
    });
    // Çıkıştan sonra giriş ekranına kesin geçiş
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => AuthScreen(onLogin: _onLogin)),
          (route) => false,
        );
      }
    });
  }

  void _onLogin(String token) {
    setState(() {
      _jwtToken = token;
    });
    // Girişten sonra ana navigasyona kesin geçiş
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainNavigation(onLogout: _logout, jwtToken: token)),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return MaterialApp(
        home: SplashScreen(onLoaded: _onSplashLoaded),
        debugShowCheckedModeBanner: false,
      );
    }
    if (_loading) {
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'İslami App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: _jwtToken == null
              ? AuthScreen(onLogin: _onLogin)
              : MainNavigation(onLogout: _logout, jwtToken: _jwtToken!),
          routes: {
            '/user_data': (context) => UserDataScreen(),
            '/premium': (context) => PremiumScreen(),
            '/onboarding': (context) => OnboardingScreen(onDone: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => AuthScreen(onLogin: (token) {})),
              );
            }),
          },
        );
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  final void Function(String token) onLogin;
  const AuthScreen({required this.onLogin, Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool showLogin = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: showLogin
                ? LoginScreen(
                    key: const ValueKey('login_screen'),
                    onLoginSuccess: widget.onLogin,
                  )
                : RegisterScreen(
                    key: const ValueKey('register_screen'),
                    onRegisterSuccess: () {
                      setState(() {
                        showLogin = true;
                      });
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: TextButton(
              onPressed: () {
                setState(() {
                  showLogin = !showLogin;
                });
              },
              child: Text(showLogin ? 'Kayıt Ol' : 'Giriş Yap'),
            ),
          ),
        ],
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final VoidCallback onLogout;
  final String jwtToken;
  const MainNavigation({required this.onLogout, required this.jwtToken, Key? key}) : super(key: key);
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  bool _isAdmin = false;
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileAndBuildPages();
  }

  Future<void> _fetchProfileAndBuildPages() async {
    final apiUrl = dotenv.env['API_URL'] ?? '';
    final storage = FlutterSecureStorage();
    final token = widget.jwtToken;
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(json.decode(response.body));
        print('PROFILE DATA: $data');
        setState(() {
          _isAdmin = data['is_admin'] ?? false;
          print('_isAdmin:  [32m [1m [4m [7m$_isAdmin [0m');
          _buildPages();
          _profileLoaded = true;
        });
      } else {
        print('PROFILE ERROR: ${response.body}');
        setState(() {
          _isAdmin = false;
          _buildPages();
          _profileLoaded = true;
        });
      }
    } catch (e) {
      print('PROFILE EXCEPTION: $e');
      setState(() {
        _isAdmin = false;
        _buildPages();
        _profileLoaded = true;
      });
    }
  }

  void _buildPages() {
    _pages = <Widget>[
      HomeScreen(),
      LibraryScreen(),
      AssistantScreen(),
      JourneyScreen(),
      ProfileScreen(onAccountDeleted: widget.onLogout),
      if (_isAdmin) AdminScreen(),
    ];
    
    // Eğer admin değilse ve admin sekmesindeyse ana sayfaya yönlendir
    if (!_isAdmin && _selectedIndex >= 5) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('BUILD: _isAdmin=$_isAdmin, _profileLoaded=$_profileLoaded');
    if (!_profileLoaded) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Yükleniyor...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Navigation item'larını dinamik oluştur
    final navItems = <BottomNavItem>[
      BottomNavItems.home(),
      BottomNavItems.library(),
      BottomNavItems.assistant(),
      BottomNavItems.journey(),
      BottomNavItems.profile(),
      if (_isAdmin) BottomNavItems.admin(),
    ];

    // _selectedIndex sınırını kontrol et
    final maxIndex = _pages.length - 1;
    final selectedIndex = _selectedIndex > maxIndex ? maxIndex : _selectedIndex;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Daha smooth bir geçiş animasyonu
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.02, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        child: Container(
          key: ValueKey<int>(selectedIndex),
          child: _pages[selectedIndex],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        items: navItems,
        currentIndex: selectedIndex,
        onTap: (index) {
          // Admin sekmesi kontrolü
          if (index >= 5 && !_isAdmin) {
            // Admin değilse admin sekmesine erişimi engelle
            return;
          }
          
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}