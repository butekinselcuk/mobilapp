import 'package:flutter/material.dart';
import '../../theme/dimensions.dart';
import 'slide_animation.dart';
import 'fade_in_animation.dart';

/// Animasyon konfigürasyonu ve yardımcı sınıflar
class AnimationConfig {
  // Animasyon süreleri
  static const Duration fast = Duration(milliseconds: AppDimensions.animationFast);
  static const Duration normal = Duration(milliseconds: AppDimensions.animationNormal);
  static const Duration slow = Duration(milliseconds: AppDimensions.animationSlow);
  static const Duration verySlow = Duration(milliseconds: AppDimensions.animationVerySlow);
  
  // Animasyon eğrileri
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOutCubic = Curves.easeOutCubic;
  static const Curve easeOutBack = Curves.easeOutBack;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve elasticOut = Curves.elasticOut;
  
  // İslami tema için özel eğriler
  static const Curve islamicGentle = Curves.easeInOutQuart;
  static const Curve islamicSpring = Curves.elasticOut;
  static const Curve islamicSmooth = Curves.easeOutExpo;
  
  // Stagger gecikmeleri
  static const Duration staggerShort = Duration(milliseconds: 50);
  static const Duration staggerMedium = Duration(milliseconds: 100);
  static const Duration staggerLong = Duration(milliseconds: 150);
  
  // Page transition süreleri
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration modalTransition = Duration(milliseconds: 250);
  static const Duration dialogTransition = Duration(milliseconds: 200);
}

/// Animasyon yardımcı fonksiyonları
class AnimationHelpers {
  /// Gecikme ile animasyon başlatma
  static Future<void> delayedStart(
    AnimationController controller,
    Duration delay,
  ) async {
    await Future.delayed(delay);
    if (!controller.isDisposed) {
      controller.forward();
    }
  }
  
  /// Animasyon durumunu kontrol etme
  static bool isAnimating(AnimationController controller) {
    return controller.status == AnimationStatus.forward ||
           controller.status == AnimationStatus.reverse;
  }
  
  /// Animasyonu güvenli şekilde durdurma
  static void safeStop(AnimationController controller) {
    if (!controller.isDisposed && isAnimating(controller)) {
      controller.stop();
    }
  }
  
  /// Animasyonu güvenli şekilde sıfırlama
  static void safeReset(AnimationController controller) {
    if (!controller.isDisposed) {
      controller.reset();
    }
  }
  
  /// Staggered animasyon için gecikme hesaplama
  static Duration calculateStaggerDelay(
    int index,
    Duration baseDelay,
    {int maxItems = 10}
  ) {
    final clampedIndex = index.clamp(0, maxItems - 1);
    return Duration(
      milliseconds: baseDelay.inMilliseconds * clampedIndex,
    );
  }
}

/// Önceden tanımlanmış animasyon kombinasyonları
class AnimationPresets {
  /// Kart giriş animasyonu
  static Widget cardEntrance({
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    return SlideScaleAnimation(
      delay: delay,
      duration: AnimationConfig.normal,
      curve: AnimationConfig.easeOutBack,
      slideDirection: SlideDirection.bottomToTop,
      initialScale: 0.9,
      child: FadeInAnimation(
        delay: delay,
        duration: AnimationConfig.normal,
        curve: AnimationConfig.easeInOut,
        child: child,
      ),
    );
  }
  
  /// Liste öğesi giriş animasyonu
  static Widget listItemEntrance({
    required Widget child,
    required int index,
    Duration staggerDelay = AnimationConfig.staggerMedium,
  }) {
    final delay = AnimationHelpers.calculateStaggerDelay(index, staggerDelay);
    
    return SlideAnimation(
      delay: delay,
      duration: AnimationConfig.normal,
      curve: AnimationConfig.islamicGentle,
      direction: SlideDirection.rightToLeft,
      distance: 0.3,
      child: FadeInAnimation(
        delay: delay,
        duration: AnimationConfig.normal,
        child: child,
      ),
    );
  }
  
  /// Buton press animasyonu
  static Widget buttonPress({
    required Widget child,
    required VoidCallback onPressed,
  }) {
    return _ButtonPressAnimation(
      onPressed: onPressed,
      child: child,
    );
  }
  
  /// Modal giriş animasyonu
  static Widget modalEntrance({
    required Widget child,
  }) {
    return SlideAnimation(
      duration: AnimationConfig.modalTransition,
      curve: AnimationConfig.easeOutCubic,
      direction: SlideDirection.bottomToTop,
      distance: 0.3,
      child: FadeInAnimation(
        duration: AnimationConfig.modalTransition,
        curve: AnimationConfig.easeInOut,
        child: child,
      ),
    );
  }
  
  /// Loading pulse animasyonu
  static Widget loadingPulse({
    required Widget child,
  }) {
    return _PulseAnimation(child: child);
  }
}

/// Buton press animasyonu için özel widget
class _ButtonPressAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  
  const _ButtonPressAnimation({
    required this.child,
    required this.onPressed,
  });
  
  @override
  State<_ButtonPressAnimation> createState() => _ButtonPressAnimationState();
}

class _ButtonPressAnimationState extends State<_ButtonPressAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConfig.fast,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }
  
  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }
  
  void _handleTapCancel() {
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Pulse animasyonu için özel widget
class _PulseAnimation extends StatefulWidget {
  final Widget child;
  
  const _PulseAnimation({required this.child});
  
  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

