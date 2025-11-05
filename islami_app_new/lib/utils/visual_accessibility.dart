import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Visual accessibility helper sınıfı
class VisualAccessibilityHelper {
  /// High contrast mode aktif mi kontrol et
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Text scaling factor'ü al
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  /// Bold text aktif mi kontrol et
  static bool isBoldTextEnabled(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// Accessibility features aktif mi kontrol et
  static bool hasAccessibilityFeatures(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.highContrast || 
           mediaQuery.boldText || 
           mediaQuery.textScaleFactor > 1.0;
  }

  /// Renk kontrastını hesapla (WCAG standartlarına göre)
  static double calculateContrast(Color color1, Color color2) {
    final luminance1 = _calculateLuminance(color1);
    final luminance2 = _calculateLuminance(color2);
    
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Rengin luminance değerini hesapla
  static double _calculateLuminance(Color color) {
    final r = _linearizeColorComponent(color.red / 255.0);
    final g = _linearizeColorComponent(color.green / 255.0);
    final b = _linearizeColorComponent(color.blue / 255.0);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Renk bileşenini linearize et
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return ((component + 0.055) / 1.055).pow(2.4);
    }
  }

  /// WCAG AA standardına uygun mu kontrol et (4.5:1 kontrast)
  static bool meetsWCAGAA(Color foreground, Color background) {
    return calculateContrast(foreground, background) >= 4.5;
  }

  /// WCAG AAA standardına uygun mu kontrol et (7:1 kontrast)
  static bool meetsWCAGAAA(Color foreground, Color background) {
    return calculateContrast(foreground, background) >= 7.0;
  }

  /// Büyük text için WCAG AA standardına uygun mu kontrol et (3:1 kontrast)
  static bool meetsWCAGAALargeText(Color foreground, Color background) {
    return calculateContrast(foreground, background) >= 3.0;
  }

  /// Rengi high contrast mode için optimize et
  static Color optimizeForHighContrast(Color color, bool isBackground) {
    if (isBackground) {
      // Arka plan renkleri için
      return color.computeLuminance() > 0.5 ? Colors.white : Colors.black;
    } else {
      // Metin renkleri için
      return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    }
  }

  /// Color-blind friendly renk paleti
  static const Map<String, Color> colorBlindFriendlyColors = {
    'primary': Color(0xFF0173B2),      // Mavi
    'secondary': Color(0xFFDE8F05),    // Turuncu
    'success': Color(0xFF029E73),      // Yeşil
    'warning': Color(0xFFD55E00),      // Kırmızı-turuncu
    'error': Color(0xFFCC78BC),        // Pembe
    'info': Color(0xFF56B4E9),         // Açık mavi
    'neutral': Color(0xFF999999),      // Gri
  };

  /// Color-blind friendly renk al
  static Color getColorBlindFriendlyColor(String colorName) {
    return colorBlindFriendlyColors[colorName] ?? Colors.grey;
  }

  /// Rengin color-blind friendly versiyonunu al
  static Color makeColorBlindFriendly(Color originalColor) {
    // Rengi HSV'ye çevir
    final hsv = HSVColor.fromColor(originalColor);
    
    // Hue değerini color-blind friendly aralıklara ayarla
    double newHue = hsv.hue;
    
    if (newHue >= 0 && newHue < 60) {
      // Kırmızı -> Turuncu
      newHue = 30;
    } else if (newHue >= 60 && newHue < 180) {
      // Yeşil -> Mavi
      newHue = 210;
    } else if (newHue >= 180 && newHue < 300) {
      // Mavi -> Mavi (değişiklik yok)
      newHue = 210;
    } else {
      // Mor/Pembe -> Pembe
      newHue = 300;
    }
    
    return hsv.withHue(newHue).toColor();
  }

  /// Text size'ı accessibility ayarlarına göre optimize et
  static double optimizeTextSize(BuildContext context, double baseSize) {
    final textScaleFactor = getTextScaleFactor(context);
    final scaledSize = baseSize * textScaleFactor;
    
    // Minimum ve maksimum sınırlar
    return scaledSize.clamp(12.0, 32.0);
  }

  /// Icon size'ı accessibility ayarlarına göre optimize et
  static double optimizeIconSize(BuildContext context, double baseSize) {
    final textScaleFactor = getTextScaleFactor(context);
    final scaledSize = baseSize * textScaleFactor;
    
    // Icon'lar için minimum ve maksimum sınırlar
    return scaledSize.clamp(16.0, 48.0);
  }

  /// Padding'i accessibility ayarlarına göre optimize et
  static EdgeInsets optimizePadding(BuildContext context, EdgeInsets basePadding) {
    final textScaleFactor = getTextScaleFactor(context);
    
    return EdgeInsets.fromLTRB(
      basePadding.left * textScaleFactor,
      basePadding.top * textScaleFactor,
      basePadding.right * textScaleFactor,
      basePadding.bottom * textScaleFactor,
    );
  }
}

/// High contrast theme provider
class HighContrastTheme {
  /// High contrast light theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    dividerColor: Colors.black,
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      bodySmall: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      labelLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      labelMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      labelSmall: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 3),
      ),
    ),
  );

  /// High contrast dark theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: Colors.black,
    cardColor: Colors.black,
    dividerColor: Colors.white,
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      bodySmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      labelMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      labelSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 2),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white, width: 3),
      ),
    ),
  );
}

/// Visual accessibility widget wrapper
class VisualAccessibilityWrapper extends StatelessWidget {
  final Widget child;
  final bool enableHighContrast;
  final bool enableColorBlindSupport;
  final bool enableTextScaling;

  const VisualAccessibilityWrapper({
    Key? key,
    required this.child,
    this.enableHighContrast = true,
    this.enableColorBlindSupport = true,
    this.enableTextScaling = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget result = child;

    // High contrast desteği
    if (enableHighContrast && VisualAccessibilityHelper.isHighContrastEnabled(context)) {
      result = Theme(
        data: Theme.of(context).brightness == Brightness.light
            ? HighContrastTheme.lightTheme
            : HighContrastTheme.darkTheme,
        child: result,
      );
    }

    // Text scaling desteği
    if (enableTextScaling) {
      final textScaleFactor = VisualAccessibilityHelper.getTextScaleFactor(context);
      if (textScaleFactor > 1.0) {
        result = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: textScaleFactor.clamp(1.0, 2.0),
          ),
          child: result,
        );
      }
    }

    return result;
  }
}

/// Accessible text widget
class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? semanticLabel;

  const AccessibleText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.semanticLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final optimizedStyle = _optimizeTextStyle(context, style);
    
    return Semantics(
      label: semanticLabel ?? text,
      child: Text(
        text,
        style: optimizedStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }

  TextStyle? _optimizeTextStyle(BuildContext context, TextStyle? baseStyle) {
    if (baseStyle == null) return null;

    final fontSize = baseStyle.fontSize ?? 14.0;
    final optimizedSize = VisualAccessibilityHelper.optimizeTextSize(context, fontSize);
    
    TextStyle optimizedStyle = baseStyle.copyWith(fontSize: optimizedSize);

    // Bold text desteği
    if (VisualAccessibilityHelper.isBoldTextEnabled(context)) {
      optimizedStyle = optimizedStyle.copyWith(
        fontWeight: FontWeight.bold,
      );
    }

    // High contrast desteği
    if (VisualAccessibilityHelper.isHighContrastEnabled(context)) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      optimizedStyle = optimizedStyle.copyWith(
        color: isDark ? Colors.white : Colors.black,
      );
    }

    return optimizedStyle;
  }
}

/// Accessible icon widget
class AccessibleIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  const AccessibleIcon(
    this.icon, {
    Key? key,
    this.size,
    this.color,
    this.semanticLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseSize = size ?? 24.0;
    final optimizedSize = VisualAccessibilityHelper.optimizeIconSize(context, baseSize);
    
    Color? optimizedColor = color;
    if (VisualAccessibilityHelper.isHighContrastEnabled(context)) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      optimizedColor = isDark ? Colors.white : Colors.black;
    }

    return Semantics(
      label: semanticLabel,
      child: Icon(
        icon,
        size: optimizedSize,
        color: optimizedColor,
      ),
    );
  }
}

/// MediaQuery extensions for visual accessibility
extension VisualAccessibilityExtensions on BuildContext {
  /// High contrast aktif mi
  bool get isHighContrastEnabled => VisualAccessibilityHelper.isHighContrastEnabled(this);
  
  /// Bold text aktif mi
  bool get isBoldTextEnabled => VisualAccessibilityHelper.isBoldTextEnabled(this);
  
  /// Text scale factor
  double get textScaleFactor => VisualAccessibilityHelper.getTextScaleFactor(this);
  
  /// Accessibility features aktif mi
  bool get hasAccessibilityFeatures => VisualAccessibilityHelper.hasAccessibilityFeatures(this);
  
  /// Text size'ı optimize et
  double optimizeTextSize(double baseSize) => VisualAccessibilityHelper.optimizeTextSize(this, baseSize);
  
  /// Icon size'ı optimize et
  double optimizeIconSize(double baseSize) => VisualAccessibilityHelper.optimizeIconSize(this, baseSize);
  
  /// Padding'i optimize et
  EdgeInsets optimizePadding(EdgeInsets basePadding) => VisualAccessibilityHelper.optimizePadding(this, basePadding);
}

/// Color extensions for accessibility
extension ColorAccessibilityExtensions on Color {
  /// Bu rengin kontrast oranını başka bir renkle hesapla
  double contrastWith(Color other) => VisualAccessibilityHelper.calculateContrast(this, other);
  
  /// WCAG AA standardına uygun mu
  bool meetsWCAGAA(Color background) => VisualAccessibilityHelper.meetsWCAGAA(this, background);
  
  /// WCAG AAA standardına uygun mu
  bool meetsWCAGAAA(Color background) => VisualAccessibilityHelper.meetsWCAGAAA(this, background);
  
  /// Color-blind friendly versiyonunu al
  Color get colorBlindFriendly => VisualAccessibilityHelper.makeColorBlindFriendly(this);
  
  /// High contrast için optimize et
  Color optimizeForHighContrast({bool isBackground = false}) => 
    VisualAccessibilityHelper.optimizeForHighContrast(this, isBackground);
}

/// Double extension for pow function
extension DoubleExtensions on double {
  double pow(double exponent) {
    return ui.lerpDouble(1.0, this, exponent) ?? this;
  }
}