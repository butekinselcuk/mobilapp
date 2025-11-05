import 'package:flutter/material.dart';
import '../../theme/dimensions.dart';

/// Slide animasyonu yönleri
enum SlideDirection {
  /// Soldan sağa
  leftToRight,
  /// Sağdan sola
  rightToLeft,
  /// Yukarıdan aşağıya
  topToBottom,
  /// Aşağıdan yukarıya
  bottomToTop,
}

/// Slide animasyonu widget'ı
/// Çocuk widget'ı belirli bir yönden slide in efektiyle gösterir
class SlideAnimation extends StatefulWidget {
  /// Animasyon yapılacak çocuk widget
  final Widget child;
  
  /// Slide yönü
  final SlideDirection direction;
  
  /// Animasyon süresi
  final Duration duration;
  
  /// Animasyon gecikmesi
  final Duration delay;
  
  /// Animasyon eğrisi
  final Curve curve;
  
  /// Slide mesafesi (0.0 - 1.0 arası)
  final double distance;
  
  /// Animasyon tamamlandığında çağrılacak callback
  final VoidCallback? onComplete;

  const SlideAnimation({
    Key? key,
    required this.child,
    this.direction = SlideDirection.bottomToTop,
    this.duration = const Duration(milliseconds: AppDimensions.animationNormal),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.distance = 1.0,
    this.onComplete,
  }) : super(key: key);

  @override
  State<SlideAnimation> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: _getBeginOffset(),
      end: Offset.zero,
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

  Offset _getBeginOffset() {
    switch (widget.direction) {
      case SlideDirection.leftToRight:
        return Offset(-widget.distance, 0.0);
      case SlideDirection.rightToLeft:
        return Offset(widget.distance, 0.0);
      case SlideDirection.topToBottom:
        return Offset(0.0, -widget.distance);
      case SlideDirection.bottomToTop:
        return Offset(0.0, widget.distance);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: widget.child,
        );
      },
    );
  }
}

/// Staggered slide animasyonu
/// Birden fazla widget'ı sırayla slide in yapar
class StaggeredSlideAnimation extends StatelessWidget {
  /// Animasyon yapılacak çocuk widget'lar
  final List<Widget> children;
  
  /// Slide yönü
  final SlideDirection direction;
  
  /// Her animasyon arasındaki gecikme
  final Duration staggerDelay;
  
  /// Her animasyonun süresi
  final Duration duration;
  
  /// Animasyon eğrisi
  final Curve curve;
  
  /// Ana eksen yönü
  final Axis axis;
  
  /// Ana eksen hizalaması
  final MainAxisAlignment mainAxisAlignment;
  
  /// Çapraz eksen hizalaması
  final CrossAxisAlignment crossAxisAlignment;

  const StaggeredSlideAnimation({
    Key? key,
    required this.children,
    this.direction = SlideDirection.bottomToTop,
    this.staggerDelay = const Duration(milliseconds: 100),
    this.duration = const Duration(milliseconds: AppDimensions.animationNormal),
    this.curve = Curves.easeOutCubic,
    this.axis = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final animatedChildren = children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      
      return SlideAnimation(
        direction: direction,
        delay: Duration(milliseconds: staggerDelay.inMilliseconds * index),
        duration: duration,
        curve: curve,
        child: child,
      );
    }).toList();

    if (axis == Axis.vertical) {
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

/// Scale ile birleşik slide animasyonu
class SlideScaleAnimation extends StatefulWidget {
  /// Animasyon yapılacak çocuk widget
  final Widget child;
  
  /// Slide yönü
  final SlideDirection slideDirection;
  
  /// Animasyon süresi
  final Duration duration;
  
  /// Animasyon gecikmesi
  final Duration delay;
  
  /// Animasyon eğrisi
  final Curve curve;
  
  /// Başlangıç scale değeri
  final double initialScale;
  
  /// Bitiş scale değeri
  final double finalScale;

  const SlideScaleAnimation({
    Key? key,
    required this.child,
    this.slideDirection = SlideDirection.bottomToTop,
    this.duration = const Duration(milliseconds: AppDimensions.animationNormal),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutBack,
    this.initialScale = 0.8,
    this.finalScale = 1.0,
  }) : super(key: key);

  @override
  State<SlideScaleAnimation> createState() => _SlideScaleAnimationState();
}

class _SlideScaleAnimationState extends State<SlideScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: _getBeginOffset(),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: widget.initialScale,
      end: widget.finalScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
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

  Offset _getBeginOffset() {
    switch (widget.slideDirection) {
      case SlideDirection.leftToRight:
        return const Offset(-0.5, 0.0);
      case SlideDirection.rightToLeft:
        return const Offset(0.5, 0.0);
      case SlideDirection.topToBottom:
        return const Offset(0.0, -0.5);
      case SlideDirection.bottomToTop:
        return const Offset(0.0, 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}