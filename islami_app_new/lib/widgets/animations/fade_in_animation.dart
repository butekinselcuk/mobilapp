import 'package:flutter/material.dart';
import '../../theme/dimensions.dart';

/// Fade in animasyonu widget'ı
/// Çocuk widget'ı belirli bir süre sonra fade in efektiyle gösterir
class FadeInAnimation extends StatefulWidget {
  /// Animasyon yapılacak çocuk widget
  final Widget child;
  
  /// Animasyon süresi
  final Duration duration;
  
  /// Animasyon gecikmesi
  final Duration delay;
  
  /// Animasyon eğrisi
  final Curve curve;
  
  /// Başlangıç opacity değeri
  final double initialOpacity;
  
  /// Bitiş opacity değeri
  final double finalOpacity;
  
  /// Animasyon tamamlandığında çağrılacak callback
  final VoidCallback? onComplete;

  const FadeInAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: AppDimensions.animationNormal),
    this.delay = Duration.zero,
    this.curve = Curves.easeInOut,
    this.initialOpacity = 0.0,
    this.finalOpacity = 1.0,
    this.onComplete,
  }) : super(key: key);

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _opacityAnimation = Tween<double>(
      begin: widget.initialOpacity,
      end: widget.finalOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
    
    // Gecikme ile animasyonu başlat
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// Staggered fade in animasyonu
/// Birden fazla widget'ı sırayla fade in yapar
class StaggeredFadeInAnimation extends StatelessWidget {
  /// Animasyon yapılacak çocuk widget'lar
  final List<Widget> children;
  
  /// Her animasyon arasındaki gecikme
  final Duration staggerDelay;
  
  /// Her animasyonun süresi
  final Duration duration;
  
  /// Animasyon eğrisi
  final Curve curve;
  
  /// Ana eksen yönü
  final Axis direction;
  
  /// Ana eksen hizalaması
  final MainAxisAlignment mainAxisAlignment;
  
  /// Çapraz eksen hizalaması
  final CrossAxisAlignment crossAxisAlignment;

  const StaggeredFadeInAnimation({
    Key? key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: AppDimensions.animationNormal),
    this.curve = Curves.easeInOut,
    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final animatedChildren = children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      
      return FadeInAnimation(
        delay: Duration(milliseconds: staggerDelay.inMilliseconds * index),
        duration: duration,
        curve: curve,
        child: child,
      );
    }).toList();

    if (direction == Axis.vertical) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: animatedChildren,
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: animatedChildren,
      );
    }
  }
}