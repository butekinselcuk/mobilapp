# UI/UX İyileştirmeleri - Tasarım Belgesi

## Genel Bakış

Bu tasarım belgesi, İslami App'in Flutter frontend'inde modern, tutarlı ve kullanıcı dostu bir deneyim oluşturmak için gerekli UI/UX iyileştirmelerini detaylandırır. Mevcut Material 3 teması üzerine inşa edilerek, İslami uygulamanın kimliğine uygun özel bileşenler ve tasarım sistemi geliştirilecektir.

## Mimari

### Tasarım Sistemi Mimarisi

```
lib/
├── theme/
│   ├── app_theme.dart          # Ana tema tanımları
│   ├── colors.dart             # Renk paleti
│   ├── typography.dart         # Font ve metin stilleri
│   └── dimensions.dart         # Spacing, radius vb. sabitler
├── widgets/
│   ├── shared/
│   │   ├── app_card.dart       # Tutarlı kart bileşeni
│   │   ├── app_button.dart     # Tutarlı buton bileşeni
│   │   ├── app_input.dart      # Tutarlı input bileşeni
│   │   ├── app_modal.dart      # Modal wrapper
│   │   └── loading_states.dart # Loading animasyonları
│   ├── navigation/
│   │   ├── custom_bottom_nav.dart
│   │   └── page_transitions.dart
│   └── animations/
│       ├── fade_in_animation.dart
│       ├── slide_animation.dart
│       └── skeleton_loader.dart
└── screens/
    └── [mevcut ekranlar - güncellenecek]
```

## Bileşenler ve Arayüzler

### 1. Tasarım Token'ları

#### Renk Paleti
```dart
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF00695C);
  static const Color primaryLight = Color(0xFF4DB6AC);
  static const Color primaryDark = Color(0xFF004D40);
  
  // Secondary Colors
  static const Color secondary = Color(0xFFFFAB00);
  static const Color secondaryLight = Color(0xFFFFD54F);
  static const Color secondaryDark = Color(0xFFFF8F00);
  
  // Neutral Colors
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF5F5F5);
  static const Color onSurface = Color(0xFF212121);
  static const Color onBackground = Color(0xFF212121);
  
  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2196F3);
  
  // Islamic Theme Colors
  static const Color islamicGreen = Color(0xFF00695C);
  static const Color islamicGold = Color(0xFFFFAB00);
  static const Color prayerTime = Color(0xFFE8F5E8);
}
```

#### Tipografi
```dart
class AppTypography {
  static const String fontFamily = 'Inter';
  
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static const TextStyle body1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
}
```

#### Boyutlar ve Spacing
```dart
class AppDimensions {
  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  
  // Elevation
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
}
```

### 2. Temel Bileşenler

#### AppCard Bileşeni
```dart
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? elevation;
  final Color? color;
  final VoidCallback? onTap;
  final bool showHoverEffect;
  
  // Modern kart tasarımı ile tutarlı görünüm
}
```

#### AppButton Bileşeni
```dart
enum AppButtonType { primary, secondary, outline, text }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  
  // Tutarlı buton tasarımı ve animasyonları
}
```

#### AppInput Bileşeni
```dart
class AppInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  
  // Modern input tasarımı ve validasyon
}
```

### 3. Ana Sayfa Yeniden Tasarımı

#### Namaz Vakitleri Kartı
- **Gradient Arka Plan**: Sabah/akşam saatlerine göre dinamik gradient
- **Canlı Geri Sayım**: Büyük, okunabilir font ile vurgulanan geri sayım
- **Vakit Göstergeleri**: Horizontal scroll ile tüm vakitler
- **Konum Göstergesi**: GPS ikonu ile mevcut şehir

#### AI Asistanı Kartı
- **Dark Theme**: Koyu arka plan ile premium görünüm
- **Gelişmiş Input**: Placeholder animasyonları ve suggestion chips
- **Cevap Baloncukları**: Modern chat bubble tasarımı
- **Kaynak Gösterimi**: Expandable kaynak kartları

#### Hızlı Erişim Grid'i
- **3x2 Grid Layout**: Responsive grid sistemi
- **Icon + Label**: Büyük ikonlar ve açıklayıcı etiketler
- **Hover Efektleri**: Subtle scale ve shadow animasyonları
- **Kategori Renkleri**: Her kategori için özel renk kodlaması

### 4. Navigasyon Sistemi

#### Custom Bottom Navigation
```dart
class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  
  // Features:
  // - Animated indicator
  // - Badge support for notifications
  // - Haptic feedback
  // - Accessibility support
}
```

#### Page Transitions
```dart
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final PageTransitionType type;
  
  // Transition types:
  // - Slide (left, right, up, down)
  // - Fade
  // - Scale
  // - Custom Islamic-themed transitions
}
```

### 5. Modal ve Dialog Sistemi

#### AppModal Wrapper
```dart
class AppModal extends StatelessWidget {
  final Widget child;
  final bool dismissible;
  final String? title;
  final List<Widget>? actions;
  
  // Features:
  // - Backdrop blur effect
  // - Smooth slide-up animation
  // - Consistent padding and styling
  // - Keyboard handling
}
```

#### Loading States
```dart
class AppLoadingState extends StatelessWidget {
  final LoadingType type;
  final String? message;
  
  // Loading types:
  // - Spinner with Islamic geometric patterns
  // - Skeleton loaders for content
  // - Progress indicators
  // - Shimmer effects
}
```

## Veri Modelleri

### Theme Configuration
```dart
class AppThemeConfig {
  final bool isDarkMode;
  final double textScale;
  final bool highContrast;
  final bool reduceAnimations;
  
  // User preferences for accessibility and customization
}
```

### Animation Configuration
```dart
class AnimationConfig {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve elasticOut = Curves.elasticOut;
}
```

## Hata Yönetimi

### Error State Components
```dart
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final ErrorType type;
  
  // Error types:
  // - Network error
  // - Authentication error
  // - Validation error
  // - Generic error
}
```

### Form Validation
```dart
class AppFormValidator {
  static String? validateEmail(String? value);
  static String? validatePassword(String? value);
  static String? validateRequired(String? value);
  
  // Consistent validation with Islamic context
}
```

## Test Stratejisi

### Widget Testing
- **Bileşen Testleri**: Her custom widget için unit testler
- **Integration Testleri**: Ekran akışları için integration testler
- **Golden Testleri**: UI regression testleri için screenshot karşılaştırmaları

### Accessibility Testing
- **Screen Reader**: TalkBack/VoiceOver uyumluluğu
- **Keyboard Navigation**: Tab order ve focus management
- **Color Contrast**: WCAG 2.1 AA standartlarına uygunluk
- **Text Scaling**: Büyük font boyutlarında kullanılabilirlik

### Performance Testing
- **Animation Performance**: 60 FPS hedefi
- **Memory Usage**: Widget rebuild optimizasyonları
- **Bundle Size**: Asset optimizasyonu
- **Load Times**: Lazy loading ve caching stratejileri

## Responsive Tasarım Stratejisi

### Breakpoint Sistemi
```dart
class AppBreakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;
}
```

### Layout Adaptasyonu
- **Mobile First**: Önce mobil tasarım, sonra büyük ekranlar
- **Flexible Grid**: Flutter'ın Flex sistemi ile responsive grid
- **Adaptive Components**: Ekran boyutuna göre component davranışları
- **Orientation Support**: Portrait/landscape mode adaptasyonu

## Animasyon ve Mikro-etkileşimler

### Transition Animations
- **Page Transitions**: Smooth sayfa geçişleri
- **Modal Animations**: Bottom sheet ve dialog animasyonları
- **List Animations**: Staggered list item animasyonları
- **Loading Animations**: Skeleton ve shimmer efektleri

### Micro-interactions
- **Button Feedback**: Press, hover ve focus durumları
- **Input Feedback**: Focus, error ve success durumları
- **Card Interactions**: Hover, tap ve swipe efektleri
- **Navigation Feedback**: Tab değişimi ve sayfa geçiş animasyonları

## Erişilebilirlik (Accessibility)

### Semantic Markup
- **Proper Labels**: Tüm interactive elementler için semantic labels
- **Focus Management**: Logical tab order ve focus indicators
- **Screen Reader Support**: Meaningful content descriptions
- **Keyboard Navigation**: Full keyboard accessibility

### Visual Accessibility
- **High Contrast Mode**: Yüksek kontrast tema desteği
- **Text Scaling**: Dynamic type support
- **Color Independence**: Renk körü kullanıcılar için alternatif gösterimler
- **Motion Sensitivity**: Reduced motion preferences

Bu tasarım belgesi, İslami App'in modern, erişilebilir ve kullanıcı dostu bir arayüze kavuşması için gerekli tüm bileşenleri ve stratejileri detaylandırmaktadır.