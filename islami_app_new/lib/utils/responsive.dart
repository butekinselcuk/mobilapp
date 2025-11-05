import 'package:flutter/material.dart';

/// Responsive breakpoint değerleri
class AppBreakpoints {
  /// Mobil cihazlar için maksimum genişlik
  static const double mobile = 600;
  
  /// Tablet cihazlar için maksimum genişlik
  static const double tablet = 1024;
  
  /// Desktop cihazlar için minimum genişlik
  static const double desktop = 1025;
  
  /// Geniş desktop ekranlar için minimum genişlik
  static const double wideDesktop = 1440;

  /// Küçük mobil cihazlar (eski telefonlar)
  static const double smallMobile = 360;
  
  /// Büyük mobil cihazlar
  static const double largeMobile = 480;
  
  /// Küçük tablet
  static const double smallTablet = 768;
  
  /// Büyük tablet
  static const double largeTablet = 1024;
}

/// Cihaz tipi enum'u
enum DeviceType {
  /// Küçük mobil (< 360px)
  smallMobile,
  /// Mobil (360px - 600px)
  mobile,
  /// Büyük mobil (480px - 600px)
  largeMobile,
  /// Küçük tablet (600px - 768px)
  smallTablet,
  /// Tablet (768px - 1024px)
  tablet,
  /// Desktop (1024px+)
  desktop,
  /// Geniş desktop (1440px+)
  wideDesktop,
}

/// Responsive yardımcı sınıfı
class ResponsiveHelper {
  /// Responsive değer döndüren yardımcı fonksiyon
  static T getResponsiveValue<T>(BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return desktop ?? tablet ?? mobile;
    }
  }

  /// Mevcut cihaz tipini döndürür
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < AppBreakpoints.smallMobile) {
      return DeviceType.smallMobile;
    } else if (width < AppBreakpoints.largeMobile) {
      return DeviceType.mobile;
    } else if (width < AppBreakpoints.mobile) {
      return DeviceType.largeMobile;
    } else if (width < AppBreakpoints.smallTablet) {
      return DeviceType.smallTablet;
    } else if (width < AppBreakpoints.tablet) {
      return DeviceType.tablet;
    } else if (width < AppBreakpoints.wideDesktop) {
      return DeviceType.desktop;
    } else {
      return DeviceType.wideDesktop;
    }
  }

  /// Mobil cihaz kontrolü
  static bool isMobile(BuildContext context) {
    final deviceType = getDeviceType(context);
    return deviceType == DeviceType.smallMobile ||
           deviceType == DeviceType.mobile ||
           deviceType == DeviceType.largeMobile;
  }

  /// Tablet cihaz kontrolü
  static bool isTablet(BuildContext context) {
    final deviceType = getDeviceType(context);
    return deviceType == DeviceType.smallTablet ||
           deviceType == DeviceType.tablet;
  }

  /// Desktop cihaz kontrolü
  static bool isDesktop(BuildContext context) {
    final deviceType = getDeviceType(context);
    return deviceType == DeviceType.desktop ||
           deviceType == DeviceType.wideDesktop;
  }

  /// Küçük ekran kontrolü (mobil + küçük tablet)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < AppBreakpoints.smallTablet;
  }

  /// Orta ekran kontrolü (tablet)
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppBreakpoints.smallTablet && width < AppBreakpoints.desktop;
  }

  /// Büyük ekran kontrolü (desktop)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppBreakpoints.desktop;
  }

  /// Grid sütun sayısını cihaz tipine göre döndürür
  static int getGridColumns(BuildContext context, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
  }) {
    if (isMobile(context)) {
      return mobileColumns;
    } else if (isTablet(context)) {
      return tabletColumns;
    } else {
      return desktopColumns;
    }
  }

  /// Padding değerini cihaz tipine göre döndürür
  static double getResponsivePadding(BuildContext context, {
    double mobilePadding = 16.0,
    double tabletPadding = 24.0,
    double desktopPadding = 32.0,
  }) {
    if (isMobile(context)) {
      return mobilePadding;
    } else if (isTablet(context)) {
      return tabletPadding;
    } else {
      return desktopPadding;
    }
  }

  /// Font boyutunu cihaz tipine göre döndürür
  static double getResponsiveFontSize(BuildContext context, {
    double mobileFontSize = 14.0,
    double tabletFontSize = 16.0,
    double desktopFontSize = 18.0,
  }) {
    if (isMobile(context)) {
      return mobileFontSize;
    } else if (isTablet(context)) {
      return tabletFontSize;
    } else {
      return desktopFontSize;
    }
  }

  /// Icon boyutunu cihaz tipine göre döndürür
  static double getResponsiveIconSize(BuildContext context, {
    double mobileIconSize = 24.0,
    double tabletIconSize = 28.0,
    double desktopIconSize = 32.0,
  }) {
    if (isMobile(context)) {
      return mobileIconSize;
    } else if (isTablet(context)) {
      return tabletIconSize;
    } else {
      return desktopIconSize;
    }
  }
}

/// MediaQuery extension'ları
extension MediaQueryExtensions on BuildContext {
  /// MediaQuery data'sını döndürür
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  
  /// Ekran boyutunu döndürür
  Size get screenSize => mediaQuery.size;
  
  /// Ekran genişliğini döndürür
  double get screenWidth => screenSize.width;
  
  /// Ekran yüksekliğini döndürür
  double get screenHeight => screenSize.height;
  
  /// Cihaz pixel ratio'sunu döndürür
  double get devicePixelRatio => mediaQuery.devicePixelRatio;
  
  /// Status bar yüksekliğini döndürür
  double get statusBarHeight => mediaQuery.padding.top;
  
  /// Bottom padding'i döndürür (safe area için)
  double get bottomPadding => mediaQuery.padding.bottom;
  
  /// Keyboard yüksekliğini döndürür
  double get keyboardHeight => mediaQuery.viewInsets.bottom;
  
  /// Keyboard açık mı kontrolü
  bool get isKeyboardOpen => keyboardHeight > 0;
  
  /// Cihaz tipini döndürür
  DeviceType get deviceType => ResponsiveHelper.getDeviceType(this);
  
  /// Mobil cihaz mı kontrolü
  bool get isMobile => ResponsiveHelper.isMobile(this);
  
  /// Tablet cihaz mı kontrolü
  bool get isTablet => ResponsiveHelper.isTablet(this);
  
  /// Desktop cihaz mı kontrolü
  bool get isDesktop => ResponsiveHelper.isDesktop(this);
  
  /// Küçük ekran mı kontrolü
  bool get isSmallScreen => ResponsiveHelper.isSmallScreen(this);
  
  /// Orta ekran mı kontrolü
  bool get isMediumScreen => ResponsiveHelper.isMediumScreen(this);
  
  /// Büyük ekran mı kontrolü
  bool get isLargeScreen => ResponsiveHelper.isLargeScreen(this);
  
  /// Landscape mode kontrolü
  bool get isLandscape => screenWidth > screenHeight;
  
  /// Portrait mode kontrolü
  bool get isPortrait => screenHeight > screenWidth;
  
  /// Responsive padding
  double responsivePadding({
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) => ResponsiveHelper.getResponsivePadding(
    this,
    mobilePadding: mobile,
    tabletPadding: tablet,
    desktopPadding: desktop,
  );
  
  /// Responsive font size
  double responsiveFontSize({
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
  }) => ResponsiveHelper.getResponsiveFontSize(
    this,
    mobileFontSize: mobile,
    tabletFontSize: tablet,
    desktopFontSize: desktop,
  );
  
  /// Responsive icon size
  double responsiveIconSize({
    double mobile = 24.0,
    double tablet = 28.0,
    double desktop = 32.0,
  }) => ResponsiveHelper.getResponsiveIconSize(
    this,
    mobileIconSize: mobile,
    tabletIconSize: tablet,
    desktopIconSize: desktop,
  );
}

/// Responsive widget builder
class ResponsiveBuilder extends StatelessWidget {
  /// Mobil widget builder
  final Widget Function(BuildContext context)? mobile;
  
  /// Tablet widget builder
  final Widget Function(BuildContext context)? tablet;
  
  /// Desktop widget builder
  final Widget Function(BuildContext context)? desktop;
  
  /// Fallback widget builder
  final Widget Function(BuildContext context)? fallback;

  const ResponsiveBuilder({
    Key? key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (context.isMobile && mobile != null) {
      return mobile!(context);
    } else if (context.isTablet && tablet != null) {
      return tablet!(context);
    } else if (context.isDesktop && desktop != null) {
      return desktop!(context);
    } else if (fallback != null) {
      return fallback!(context);
    } else {
      // En uygun widget'ı seç
      if (context.isMobile) {
        return (mobile ?? tablet ?? desktop ?? fallback)!(context);
      } else if (context.isTablet) {
        return (tablet ?? desktop ?? mobile ?? fallback)!(context);
      } else {
        return (desktop ?? tablet ?? mobile ?? fallback)!(context);
      }
    }
  }
}

/// Responsive değer seçici
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Context'e göre uygun değeri döndürür
  T getValue(BuildContext context) {
    if (context.isMobile) {
      return mobile;
    } else if (context.isTablet) {
      return tablet ?? mobile;
    } else {
      return desktop ?? tablet ?? mobile;
    }
  }
}

/// Responsive grid delegate
class ResponsiveGridDelegate {
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  const ResponsiveGridDelegate({
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
  });

  /// Ekran boyutuna göre uygun delegate döndürür
  SliverGridDelegateWithFixedCrossAxisCount getDelegate(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    int columns;
    
    if (width < AppBreakpoints.mobile) {
      columns = mobileColumns;
    } else if (width < AppBreakpoints.desktop) {
      columns = tabletColumns;
    } else {
      columns = desktopColumns;
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio,
    );
  }
}

/// Responsive container
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? mobileMaxWidth;
  final double? tabletMaxWidth;
  final double? desktopMaxWidth;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.mobileMaxWidth,
    this.tabletMaxWidth,
    this.desktopMaxWidth,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double? maxWidth;
    EdgeInsets? padding;

    if (context.isMobile) {
      maxWidth = mobileMaxWidth;
      padding = mobilePadding;
    } else if (context.isTablet) {
      maxWidth = tabletMaxWidth ?? mobileMaxWidth;
      padding = tabletPadding ?? mobilePadding;
    } else {
      maxWidth = desktopMaxWidth ?? tabletMaxWidth ?? mobileMaxWidth;
      padding = desktopPadding ?? tabletPadding ?? mobilePadding;
    }

    Widget result = child;

    if (padding != null) {
      result = Padding(padding: padding, child: result);
    }

    if (maxWidth != null) {
      result = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: result,
      );
    }

    return result;
  }
}

/// Responsive spacing
class ResponsiveSpacing {
  /// Responsive SizedBox height
  static Widget height(BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    final height = ResponsiveValue(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    ).getValue(context);
    
    return SizedBox(height: height);
  }

  /// Responsive SizedBox width
  static Widget width(BuildContext context, {
    double mobile = 8.0,
    double tablet = 12.0,
    double desktop = 16.0,
  }) {
    final width = ResponsiveValue(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    ).getValue(context);
    
    return SizedBox(width: width);
  }
}