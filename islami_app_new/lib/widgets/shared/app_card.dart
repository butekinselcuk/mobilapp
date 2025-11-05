import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../utils/accessibility.dart';

/// Modern, tutarlı kart bileşeni
/// Hover efektleri, accessibility ve responsive tasarım desteği ile
class AppCard extends StatefulWidget {
  /// Kartın içeriği
  final Widget child;
  
  /// İç boşluk (padding)
  final EdgeInsetsGeometry? padding;
  
  /// Dış boşluk (margin)
  final EdgeInsetsGeometry? margin;
  
  /// Köşe yuvarlaklığı
  final double? borderRadius;
  
  /// Gölge yüksekliği
  final double? elevation;
  
  /// Arka plan rengi
  final Color? color;
  
  /// Tıklama olayı
  final VoidCallback? onTap;
  
  /// Uzun basma olayı
  final VoidCallback? onLongPress;
  
  /// Hover efekti gösterilsin mi
  final bool showHoverEffect;
  
  /// Tıklama efekti gösterilsin mi
  final bool showRippleEffect;
  
  /// Haptic feedback verilsin mi
  final bool enableHapticFeedback;
  
  /// Accessibility label
  final String? semanticLabel;
  
  /// Kart tipi (farklı stillendirme için)
  final AppCardType type;
  
  /// Kenarlık
  final Border? border;
  
  /// Gradient arka plan
  final Gradient? gradient;
  
  /// Gölge rengi
  final Color? shadowColor;

  const AppCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevation,
    this.color,
    this.onTap,
    this.onLongPress,
    this.showHoverEffect = true,
    this.showRippleEffect = true,
    this.enableHapticFeedback = true,
    this.semanticLabel,
    this.type = AppCardType.standard,
    this.border,
    this.gradient,
    this.shadowColor,
  }) : super(key: key);

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: AppDimensions.animationFast),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? _getDefaultElevation(),
      end: (widget.elevation ?? _getDefaultElevation()) + 2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _getDefaultElevation() {
    switch (widget.type) {
      case AppCardType.standard:
        return AppDimensions.elevationSm;
      case AppCardType.elevated:
        return AppDimensions.elevationMd;
      case AppCardType.outlined:
        return AppDimensions.elevationNone;
      case AppCardType.filled:
        return AppDimensions.elevationXs;
    }
  }

  double _getDefaultBorderRadius() {
    switch (widget.type) {
      case AppCardType.standard:
        return 12.0;
      case AppCardType.elevated:
        return 16.0;
      case AppCardType.outlined:
        return 12.0;
      case AppCardType.filled:
        return 8.0;
    }
  }

  Color _getDefaultColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (widget.type) {
      case AppCardType.standard:
        return isDark ? AppColors.cardDark : AppColors.cardLight;
      case AppCardType.elevated:
        return isDark ? AppColors.cardDark : AppColors.cardLight;
      case AppCardType.outlined:
        return Colors.transparent;
      case AppCardType.filled:
        return isDark 
          ? AppColors.primary.withOpacity(0.1)
          : AppColors.prayerTime;
    }
  }

  Border? _getDefaultBorder(BuildContext context) {
    if (widget.type == AppCardType.outlined) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        width: 1,
      );
    }
    return null;
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null && widget.showHoverEffect) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _handleLongPress() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    widget.onLongPress?.call();
  }

  void _handleHoverEnter(PointerEnterEvent event) {
    if (widget.showHoverEffect && widget.onTap != null) {
      setState(() {
        _isHovered = true;
      });
    }
  }

  void _handleHoverExit(PointerExitEvent event) {
    if (_isHovered) {
      setState(() {
        _isHovered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? _getDefaultBorderRadius();
    final elevation = widget.elevation ?? _getDefaultElevation();
    final color = widget.color ?? _getDefaultColor(context);
    final border = widget.border ?? _getDefaultBorder(context);
    final padding = widget.padding ?? EdgeInsets.all(AppDimensions.paddingMd(context));
    final margin = widget.margin ?? EdgeInsets.zero;
    
    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: widget.gradient == null ? color : null,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
        boxShadow: elevation > 0 ? [
          BoxShadow(
            color: widget.shadowColor ?? 
              (Theme.of(context).brightness == Brightness.dark 
                ? AppColors.shadowDark 
                : AppColors.shadowLight),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation / 2),
          ),
        ] : null,
      ),
      child: Padding(
        padding: padding,
        child: widget.child,
      ),
    );

    // Animasyonlu wrapper
    if (widget.showHoverEffect && widget.onTap != null) {
      cardContent = AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed ? _scaleAnimation.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: widget.gradient == null ? color : null,
                gradient: widget.gradient,
                borderRadius: BorderRadius.circular(borderRadius),
                border: border,
                boxShadow: [
                  BoxShadow(
                    color: widget.shadowColor ?? 
                      (Theme.of(context).brightness == Brightness.dark 
                        ? AppColors.shadowDark 
                        : AppColors.shadowLight),
                    blurRadius: (_isHovered ? _elevationAnimation.value : elevation) * 2,
                    offset: Offset(0, (_isHovered ? _elevationAnimation.value : elevation) / 2),
                  ),
                ],
              ),
              child: Padding(
                padding: padding,
                child: widget.child,
              ),
            ),
          );
        },
      );
    }

    // Interactive wrapper
    if (widget.onTap != null || widget.onLongPress != null) {
      cardContent = MouseRegion(
        onEnter: _handleHoverEnter,
        onExit: _handleHoverExit,
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _handleTap,
          onLongPress: widget.onLongPress != null ? _handleLongPress : null,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: widget.showRippleEffect
            ? Material(
                color: Colors.transparent,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: cardContent,
                ),
              )
            : cardContent,
        ),
      );
    }

    // Semantic wrapper
    if (widget.semanticLabel != null) {
      cardContent = Semantics(
        label: widget.semanticLabel,
        button: widget.onTap != null,
        child: cardContent,
      );
    }

    return Container(
      margin: margin,
      child: cardContent,
    );
  }
}

/// Kart tipleri
enum AppCardType {
  /// Standart kart - varsayılan elevation ve renk
  standard,
  
  /// Yükseltilmiş kart - daha fazla elevation
  elevated,
  
  /// Çerçeveli kart - kenarlık var, elevation yok
  outlined,
  
  /// Doldurulmuş kart - renkli arka plan
  filled,
}

/// Özel kart varyasyonları için yardımcı sınıf
class AppCardVariants {
  /// Namaz vakti kartı için özelleştirilmiş kart
  static Widget prayerTime({
    required Widget child,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    return AppCard(
      type: AppCardType.filled,
      borderRadius: 12.0,
      padding: EdgeInsets.all(16.0),
      elevation: 4.0,
      gradient: const LinearGradient(
        colors: AppColors.prayerTimeGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }

  /// AI asistanı kartı için özelleştirilmiş kart
  static Widget aiAssistant({
    required Widget child,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    return AppCard(
      type: AppCardType.elevated,
      borderRadius: 16.0,
      padding: EdgeInsets.all(20.0),
      color: AppColors.darkSurface,
      elevation: 8.0,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }

  /// Hızlı erişim butonu kartı
  static Widget quickAccess({
    required Widget child,
    required VoidCallback onTap,
    String? semanticLabel,
  }) {
    return AppCard(
      type: AppCardType.standard,
      borderRadius: 8.0,
      padding: EdgeInsets.symmetric(vertical: 16.0),
      onTap: onTap,
      semanticLabel: semanticLabel,
      showHoverEffect: true,
      child: child,
    );
  }

  /// Liste öğesi kartı
  static Widget listItem({
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    String? semanticLabel,
  }) {
    return AppCard(
      type: AppCardType.standard,
      margin: EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 4.0,
      ),
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}