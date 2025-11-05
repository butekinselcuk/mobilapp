import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/typography.dart';
import '../animations/fade_in_animation.dart';

/// Loading state tipleri
enum LoadingType {
  /// Basit spinner
  spinner,
  /// Dots animasyonu
  dots,
  /// Pulse animasyonu
  pulse,
  /// İslami geometric pattern
  islamic,
  /// Skeleton loader
  skeleton,
  /// Shimmer efekti
  shimmer,
  /// Custom loading
  custom,
}

/// Loading boyut tipleri
enum LoadingSize {
  /// Küçük (24x24)
  small,
  /// Orta (48x48)
  medium,
  /// Büyük (72x72)
  large,
  /// Özel boyut
  custom,
}

/// Modern loading state widget'ı
class AppLoadingState extends StatefulWidget {
  /// Loading tipi
  final LoadingType type;
  
  /// Loading boyutu
  final LoadingSize size;
  
  /// Özel boyut (size = custom olduğunda)
  final double? customSize;
  
  /// Loading mesajı
  final String? message;
  
  /// Loading rengi
  final Color? color;
  
  /// Arka plan rengi
  final Color? backgroundColor;
  
  /// Animasyon süresi
  final Duration animationDuration;
  
  /// Overlay olarak göster
  final bool overlay;
  
  /// Overlay opacity
  final double overlayOpacity;
  
  /// Custom loading widget'ı
  final Widget? customWidget;

  const AppLoadingState({
    Key? key,
    this.type = LoadingType.spinner,
    this.size = LoadingSize.medium,
    this.customSize,
    this.message,
    this.color,
    this.backgroundColor,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.overlay = false,
    this.overlayOpacity = 0.8,
    this.customWidget,
  }) : super(key: key);

  @override
  State<AppLoadingState> createState() => _AppLoadingStateState();
}

class _AppLoadingStateState extends State<AppLoadingState>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _dotsController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _dotsAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _dotsAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _dotsController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _animationController.repeat();
    _pulseController.repeat(reverse: true);
    _dotsController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  double get _loadingSize {
    switch (widget.size) {
      case LoadingSize.small:
        return 24.0;
      case LoadingSize.medium:
        return 48.0;
      case LoadingSize.large:
        return 72.0;
      case LoadingSize.custom:
        return widget.customSize ?? 48.0;
    }
  }

  Color get _loadingColor {
    return widget.color ?? AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final loadingWidget = _buildLoadingWidget();

    if (widget.overlay) {
      return Container(
        color: (widget.backgroundColor ?? Colors.black)
            .withOpacity(widget.overlayOpacity),
        child: Center(child: loadingWidget),
      );
    }

    return loadingWidget;
  }

  Widget _buildLoadingWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLoadingIndicator(),
        if (widget.message != null) ...[
          SizedBox(height: AppDimensions.paddingMdStatic),
          FadeInAnimation(
            child: Text(
              widget.message!,
              style: AppTypography.bodyMedium.copyWith(
                color: _loadingColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    switch (widget.type) {
      case LoadingType.spinner:
        return _buildSpinner();
      case LoadingType.dots:
        return _buildDots();
      case LoadingType.pulse:
        return _buildPulse();
      case LoadingType.islamic:
        return _buildIslamicPattern();
      case LoadingType.skeleton:
        return _buildSkeleton();
      case LoadingType.shimmer:
        return _buildShimmer();
      case LoadingType.custom:
        return widget.customWidget ?? _buildSpinner();
    }
  }

  Widget _buildSpinner() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: _loadingSize,
            height: _loadingSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _loadingColor.withOpacity(0.2),
                width: 3,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: _loadingColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDots() {
    return AnimatedBuilder(
      animation: _dotsAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_dotsAnimation.value - delay).clamp(0.0, 1.0);
            final scale = math.sin(animationValue * math.pi);
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: 0.5 + (scale * 0.5),
                child: Container(
                  width: _loadingSize / 4,
                  height: _loadingSize / 4,
                  decoration: BoxDecoration(
                    color: _loadingColor.withOpacity(0.3 + (scale * 0.7)),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildPulse() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: _loadingSize,
            height: _loadingSize,
            decoration: BoxDecoration(
              color: _loadingColor.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildIslamicPattern() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: CustomPaint(
            size: Size(_loadingSize, _loadingSize),
            painter: IslamicPatternPainter(
              color: _loadingColor,
              progress: _rotationAnimation.value,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return Container(
      width: _loadingSize * 3,
      height: _loadingSize,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmStatic),
      ),
    );
  }

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: _loadingSize * 3,
          height: _loadingSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmStatic),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _animationController.value * 2, 0.0),
              end: Alignment(1.0 + _animationController.value * 2, 0.0),
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// İslami geometric pattern painter
class IslamicPatternPainter extends CustomPainter {
  final Color color;
  final double progress;

  IslamicPatternPainter({
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // 8 köşeli yıldız çiz
    final path = Path();
    const points = 8;
    const outerRadius = 1.0;
    const innerRadius = 0.6;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi / points) + (progress * 2 * math.pi / 8);
      final currentRadius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + math.cos(angle) * radius * currentRadius;
      final y = center.dy + math.sin(angle) * radius * currentRadius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);

    // İç daire
    canvas.drawCircle(
      center,
      radius * 0.3,
      paint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(IslamicPatternPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Önceden tanımlanmış loading widget'ları
class AppLoadings {
  /// Basit spinner
  static Widget spinner({
    LoadingSize size = LoadingSize.medium,
    Color? color,
    String? message,
  }) {
    return AppLoadingState(
      type: LoadingType.spinner,
      size: size,
      color: color,
      message: message,
    );
  }

  /// Dots animasyonu
  static Widget dots({
    LoadingSize size = LoadingSize.medium,
    Color? color,
    String? message,
  }) {
    return AppLoadingState(
      type: LoadingType.dots,
      size: size,
      color: color,
      message: message,
    );
  }

  /// Pulse animasyonu
  static Widget pulse({
    LoadingSize size = LoadingSize.medium,
    Color? color,
    String? message,
  }) {
    return AppLoadingState(
      type: LoadingType.pulse,
      size: size,
      color: color,
      message: message,
    );
  }

  /// İslami pattern
  static Widget islamic({
    LoadingSize size = LoadingSize.medium,
    Color? color,
    String? message,
  }) {
    return AppLoadingState(
      type: LoadingType.islamic,
      size: size,
      color: color,
      message: message,
    );
  }

  /// Skeleton loader
  static Widget skeleton({
    LoadingSize size = LoadingSize.medium,
    Color? color,
  }) {
    return AppLoadingState(
      type: LoadingType.skeleton,
      size: size,
      color: color,
    );
  }

  /// Shimmer efekti
  static Widget shimmer({
    LoadingSize size = LoadingSize.medium,
    Color? color,
  }) {
    return AppLoadingState(
      type: LoadingType.shimmer,
      size: size,
      color: color,
    );
  }

  /// Overlay loading
  static Widget overlay({
    LoadingType type = LoadingType.spinner,
    LoadingSize size = LoadingSize.medium,
    Color? color,
    String? message,
    double overlayOpacity = 0.8,
  }) {
    return AppLoadingState(
      type: type,
      size: size,
      color: color,
      message: message,
      overlay: true,
      overlayOpacity: overlayOpacity,
    );
  }

  /// Full screen loading
  static Widget fullScreen({
    LoadingType type = LoadingType.islamic,
    String? message,
    Color? backgroundColor,
  }) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.surface,
      body: Center(
        child: AppLoadingState(
          type: type,
          size: LoadingSize.large,
          message: message ?? 'Yükleniyor...',
        ),
      ),
    );
  }
}

/// Loading state için extension
extension LoadingStateExtension on Widget {
  /// Widget'ı loading state ile wrap et
  Widget withLoading({
    required bool isLoading,
    LoadingType type = LoadingType.spinner,
    LoadingSize size = LoadingSize.medium,
    Color? color,
    String? message,
    double overlayOpacity = 0.8,
  }) {
    return Stack(
      children: [
        this,
        if (isLoading)
          Positioned.fill(
            child: AppLoadingState(
              type: type,
              size: size,
              color: color,
              message: message,
              overlay: true,
              overlayOpacity: overlayOpacity,
            ),
          ),
      ],
    );
  }
}