import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/typography.dart';
import '../animations/fade_in_animation.dart';
import '../animations/slide_animation.dart';

/// Modal boyut tipleri
enum ModalSize {
  /// Küçük modal (ekranın %40'ı)
  small,
  /// Orta modal (ekranın %60'ı)
  medium,
  /// Büyük modal (ekranın %80'ı)
  large,
  /// Tam ekran modal
  fullscreen,
  /// Özel boyut
  custom,
}

/// Modal pozisyon tipleri
enum ModalPosition {
  /// Merkez
  center,
  /// Alt
  bottom,
  /// Üst
  top,
}

/// Modern modal wrapper widget'ı
class AppModal extends StatefulWidget {
  /// Modal içeriği
  final Widget child;
  
  /// Modal başlığı
  final String? title;
  
  /// Başlık widget'ı (title'dan öncelikli)
  final Widget? titleWidget;
  
  /// Modal boyutu
  final ModalSize size;
  
  /// Modal pozisyonu
  final ModalPosition position;
  
  /// Özel genişlik (size = custom olduğunda)
  final double? customWidth;
  
  /// Özel yükseklik (size = custom olduğunda)
  final double? customHeight;
  
  /// Backdrop blur efekti
  final bool enableBlur;
  
  /// Blur şiddeti
  final double blurSigma;
  
  /// Dışarı tıklayınca kapanma
  final bool dismissible;
  
  /// Keyboard ile kapanma (ESC tuşu)
  final bool keyboardDismissible;
  
  /// Kapatma butonu gösterme
  final bool showCloseButton;
  
  /// Kapatma callback'i
  final VoidCallback? onClose;
  
  /// Arka plan rengi
  final Color? backgroundColor;
  
  /// Border radius
  final double? borderRadius;
  
  /// Padding
  final EdgeInsets? padding;
  
  /// Margin
  final EdgeInsets? margin;
  
  /// Elevation
  final double elevation;
  
  /// Animasyon süresi
  final Duration animationDuration;
  
  /// Haptic feedback
  final bool enableHapticFeedback;

  const AppModal({
    Key? key,
    required this.child,
    this.title,
    this.titleWidget,
    this.size = ModalSize.medium,
    this.position = ModalPosition.center,
    this.customWidth,
    this.customHeight,
    this.enableBlur = true,
    this.blurSigma = 8.0,
    this.dismissible = true,
    this.keyboardDismissible = true,
    this.showCloseButton = true,
    this.onClose,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.elevation = AppDimensions.elevationMd,
    this.animationDuration = const Duration(milliseconds: AppDimensions.animationNormal),
    this.enableHapticFeedback = true,
  }) : super(key: key);

  @override
  State<AppModal> createState() => _AppModalState();

  /// Modal gösterme helper metodu
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? titleWidget,
    ModalSize size = ModalSize.medium,
    ModalPosition position = ModalPosition.center,
    double? customWidth,
    double? customHeight,
    bool enableBlur = true,
    double blurSigma = 8.0,
    bool dismissible = true,
    bool keyboardDismissible = true,
    bool showCloseButton = true,
    VoidCallback? onClose,
    Color? backgroundColor,
    double? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double elevation = AppDimensions.elevationMd,
    Duration animationDuration = const Duration(milliseconds: AppDimensions.animationNormal),
    bool enableHapticFeedback = true,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.5),
      builder: (context) => AppModal(
        child: child,
        title: title,
        titleWidget: titleWidget,
        size: size,
        position: position,
        customWidth: customWidth,
        customHeight: customHeight,
        enableBlur: enableBlur,
        blurSigma: blurSigma,
        dismissible: dismissible,
        keyboardDismissible: keyboardDismissible,
        showCloseButton: showCloseButton,
        onClose: onClose,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        padding: padding,
        margin: margin,
        elevation: elevation,
        animationDuration: animationDuration,
        enableHapticFeedback: enableHapticFeedback,
      ),
    );
  }

  /// Bottom sheet tarzı modal gösterme
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? titleWidget,
    bool enableBlur = true,
    double blurSigma = 8.0,
    bool dismissible = true,
    bool showCloseButton = true,
    VoidCallback? onClose,
    Color? backgroundColor,
    double? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double elevation = AppDimensions.elevationMd,
    Duration animationDuration = const Duration(milliseconds: AppDimensions.animationNormal),
    bool enableHapticFeedback = true,
    bool barrierDismissible = true,
    Color? barrierColor,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.5),
      builder: (context) => AppModal(
        child: child,
        title: title,
        titleWidget: titleWidget,
        size: ModalSize.large,
        position: ModalPosition.bottom,
        enableBlur: enableBlur,
        blurSigma: blurSigma,
        dismissible: dismissible,
        keyboardDismissible: false, // Bottom sheet'te keyboard dismiss kapalı
        showCloseButton: showCloseButton,
        onClose: onClose,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        padding: padding,
        margin: margin,
        elevation: elevation,
        animationDuration: animationDuration,
        enableHapticFeedback: enableHapticFeedback,
      ),
    );
  }
}

class _AppModalState extends State<AppModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.position == ModalPosition.bottom
          ? const Offset(0, 1)
          : widget.position == ModalPosition.top
              ? const Offset(0, -1)
              : const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimation() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    
    if (widget.onClose != null) {
      widget.onClose!();
    }
    
    Navigator.of(context).pop();
  }

  void _handleBackdropTap() {
    if (widget.dismissible) {
      _handleClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (widget.keyboardDismissible &&
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _handleClose();
        }
      },
      child: GestureDetector(
        onTap: _handleBackdropTap,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Backdrop blur
              if (widget.enableBlur)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: widget.blurSigma,
                      sigmaY: widget.blurSigma,
                    ),
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ),
                ),

              // Modal content
              _buildModalContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalContent() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.position == ModalPosition.center
                ? _buildCenterModal()
                : widget.position == ModalPosition.bottom
                    ? _buildBottomModal()
                    : _buildTopModal(),
          ),
        );
      },
    );
  }

  Widget _buildCenterModal() {
    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildModalContainer(),
      ),
    );
  }

  Widget _buildBottomModal() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: _buildModalContainer(),
    );
  }

  Widget _buildTopModal() {
    return Align(
      alignment: Alignment.topCenter,
      child: _buildModalContainer(),
    );
  }

  Widget _buildModalContainer() {
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Boyut hesaplama
    double? width;
    double? height;
    
    switch (widget.size) {
      case ModalSize.small:
        width = screenSize.width * 0.4;
        height = screenSize.height * 0.3;
        break;
      case ModalSize.medium:
        width = screenSize.width * 0.6;
        height = screenSize.height * 0.5;
        break;
      case ModalSize.large:
        width = screenSize.width * 0.8;
        height = screenSize.height * 0.7;
        break;
      case ModalSize.fullscreen:
        width = screenSize.width;
        height = screenSize.height;
        break;
      case ModalSize.custom:
        width = widget.customWidth;
        height = widget.customHeight;
        break;
    }

    // Responsive constraints
    width = width?.clamp(280.0, screenSize.width * 0.95);
    height = height?.clamp(200.0, screenSize.height * 0.9);

    return Container(
      width: width,
      height: height,
      margin: widget.margin ?? 
        (widget.position == ModalPosition.center 
          ? EdgeInsets.all(AppDimensions.paddingLg(context))
          : widget.position == ModalPosition.bottom
            ? EdgeInsets.only(
                left: AppDimensions.paddingMd(context),
                right: AppDimensions.paddingMd(context),
                bottom: AppDimensions.paddingMd(context),
              )
            : EdgeInsets.only(
                left: AppDimensions.paddingMd(context),
                right: AppDimensions.paddingMd(context),
                top: AppDimensions.paddingMd(context),
              )),
      child: GestureDetector(
        onTap: () {}, // Modal içeriğine tıklamayı engelle
        child: Material(
          color: widget.backgroundColor ?? 
            (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? 
              (widget.position == ModalPosition.bottom
                ? 16.0
                : 12.0)
          ),
          elevation: widget.elevation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              widget.borderRadius ?? 
                (widget.position == ModalPosition.bottom
                  ? 16.0
                  : 12.0)
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                if (widget.title != null || widget.titleWidget != null || widget.showCloseButton)
                  _buildHeader(),
                
                // Content
                Expanded(
                  child: Container(
                    padding: widget.padding ?? EdgeInsets.all(AppDimensions.paddingLg(context)),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.paddingLg(context),
        AppDimensions.paddingMd(context),
        AppDimensions.paddingMd(context),
        AppDimensions.paddingMd(context),
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title
          Expanded(
            child: widget.titleWidget ?? 
              (widget.title != null
                ? Text(
                    widget.title!,
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : const SizedBox.shrink()),
          ),
          
          // Close button
          if (widget.showCloseButton)
            IconButton(
              onPressed: _handleClose,
              icon: const Icon(Icons.close),
              iconSize: 20,
              padding: EdgeInsets.all(AppDimensions.paddingSmStatic),
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

/// Önceden tanımlanmış modal tipleri
class AppModals {
  /// Bilgi modalı
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return AppModal.show(
      context: context,
      title: title,
      size: ModalSize.small,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: AppColors.info,
          ),
          SizedBox(height: AppDimensions.paddingMdStatic),
          Text(
            message,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.paddingLgStatic),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed ?? () => Navigator.of(context).pop(),
              child: Text(buttonText ?? 'Tamam'),
            ),
          ),
        ],
      ),
    );
  }

  /// Hata modalı
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return AppModal.show(
      context: context,
      title: title,
      size: ModalSize.small,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          SizedBox(height: AppDimensions.paddingMd(context)),
          Text(
            message,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.paddingLg(context)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed ?? () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonText ?? 'Tamam'),
            ),
          ),
        ],
      ),
    );
  }

  /// Onay modalı
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return AppModal.show<bool>(
      context: context,
      title: title,
      size: ModalSize.small,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.help_outline,
            size: 48,
            color: AppColors.warning,
          ),
          SizedBox(height: AppDimensions.paddingMd(context)),
          Text(
            message,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.paddingLg(context)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (onCancel != null) onCancel();
                    Navigator.of(context).pop(false);
                  },
                  child: Text(cancelText ?? 'İptal'),
                ),
              ),
              SizedBox(width: AppDimensions.paddingMdStatic),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (onConfirm != null) onConfirm();
                    Navigator.of(context).pop(true);
                  },
                  child: Text(confirmText ?? 'Onayla'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Loading modalı
  static Future<void> showLoading({
    required BuildContext context,
    String? message,
  }) {
    return AppModal.show(
      context: context,
      size: ModalSize.small,
      dismissible: false,
      showCloseButton: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            SizedBox(height: AppDimensions.paddingMd(context)),
            Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}