import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/typography.dart';

/// Modern, tutarlı buton bileşeni
/// Farklı tipler, boyutlar ve animasyonlar ile
class AppButton extends StatefulWidget {
  /// Buton metni
  final String text;
  
  /// Tıklama olayı
  final VoidCallback? onPressed;
  
  /// Buton tipi
  final AppButtonType type;
  
  /// Buton boyutu
  final AppButtonSize size;
  
  /// İkon (opsiyonel)
  final IconData? icon;
  
  /// İkon pozisyonu
  final AppButtonIconPosition iconPosition;
  
  /// Loading durumu
  final bool loading;
  
  /// Tam genişlik kullan
  final bool fullWidth;
  
  /// Özel renk
  final Color? color;
  
  /// Özel metin rengi
  final Color? textColor;
  
  /// Haptic feedback
  final bool enableHapticFeedback;
  
  /// Accessibility label
  final String? semanticLabel;
  
  /// Özel padding
  final EdgeInsetsGeometry? padding;
  
  /// Özel border radius
  final double? borderRadius;

  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.iconPosition = AppButtonIconPosition.left,
    this.loading = false,
    this.fullWidth = false,
    this.color,
    this.textColor,
    this.enableHapticFeedback = true,
    this.semanticLabel,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: AppDimensions.animationFast),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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

  double _getButtonHeight(BuildContext context) {
    switch (widget.size) {
      case AppButtonSize.small:
        return AppDimensions.buttonHeightSm(context);
      case AppButtonSize.medium:
        return AppDimensions.buttonHeightMd(context);
      case AppButtonSize.large:
        return AppDimensions.buttonHeightLg(context);
      case AppButtonSize.extraLarge:
        return AppDimensions.buttonHeightXl(context);
    }
  }

  EdgeInsetsGeometry _getButtonPadding(BuildContext context) {
    if (widget.padding != null) return widget.padding!;
    
    switch (widget.size) {
      case AppButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppDimensions.buttonPaddingHorizontalSm(context),
          vertical: AppDimensions.paddingXs(context),
        );
      case AppButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppDimensions.buttonPaddingHorizontalMd(context),
          vertical: AppDimensions.paddingSm(context),
        );
      case AppButtonSize.large:
        return EdgeInsets.symmetric(
          horizontal: AppDimensions.buttonPaddingHorizontalLg(context),
          vertical: AppDimensions.paddingMd(context),
        );
      case AppButtonSize.extraLarge:
        return EdgeInsets.symmetric(
          horizontal: AppDimensions.buttonPaddingHorizontalLg(context),
          vertical: AppDimensions.paddingLg(context),
        );
    }
  }

  double _getIconSize(BuildContext context) {
    switch (widget.size) {
      case AppButtonSize.small:
        return AppDimensions.iconXs(context);
      case AppButtonSize.medium:
        return AppDimensions.iconSm(context);
      case AppButtonSize.large:
        return AppDimensions.iconMd(context);
      case AppButtonSize.extraLarge:
        return AppDimensions.iconLg(context);
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    final baseStyle = AppTypography.buttonText;
    
    switch (widget.size) {
      case AppButtonSize.small:
        return baseStyle.copyWith(fontSize: 12);
      case AppButtonSize.medium:
        return baseStyle;
      case AppButtonSize.large:
        return baseStyle.copyWith(fontSize: 16);
      case AppButtonSize.extraLarge:
        return baseStyle.copyWith(fontSize: 18);
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    if (widget.color != null) return widget.color!;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (widget.type) {
      case AppButtonType.primary:
        return isDark ? AppColors.primaryLight : AppColors.primary;
      case AppButtonType.secondary:
        return AppColors.secondary;
      case AppButtonType.outline:
        return Colors.transparent;
      case AppButtonType.text:
        return Colors.transparent;
      case AppButtonType.success:
        return AppColors.success;
      case AppButtonType.warning:
        return AppColors.warning;
      case AppButtonType.error:
        return AppColors.error;
    }
  }

  Color _getTextColor(BuildContext context) {
    if (widget.textColor != null) return widget.textColor!;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (widget.type) {
      case AppButtonType.primary:
        return isDark ? Colors.black : Colors.white;
      case AppButtonType.secondary:
        return Colors.black;
      case AppButtonType.outline:
        return isDark ? AppColors.primaryLight : AppColors.primary;
      case AppButtonType.text:
        return isDark ? AppColors.primaryLight : AppColors.primary;
      case AppButtonType.success:
        return Colors.white;
      case AppButtonType.warning:
        return Colors.white;
      case AppButtonType.error:
        return Colors.white;
    }
  }

  BorderSide? _getBorderSide(BuildContext context) {
    if (widget.type == AppButtonType.outline) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return BorderSide(
        color: widget.color ?? (isDark ? AppColors.primaryLight : AppColors.primary),
        width: 1.5,
      );
    }
    return null;
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.loading) {
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
    widget.onPressed?.call();
  }

  Widget _buildButtonContent() {
    final iconSize = _getIconSize(context);
    final spacing = widget.size == AppButtonSize.small ? 4.0 : 8.0;
    
    if (widget.loading) {
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getTextColor(context),
          ),
        ),
      );
    }

    if (widget.icon == null) {
      return Text(
        widget.text,
        style: _getTextStyle(context).copyWith(
          color: _getTextColor(context),
        ),
        textAlign: TextAlign.center,
      );
    }

    final icon = Icon(
      widget.icon,
      size: iconSize,
      color: _getTextColor(context),
    );

    final text = Text(
      widget.text,
      style: _getTextStyle(context).copyWith(
        color: _getTextColor(context),
      ),
    );

    switch (widget.iconPosition) {
      case AppButtonIconPosition.left:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            SizedBox(width: spacing),
            text,
          ],
        );
      case AppButtonIconPosition.right:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            text,
            SizedBox(width: spacing),
            icon,
          ],
        );
      case AppButtonIconPosition.top:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            SizedBox(height: spacing / 2),
            text,
          ],
        );
      case AppButtonIconPosition.bottom:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            text,
            SizedBox(height: spacing / 2),
            icon,
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? AppDimensions.radiusMd(context);
    final backgroundColor = _getBackgroundColor(context);
    final borderSide = _getBorderSide(context);
    final buttonHeight = _getButtonHeight(context);
    final buttonPadding = _getButtonPadding(context);

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? _scaleAnimation.value : 1.0,
          child: Container(
            height: buttonHeight,
            width: widget.fullWidth ? double.infinity : null,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: borderSide != null ? Border.fromBorderSide(borderSide) : null,
              boxShadow: widget.type != AppButtonType.text && widget.type != AppButtonType.outline
                ? [
                    BoxShadow(
                      color: backgroundColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              child: InkWell(
                onTap: widget.onPressed != null && !widget.loading ? _handleTap : null,
                onTapDown: widget.onPressed != null && !widget.loading ? _handleTapDown : null,
                onTapUp: widget.onPressed != null && !widget.loading ? _handleTapUp : null,
                onTapCancel: widget.onPressed != null && !widget.loading ? _handleTapCancel : null,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  padding: buttonPadding,
                  child: Center(
                    child: _buildButtonContent(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Semantic wrapper
    if (widget.semanticLabel != null) {
      button = Semantics(
        label: widget.semanticLabel,
        button: true,
        enabled: widget.onPressed != null && !widget.loading,
        child: button,
      );
    }

    return button;
  }
}

/// Buton tipleri
enum AppButtonType {
  /// Ana buton - primary renk
  primary,
  
  /// İkincil buton - secondary renk
  secondary,
  
  /// Çerçeveli buton - sadece kenarlık
  outline,
  
  /// Metin buton - sadece metin
  text,
  
  /// Başarı buton - yeşil
  success,
  
  /// Uyarı buton - turuncu
  warning,
  
  /// Hata buton - kırmızı
  error,
}

/// Buton boyutları
enum AppButtonSize {
  /// Küçük buton
  small,
  
  /// Orta buton (varsayılan)
  medium,
  
  /// Büyük buton
  large,
  
  /// Çok büyük buton
  extraLarge,
}

/// İkon pozisyonları
enum AppButtonIconPosition {
  /// İkon solda
  left,
  
  /// İkon sağda
  right,
  
  /// İkon üstte
  top,
  
  /// İkon altta
  bottom,
}

/// Özel buton varyasyonları
extension AppButtonVariants on AppButton {
  /// Hızlı erişim butonu
  static AppButton quickAccess({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    String? semanticLabel,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      type: AppButtonType.primary,
      size: AppButtonSize.medium,
      icon: icon,
      iconPosition: AppButtonIconPosition.top,
      semanticLabel: semanticLabel,
      borderRadius: 12.0,
    );
  }

  /// Premium buton
  static AppButton premium({
    required String text,
    required VoidCallback onPressed,
    String? semanticLabel,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      type: AppButtonType.secondary,
      size: AppButtonSize.large,
      icon: Icons.workspace_premium,
      semanticLabel: semanticLabel,
      fullWidth: true,
    );
  }

  /// Namaz vakti ayar butonu
  static AppButton prayerSetting({
    required String text,
    required VoidCallback onPressed,
    String? semanticLabel,
  }) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      type: AppButtonType.outline,
      size: AppButtonSize.small,
      icon: Icons.settings,
      semanticLabel: semanticLabel,
    );
  }

  /// AI soru gönder butonu
  static AppButton sendMessage({
    required VoidCallback onPressed,
    bool loading = false,
    String? semanticLabel,
  }) {
    return AppButton(
      text: '',
      onPressed: onPressed,
      type: AppButtonType.primary,
      size: AppButtonSize.medium,
      icon: Icons.send,
      loading: loading,
      semanticLabel: semanticLabel ?? 'Mesaj gönder',
      padding: const EdgeInsets.all(12.0),
      borderRadius: 24.0,
    );
  }
}