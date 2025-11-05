import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../widgets/app_card.dart';
import '../widgets/app_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/dimensions.dart';
import '../main.dart';
import '../screens/premium_screen.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  final Function()? onAccountDeleted;

  const ProfileScreen({Key? key, this.onAccountDeleted}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = '';
  String email = '';
  bool isPremium = false;
  bool isLoading = true;
  
  // TTS ayarları
  FlutterTts flutterTts = FlutterTts();
  List<String> ttsLanguages = [];
  List<Map<String, dynamic>> ttsVoices = [];
  String? ttsLanguage;
  String? ttsVoice;
  double ttsSpeed = 1.0;
  double ttsPitch = 1.0;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _initTts();
  }

  Future<void> _initTts() async {
    await _loadTtsSettings();
    await _loadLanguages();
    await _loadVoices();
  }

  Future<void> _loadTtsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      ttsLanguage = prefs.getString('tts_language') ?? 'tr-TR';
      ttsVoice = prefs.getString('tts_voice');
      ttsSpeed = prefs.getDouble('tts_speed') ?? 1.0;
      ttsPitch = prefs.getDouble('tts_pitch') ?? 1.0;
    });
  }

  Future<void> _saveTtsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tts_language', ttsLanguage ?? 'tr-TR');
    if (ttsVoice != null) await prefs.setString('tts_voice', ttsVoice!);
    await prefs.setDouble('tts_speed', ttsSpeed);
    await prefs.setDouble('tts_pitch', ttsPitch);
    
    await flutterTts.setLanguage(ttsLanguage!);
    await flutterTts.setSpeechRate(ttsSpeed);
    await flutterTts.setPitch(ttsPitch);
    if (ttsVoice != null && ttsLanguage != null) {
      await flutterTts.setVoice({'name': ttsVoice!, 'locale': ttsLanguage!});
    }
  }

  Future<void> _loadLanguages() async {
    final languages = await flutterTts.getLanguages;
    setState(() {
      ttsLanguages = List<String>.from(languages ?? []);
      if (!ttsLanguages.contains(ttsLanguage)) {
        ttsLanguage = ttsLanguages.isNotEmpty ? ttsLanguages.first : 'tr-TR';
      }
    });
  }

  Future<void> _loadVoices() async {
    if (ttsLanguage != null) {
      await flutterTts.setLanguage(ttsLanguage!);
      final voices = await flutterTts.getVoices;
      setState(() {
        // Type casting sorununu düzelt
        final voicesList = voices as List<dynamic>? ?? [];
        ttsVoices = voicesList
            .map((voice) => Map<String, dynamic>.from(voice as Map))
            .where((voice) => voice['locale']?.toString().startsWith(ttsLanguage!.split('-')[0]) == true)
            .toList();
        if (ttsVoices.isNotEmpty && !ttsVoices.any((v) => v['name'] == ttsVoice)) {
          ttsVoice = ttsVoices.first['name'];
        }
      });
    }
  }

  Future<void> _testTts() async {
    await _saveTtsSettings();
    await flutterTts.speak('Bu bir test mesajıdır.');
  }

  Future<void> _fetchProfile() async {
    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
      
      if (token == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('$apiUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userName = data['username'] ?? '';
          email = data['email'] ?? '';
          isPremium = data['isPremium'] ?? false;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Profil',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppDimensions.paddingLgStatic),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil Bilgileri Kartı
                  AppCard(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: AppDimensions.paddingMdStatic),
                        Text(
                          userName.isNotEmpty ? userName : 'Kullanıcı',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppDimensions.paddingSmStatic),
                        Text(
                          email.isNotEmpty ? email : 'email@example.com',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? AppColors.darkTextSecondary 
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (isPremium) ...[
                          SizedBox(height: AppDimensions.paddingMdStatic),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingMdStatic,
                              vertical: AppDimensions.paddingSmStatic,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSmStatic),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.workspace_premium,
                                  color: AppColors.warning,
                                  size: 16,
                                ),
                                SizedBox(width: AppDimensions.paddingSmStatic),
                                Text(
                                  'Premium Üye',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  SizedBox(height: AppDimensions.paddingLgStatic),
                  
                  // Hesap İşlemleri Bölümü
                  Text(
                    'Hesap İşlemleri',
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppDimensions.paddingMdStatic),
                  
                  // Premium Kartı
                  AppCard(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PremiumScreen(),
                        ),
                      );
                      _fetchProfile();
                    },
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppDimensions.paddingSmStatic),
                        decoration: BoxDecoration(
                          color: isPremium ? AppColors.warning.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                        ),
                        child: Icon(
                          Icons.workspace_premium,
                          color: isPremium ? AppColors.warning : AppColors.primary,
                        ),
                      ),
                      title: Text(
                        isPremium ? 'Premium Üyelik Aktif' : 'Premium\'a Geç',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isPremium ? 'Tüm özelliklere erişiminiz var' : 'Sınırsız erişim için premium olun',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppDimensions.paddingMdStatic),
                  
                  // Geçmiş & Favoriler Kartı
                  AppCard(
                    onTap: () {
                      Navigator.pushNamed(context, '/user_data');
                    },
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppDimensions.paddingSmStatic),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                        ),
                        child: Icon(
                          Icons.history,
                          color: AppColors.info,
                        ),
                      ),
                      title: Text(
                        'Geçmiş & Favoriler',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Okuma geçmişinizi ve favorilerinizi görüntüleyin',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppDimensions.paddingMdStatic),
                  
                  // Bilgileri Güncelle Kartı
                  AppCard(
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => _UpdateProfileDialog(
                          initialUsername: userName,
                          initialEmail: email,
                          onUpdated: (newUsername, newEmail) {
                            setState(() {
                              userName = newUsername;
                              email = newEmail;
                            });
                          },
                        ),
                      );
                    },
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppDimensions.paddingSmStatic),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: AppColors.success,
                        ),
                      ),
                      title: Text(
                        'Bilgileri Güncelle',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Kullanıcı adı ve e-posta adresinizi değiştirin',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppDimensions.paddingMdStatic),
                  
                  // Şifre Değiştir Kartı
                  AppCard(
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => _ChangePasswordDialog(),
                      );
                    },
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppDimensions.paddingSmStatic),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                        ),
                        child: Icon(
                          Icons.lock_reset,
                          color: AppColors.warning,
                        ),
                      ),
                      title: Text(
                        'Şifre Değiştir',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Hesap güvenliğiniz için şifrenizi güncelleyin',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppDimensions.paddingLgStatic),
                  
                  // Sesli Okuma Ayarları
                  Text(
                    'Sesli Okuma Ayarları',
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppDimensions.paddingMdStatic),
                  
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dil Seçimi
                        Text(
                          'Dil Seçimi',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: AppDimensions.paddingSmStatic),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.paddingMdStatic,
                            vertical: AppDimensions.paddingSmStatic,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                          ),
                          child: DropdownButton<String>(
                            value: ttsLanguages.contains(ttsLanguage) ? ttsLanguage : (ttsLanguages.isNotEmpty ? ttsLanguages.first : null),
                            isExpanded: true,
                            underline: SizedBox(),
                            items: ttsLanguages.toSet().map((l) => DropdownMenuItem<String>(
                              value: l,
                              child: Text(l),
                            )).toList(),
                            onChanged: (v) async {
                              setState(() { ttsLanguage = v; ttsVoice = null; });
                              await flutterTts.setLanguage(v!);
                              await _saveTtsSettings();
                              _loadVoices();
                            },
                          ),
                        ),
                        
                        SizedBox(height: AppDimensions.paddingMdStatic),
                        
                        // Okuma Hızı
                        Text(
                          'Okuma Hızı: ${ttsSpeed.toStringAsFixed(1)}x',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Slider(
                          value: ttsSpeed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 6,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() { ttsSpeed = v; _saveTtsSettings(); }),
                        ),
                        
                        SizedBox(height: AppDimensions.paddingMdStatic),
                        
                        // Ses Tonu
                        Text(
                          'Ses Tonu: ${ttsPitch.toStringAsFixed(1)}',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Slider(
                          value: ttsPitch,
                          min: 0.5,
                          max: 2.0,
                          divisions: 6,
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(() { ttsPitch = v; _saveTtsSettings(); }),
                        ),
                        
                        SizedBox(height: AppDimensions.paddingMdStatic),
                        
                        // Ses Seçimi
                        Text(
                          'Ses Seçimi',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: AppDimensions.paddingSmStatic),
                        
                        if (ttsVoices.isEmpty)
                          Container(
                            padding: EdgeInsets.all(AppDimensions.paddingMdStatic),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                            ),
                            child: Text(
                              'Bu dil için cihazınızda ses bulunamadı. Cihaz ayarlarından yeni ses/dil yükleyebilirsiniz.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        
                        if (ttsVoices.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimensions.paddingMdStatic,
                              vertical: AppDimensions.paddingSmStatic,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                            ),
                            child: DropdownButton<String>(
                              value: ttsVoices.any((v) => v['name'] == ttsVoice) ? ttsVoice : (ttsVoices.isNotEmpty ? ttsVoices.first['name'] as String : null),
                              isExpanded: true,
                              underline: SizedBox(),
                              items: ttsVoices
                                .where((v) => v['name'] is String)
                                .map<DropdownMenuItem<String>>((v) => DropdownMenuItem<String>(
                                  value: v['name'] as String,
                                  child: Text(v['name'] ?? ''),
                                )).toList(),
                              onChanged: (v) => setState(() { ttsVoice = v; _saveTtsSettings(); }),
                            ),
                          ),
                        
                        SizedBox(height: AppDimensions.paddingLgStatic),
                        
                        // Test ve Kaydet Butonları
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Test Et',
                                isOutlined: true,
                                icon: Icons.volume_up,
                                onPressed: _testTts,
                              ),
                            ),
                            SizedBox(width: AppDimensions.paddingMdStatic),
                            Expanded(
                              child: AppButton(
                                text: 'Kaydet',
                                backgroundColor: AppColors.primary,
                                icon: Icons.save,
                                onPressed: _saveTtsSettings,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: AppDimensions.paddingLgStatic),
                  
                  // Tema Ayarları
                  Text(
                    'Tema Ayarları',
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppDimensions.paddingMdStatic),
                  
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tema Seçimi',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: AppDimensions.paddingMdStatic),
                        
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return Column(
                              children: [
                                // Açık Tema
                                GestureDetector(
                                  onTap: () {
                                    themeProvider.setTheme(ThemeMode.light);
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: AppDimensions.paddingSmStatic),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: themeProvider.themeMode == ThemeMode.light 
                                            ? AppColors.primary 
                                            : (Theme.of(context).brightness == Brightness.dark 
                                                ? AppColors.borderDark 
                                                : AppColors.borderLight),
                                        width: themeProvider.themeMode == ThemeMode.light ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(AppDimensions.paddingMdStatic),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: AppColors.cardLight,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.borderLight),
                                            ),
                                            child: Icon(
                                              Icons.light_mode,
                                              color: Colors.orange,
                                              size: 24,
                                            ),
                                          ),
                                          SizedBox(width: AppDimensions.paddingMdStatic),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Açık Tema',
                                                  style: AppTypography.titleSmall.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  'Beyaz arka plan ile rahat okuma',
                                                  style: AppTypography.bodySmall.copyWith(
                                                    color: Theme.of(context).brightness == Brightness.dark 
                                                        ? AppColors.darkTextSecondary 
                                                        : AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Radio<ThemeMode>(
                                            value: ThemeMode.light,
                                            groupValue: themeProvider.themeMode,
                                            activeColor: AppColors.primary,
                                            onChanged: (ThemeMode? value) {
                                              if (value != null) {
                                                themeProvider.setTheme(value);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Koyu Tema
                                GestureDetector(
                                  onTap: () {
                                    themeProvider.setTheme(ThemeMode.dark);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: themeProvider.themeMode == ThemeMode.dark 
                                            ? AppColors.primary 
                                            : (Theme.of(context).brightness == Brightness.dark 
                                                ? AppColors.borderDark 
                                                : AppColors.borderLight),
                                        width: themeProvider.themeMode == ThemeMode.dark ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(AppDimensions.paddingMdStatic),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).brightness == Brightness.dark 
                                                  ? AppColors.darkSurface 
                                                  : AppColors.darkSurface,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderDark),
                                            ),
                                            child: Icon(
                                              Icons.dark_mode,
                                              color: Theme.of(context).brightness == Brightness.dark 
                                                  ? AppColors.primaryLight 
                                                  : AppColors.primary,
                                              size: 24,
                                            ),
                                          ),
                                          SizedBox(width: AppDimensions.paddingMdStatic),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Koyu Tema',
                                                  style: AppTypography.titleSmall.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  'Siyah arka plan ile göz dostu okuma',
                                                  style: AppTypography.bodySmall.copyWith(
                                                    color: Theme.of(context).brightness == Brightness.dark 
                                                        ? AppColors.darkTextSecondary 
                                                        : AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Radio<ThemeMode>(
                                            value: ThemeMode.dark,
                                            groupValue: themeProvider.themeMode,
                                            activeColor: AppColors.primary,
                                            onChanged: (ThemeMode? value) {
                                              if (value != null) {
                                                themeProvider.setTheme(value);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: AppDimensions.paddingLgStatic),
                  
                  // Tehlikeli İşlemler Bölümü
                  Text(
                    'Tehlikeli İşlemler',
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: AppDimensions.paddingMdStatic),
                  
                  // Hesabı Sil Kartı
                  AppCard(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Hesabı Sil'),
                          content: Text('Hesabınızı kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Vazgeç')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Evet, Sil')),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final apiUrl = dotenv.env['API_URL'] ?? '';
                        final storage = FlutterSecureStorage();
                        final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');
                        try {
                          final response = await http.delete(
                            Uri.parse('$apiUrl/user/delete'),
                            headers: {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                            },
                          );
                          if (response.statusCode == 200) {
                            await storage.delete(key: 'jwt_token');
                            await storage.delete(key: 'flutter_jwt_token');
                            if (widget.onAccountDeleted != null) widget.onAccountDeleted!();
                            if (!mounted) return;
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hesap silinemedi: ${response.body}')));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                        }
                      }
                    },
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppDimensions.paddingSmStatic),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                        ),
                        child: Icon(
                          Icons.delete_forever,
                          color: AppColors.error,
                        ),
                      ),
                      title: Text(
                        'Hesabı Sil',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      subtitle: Text(
                        'Hesabınızı kalıcı olarak silin (Geri alınamaz)',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppDimensions.paddingMdStatic),
                  
                  // Çıkış Yap Kartı
                  AppCard(
                    onTap: () async {
                      final storage = FlutterSecureStorage();
                      await storage.delete(key: 'jwt_token');
                      await storage.delete(key: 'flutter_jwt_token');
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => AuthScreen(onLogin: (token) {})),
                        (route) => false,
                      );
                    },
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppDimensions.paddingSmStatic),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
                        ),
                        child: Icon(
                          Icons.logout,
                          color: AppColors.error,
                        ),
                      ),
                      title: Text(
                        'Çıkış Yap',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      subtitle: Text(
                        'Hesabınızdan güvenli bir şekilde çıkış yapın',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? AppColors.darkTextSecondary 
                              : AppColors.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? AppColors.darkTextSecondary 
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppDimensions.paddingLgStatic),
                ],
              ),
            ),
    );
  }
}

// Profil Güncelleme Dialog'u
class _UpdateProfileDialog extends StatefulWidget {
  final String initialUsername;
  final String initialEmail;
  final Function(String, String) onUpdated;

  const _UpdateProfileDialog({
    required this.initialUsername,
    required this.initialEmail,
    required this.onUpdated,
  });

  @override
  _UpdateProfileDialogState createState() => _UpdateProfileDialogState();
}

class _UpdateProfileDialogState extends State<_UpdateProfileDialog> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_usernameController.text.trim().isEmpty || _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');

      final response = await http.put(
        Uri.parse('$apiUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        widget.onUpdated(_usernameController.text.trim(), _emailController.text.trim());
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil başarıyla güncellendi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme başarısız: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Profili Güncelle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Kullanıcı Adı',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: AppDimensions.paddingMdStatic),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'E-posta',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateProfile,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Güncelle'),
        ),
      ],
    );
  }
}

// Şifre Değiştirme Dialog'u
class _ChangePasswordDialog extends StatefulWidget {
  @override
  _ChangePasswordDialogState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yeni şifreler eşleşmiyor')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yeni şifre en az 6 karakter olmalıdır')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiUrl = dotenv.env['API_URL'] ?? '';
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token') ?? await storage.read(key: 'flutter_jwt_token');

      final response = await http.put(
        Uri.parse('$apiUrl/user/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şifre başarıyla değiştirildi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şifre değiştirme başarısız: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Şifre Değiştir'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _currentPasswordController,
            decoration: InputDecoration(
              labelText: 'Mevcut Şifre',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
              ),
            ),
            obscureText: _obscureCurrentPassword,
          ),
          SizedBox(height: AppDimensions.paddingMdStatic),
          TextField(
            controller: _newPasswordController,
            decoration: InputDecoration(
              labelText: 'Yeni Şifre',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
            ),
            obscureText: _obscureNewPassword,
          ),
          SizedBox(height: AppDimensions.paddingMdStatic),
          TextField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Yeni Şifre (Tekrar)',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            obscureText: _obscureConfirmPassword,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Değiştir'),
        ),
      ],
    );
  }
}