import 'package:flutter/material.dart';
import '../../theme/dimensions.dart';

/// Page transition tipleri
enum PageTransitionType {
  /// Sağdan sola slide
  slideRight,
  /// Soldan sağa slide
  slideLeft,
  /// Yukarıdan aşağıya slide
  slideUp,
  /// Aşağıdan yukarıya slide
  slideDown,
  /// Fade geçiş
  fade,
  /// Scale geçiş
  scale,
  /// Rotate geçiş
  rotate,
  /// İslami tema özel geçiş
  islamicSlide,
  /// Modal tarzı geçiş
  modal,
  /// Hiçbir animasyon
  none,
}

/// Özel page route sınıfı
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final PageTransitionType type;
  final Duration duration;
  final Duration reverseDuration;
  final Curve curve;
  final Curve reverseCurve;
  final bool maintainState;
  final bool fullscreenDialog;

  AppPageRoute({
    required this.child,
    this.type = PageTransitionType.slideRight,
    this.duration = const Duration(milliseconds: AppDimensions.animationNormal),
    Duration? reverseDuration,
    this.curve = Curves.easeInOut,
    this.reverseCurve = Curves.easeInOut,
    this.maintainState = true,
    this.fullscreenDialog = false,
    RouteSettings? settings,
  })  : reverseDuration = reverseDuration ?? duration,
        super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration ?? duration,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
          settings: settings,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (type) {
      case PageTransitionType.slideRight:
        return _buildSlideTransition(
          animation,
          secondaryAnimation,
          child,
          const Offset(1.0, 0.0),
        );
      case PageTransitionType.slideLeft:
        return _buildSlideTransition(
          animation,
          secondaryAnimation,
          child,
          const Offset(-1.0, 0.0),
        );
      case PageTransitionType.slideUp:
        return _buildSlideTransition(
          animation,
          secondaryAnimation,
          child,
          const Offset(0.0, 1.0),
        );
      case PageTransitionType.slideDown:
        return _buildSlideTransition(
          animation,
          secondaryAnimation,
          child,
          const Offset(0.0, -1.0),
        );
      case PageTransitionType.fade:
        return _buildFadeTransition(animation, child);
      case PageTransitionType.scale:
        return _buildScaleTransition(animation, child);
      case PageTransitionType.rotate:
        return _buildRotateTransition(animation, child);
      case PageTransitionType.islamicSlide:
        return _buildIslamicSlideTransition(animation, secondaryAnimation, child);
      case PageTransitionType.modal:
        return _buildModalTransition(animation, secondaryAnimation, child);
      case PageTransitionType.none:
        return child;
    }
  }

  Widget _buildSlideTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    Offset beginOffset,
  ) {
    final slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: curve,
    ));

    final secondarySlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-beginOffset.dx * 0.3, -beginOffset.dy * 0.3),
    ).animate(CurvedAnimation(
      parent: secondaryAnimation,
      curve: reverseCurve,
    ));

    return Stack(
      children: [
        SlideTransition(
          position: secondarySlideAnimation,
          child: child,
        ),
        SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      ],
    );
  }

  Widget _buildFadeTransition(
    Animation<double> animation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
      child: child,
    );
  }

  Widget _buildScaleTransition(
    Animation<double> animation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  Widget _buildRotateTransition(
    Animation<double> animation,
    Widget child,
  ) {
    return RotationTransition(
      turns: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      )),
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        )),
        child: child,
      ),
    );
  }

  Widget _buildIslamicSlideTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuart,
    ));

    final scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    return SlideTransition(
      position: slideAnimation,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      ),
    );
  }

  Widget _buildModalTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}

/// Navigator extension'ları
extension NavigatorExtensions on NavigatorState {
  /// Özel geçiş ile sayfa açma
  Future<T?> pushWithTransition<T extends Object?>(
    Widget page, {
    PageTransitionType type = PageTransitionType.slideRight,
    Duration? duration,
    Curve? curve,
    RouteSettings? settings,
  }) {
    return push<T>(
      AppPageRoute<T>(
        child: page,
        type: type,
        duration: duration ?? const Duration(milliseconds: AppDimensions.animationNormal),
        curve: curve ?? Curves.easeInOut,
        settings: settings,
      ),
    );
  }

  /// Özel geçiş ile sayfa değiştirme
  Future<T?> pushReplacementWithTransition<T extends Object?, TO extends Object?>(
    Widget page, {
    PageTransitionType type = PageTransitionType.slideRight,
    Duration? duration,
    Curve? curve,
    TO? result,
    RouteSettings? settings,
  }) {
    return pushReplacement<T, TO>(
      AppPageRoute<T>(
        child: page,
        type: type,
        duration: duration ?? const Duration(milliseconds: AppDimensions.animationNormal),
        curve: curve ?? Curves.easeInOut,
        settings: settings,
      ),
      result: result,
    );
  }

  /// Modal tarzı sayfa açma
  Future<T?> pushModal<T extends Object?>(
    Widget page, {
    Duration? duration,
    Curve? curve,
    RouteSettings? settings,
  }) {
    return push<T>(
      AppPageRoute<T>(
        child: page,
        type: PageTransitionType.modal,
        duration: duration ?? const Duration(milliseconds: AppDimensions.animationNormal),
        curve: curve ?? Curves.easeOutCubic,
        fullscreenDialog: true,
        settings: settings,
      ),
    );
  }

  /// İslami tema geçiş
  Future<T?> pushIslamic<T extends Object?>(
    Widget page, {
    Duration? duration,
    RouteSettings? settings,
  }) {
    return push<T>(
      AppPageRoute<T>(
        child: page,
        type: PageTransitionType.islamicSlide,
        duration: duration ?? const Duration(milliseconds: AppDimensions.animationNormal),
        curve: Curves.easeOutQuart,
        settings: settings,
      ),
    );
  }

  /// Fade geçiş
  Future<T?> pushFade<T extends Object?>(
    Widget page, {
    Duration? duration,
    RouteSettings? settings,
  }) {
    return push<T>(
      AppPageRoute<T>(
        child: page,
        type: PageTransitionType.fade,
        duration: duration ?? const Duration(milliseconds: AppDimensions.animationNormal),
        curve: Curves.easeInOut,
        settings: settings,
      ),
    );
  }
}

/// BuildContext extension'ları
extension BuildContextNavigationExtensions on BuildContext {
  /// Özel geçiş ile sayfa açma
  Future<T?> pushWithTransition<T extends Object?>(
    Widget page, {
    PageTransitionType type = PageTransitionType.slideRight,
    Duration? duration,
    Curve? curve,
    RouteSettings? settings,
  }) {
    return Navigator.of(this).pushWithTransition<T>(
      page,
      type: type,
      duration: duration,
      curve: curve,
      settings: settings,
    );
  }

  /// Modal tarzı sayfa açma
  Future<T?> pushModal<T extends Object?>(
    Widget page, {
    Duration? duration,
    Curve? curve,
    RouteSettings? settings,
  }) {
    return Navigator.of(this).pushModal<T>(
      page,
      duration: duration,
      curve: curve,
      settings: settings,
    );
  }

  /// İslami tema geçiş
  Future<T?> pushIslamic<T extends Object?>(
    Widget page, {
    Duration? duration,
    RouteSettings? settings,
  }) {
    return Navigator.of(this).pushIslamic<T>(
      page,
      duration: duration,
      settings: settings,
    );
  }

  /// Fade geçiş
  Future<T?> pushFade<T extends Object?>(
    Widget page, {
    Duration? duration,
    RouteSettings? settings,
  }) {
    return Navigator.of(this).pushFade<T>(
      page,
      duration: duration,
      settings: settings,
    );
  }
}

/// Önceden tanımlanmış route'lar
class AppRoutes {
  /// Ana sayfa route'u
  static Route<T> home<T>() {
    return AppPageRoute<T>(
      child: Container(), // HomeScreen buraya gelecek
      type: PageTransitionType.fade,
      settings: const RouteSettings(name: '/home'),
    );
  }

  /// Profil route'u
  static Route<T> profile<T>() {
    return AppPageRoute<T>(
      child: Container(), // ProfileScreen buraya gelecek
      type: PageTransitionType.slideRight,
      settings: const RouteSettings(name: '/profile'),
    );
  }

  /// Ayarlar route'u
  static Route<T> settings<T>() {
    return AppPageRoute<T>(
      child: Container(), // SettingsScreen buraya gelecek
      type: PageTransitionType.slideUp,
      settings: const RouteSettings(name: '/settings'),
    );
  }

  /// Modal route'u
  static Route<T> modal<T>(Widget child) {
    return AppPageRoute<T>(
      child: child,
      type: PageTransitionType.modal,
      fullscreenDialog: true,
    );
  }
}

/// Route generator
class AppRouteGenerator {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/home':
        return AppRoutes.home();
      case '/profile':
        return AppRoutes.profile();
      case '/settings':
        return AppRoutes.settings();
      default:
        return null;
    }
  }
}

/// Hero animasyonları için yardımcı sınıf
class AppHeroAnimations {
  /// Kart hero animasyonu
  static Widget cardHero({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }

  /// Avatar hero animasyonu
  static Widget avatarHero({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      child: child,
    );
  }

  /// İkon hero animasyonu
  static Widget iconHero({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}