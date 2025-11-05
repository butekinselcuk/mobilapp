import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// İslami App için responsive boyut ve spacing sistemi
/// Tutarlı tasarım için standart boyutlar
class AppDimensions {
  // Responsive Spacing Values - Responsive boşluk değerleri
  static double xs(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 4.0,
    tablet: 6.0,
    desktop: 8.0,
  );
  
  static double sm(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 8.0,
    tablet: 10.0,
    desktop: 12.0,
  );
  
  static double md(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 16.0,
    tablet: 20.0,
    desktop: 24.0,
  );
  
  static double lg(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 24.0,
    tablet: 28.0,
    desktop: 32.0,
  );
  
  static double xl(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 32.0,
    tablet: 40.0,
    desktop: 48.0,
  );
  
  static double xxl(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 48.0,
    tablet: 56.0,
    desktop: 64.0,
  );
  
  static double xxxl(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 64.0,
    tablet: 72.0,
    desktop: 80.0,
  );
  
  // Backward compatibility methods - Geriye uyumluluk için
  static double paddingXs(BuildContext context) => _paddingXs;
  static double paddingSm(BuildContext context) => _paddingSm;
  static double paddingMd(BuildContext context) => _paddingMd;
  static double paddingLg(BuildContext context) => _paddingLg;
  static double paddingXl(BuildContext context) => _paddingXl;
  
  static double marginXs(BuildContext context) => _marginXs;
  static double marginSm(BuildContext context) => _marginSm;
  static double marginMd(BuildContext context) => _marginMd;
  static double marginLg(BuildContext context) => _marginLg;
  static double marginXl(BuildContext context) => _marginXl;
  
  static double radiusXs(BuildContext context) => _radiusXs;
  static double radiusSm(BuildContext context) => _radiusSm;
  static double radiusMd(BuildContext context) => _radiusMd;
  static double radiusLg(BuildContext context) => _radiusLg;
  static double radiusXl(BuildContext context) => _radiusXl;
  static double radiusXxl(BuildContext context) => _radiusXxl;
  
  static double iconXs(BuildContext context) => _iconXs;
  static double iconSm(BuildContext context) => _iconSm;
  static double iconMd(BuildContext context) => _iconMd;
  static double iconLg(BuildContext context) => _iconLg;
  static double iconXl(BuildContext context) => _iconXl;
  static double iconXxl(BuildContext context) => _iconXxl;
  
  // Static Values - Sabit değerler (sadece metodlar aracılığıyla erişilebilir)
  static const double _paddingXs = 4.0;
  static const double _paddingSm = 8.0;
  static const double _paddingMd = 16.0;
  static const double _paddingLg = 24.0;
  static const double _paddingXl = 32.0;

  static const double _marginXs = 4.0;
  static const double _marginSm = 8.0;
  static const double _marginMd = 16.0;
  static const double _marginLg = 24.0;
  static const double _marginXl = 32.0;
  
  static const double _radiusXs = 4.0;
  static const double _radiusSm = 8.0;
  static const double _radiusMd = 12.0;
  static const double _radiusLg = 16.0;
  static const double _radiusXl = 20.0;
  static const double _radiusXxl = 24.0;
  static const double radiusRound = 50.0;
  
  static const double elevationNone = 0.0;
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 12.0;
  static const double elevationXxl = 16.0;
  
  static const double _iconXs = 16.0;
  static const double _iconSm = 20.0;
  static const double _iconMd = 24.0;
  static const double _iconLg = 32.0;
  static const double _iconXl = 48.0;
  static const double _iconXxl = 64.0;
  
  // Direct access to static values
  static double get paddingXsStatic => _paddingXs;
  static double get paddingSmStatic => _paddingSm;
  static double get paddingMdStatic => _paddingMd;
  static double get paddingLgStatic => _paddingLg;
  static double get paddingXlStatic => _paddingXl;
  
  static double get marginXsStatic => _marginXs;
  static double get marginSmStatic => _marginSm;
  static double get marginMdStatic => _marginMd;
  static double get marginLgStatic => _marginLg;
  static double get marginXlStatic => _marginXl;
  
  static double get radiusXsStatic => _radiusXs;
  static double get radiusSmStatic => _radiusSm;
  static double get radiusMdStatic => _radiusMd;
  static double get radiusLgStatic => _radiusLg;
  static double get radiusXlStatic => _radiusXl;
  static double get radiusXxlStatic => _radiusXxl;
  
  static double get iconXsStatic => _iconXs;
  static double get iconSmStatic => _iconSm;
  static double get iconMdStatic => _iconMd;
  static double get iconLgStatic => _iconLg;
  static double get iconXlStatic => _iconXl;
  static double get iconXxlStatic => _iconXxl;
  
  // Responsive Button Dimensions - Responsive buton boyutları
  static double buttonHeightSm(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 32.0,
    tablet: 36.0,
    desktop: 40.0,
  );
  
  static double buttonHeightMd(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 40.0,
    tablet: 44.0,
    desktop: 48.0,
  );
  
  static double buttonHeightLg(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 48.0,
    tablet: 52.0,
    desktop: 56.0,
  );
  
  static double buttonHeightXl(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 56.0,
    tablet: 60.0,
    desktop: 64.0,
  );
  
  static double buttonPaddingHorizontalSm(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 12.0,
    tablet: 14.0,
    desktop: 16.0,
  );
  
  static double buttonPaddingHorizontalMd(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 16.0,
    tablet: 18.0,
    desktop: 20.0,
  );
  
  static double buttonPaddingHorizontalLg(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 24.0,
    tablet: 26.0,
    desktop: 28.0,
  );
  
  // Input Field Dimensions - Input alanı boyutları
  static const double inputHeight = 48.0;
  static const double inputPaddingHorizontal = 16.0;
  static const double inputPaddingVertical = 12.0;
  static const double inputBorderWidth = 1.0;
  
  // Responsive Card Dimensions - Responsive kart boyutları
  static double cardPadding(BuildContext context) => md(context);
  static double cardMargin(BuildContext context) => sm(context);
  static const double cardElevation = 2.0;
  static double cardRadius(BuildContext context) => radiusMd(context);
  
  // App Bar Dimensions - App bar boyutları
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 2.0;
  
  // Bottom Navigation Dimensions - Alt navigasyon boyutları
  static const double bottomNavHeight = 80.0;
  static const double bottomNavIconSize = 24.0;
  static const double bottomNavElevation = 8.0;
  
  // Modal Dimensions - Modal boyutları
  static const double modalRadius = 16.0;
  static const double modalPadding = 24.0;
  static const double modalMaxWidth = 400.0;
  
  // List Item Dimensions - Liste öğesi boyutları
  static const double listItemHeight = 56.0;
  static const double listItemPadding = 16.0;
  
  // Avatar Dimensions - Avatar boyutları
  static const double avatarSm = 32.0;
  static const double avatarMd = 40.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 80.0;
  
  // Responsive Prayer Time Card - Responsive namaz vakti kartı
  static double prayerTimeCardPadding(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 16.0,
    tablet: 20.0,
    desktop: 24.0,
  );
  
  static double prayerTimeCardRadius(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 16.0,
    tablet: 18.0,
    desktop: 20.0,
  );
  
  static const double prayerTimeCardElevation = 2.0;
  
  static double prayerTimeItemWidth(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 60.0,
    tablet: 70.0,
    desktop: 80.0,
  );
  
  static double prayerTimeItemHeight(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 50.0,
    tablet: 55.0,
    desktop: 60.0,
  );

  // Responsive AI Assistant Card - Responsive AI asistanı kartı
  static double aiCardPadding(BuildContext context) => md(context);
  static double aiCardRadius(BuildContext context) => radiusLg(context);
  
  static double aiInputHeight(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 40.0,
    tablet: 44.0,
    desktop: 48.0,
  );
  
  static double aiChipHeight(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 32.0,
    tablet: 36.0,
    desktop: 40.0,
  );

  // Responsive Quick Access Button - Responsive hızlı erişim buton
  static double quickButtonHeight(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 80.0,
    tablet: 90.0,
    desktop: 100.0,
  );
  
  static double quickButtonRadius(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 14.0,
    tablet: 16.0,
    desktop: 18.0,
  );
  
  static double quickButtonIconSize(BuildContext context) => ResponsiveHelper.getResponsiveValue(
    context,
    mobile: 22.0,
    tablet: 26.0,
    desktop: 30.0,
  );
  
  // Responsive Breakpoints - Responsive kırılma noktaları
  static const double mobileBreakpoint = 480.0;
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;
  static const double largeDesktopBreakpoint = 1440.0;
  
  // Animation Durations - Animasyon süreleri (milliseconds)
  static const int animationFast = 200;
  static const int animationNormal = 300;
  static const int animationSlow = 500;
  static const int animationVerySlow = 800;
  
  // Z-Index Values - Katman sıralaması
  static const int zIndexModal = 1000;
  static const int zIndexTooltip = 1100;
  static const int zIndexDropdown = 1200;
  static const int zIndexOverlay = 1300;
}