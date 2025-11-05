import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/typography.dart';

/// Modern, tutarlı input field bileşeni
/// Focus durumları, validation ve accessibility desteği ile
class AppInput extends StatefulWidget {
  /// Input controller
  final TextEditingController? controller;
  
  /// Label metni
  final String? label;
  
  /// Placeholder metni
  final String? hint;
  
  /// Hata mesajı
  final String? errorText;
  
  /// Yardım metni
  final String? helperText;
  
  /// Şifre alanı mı
  final bool obscureText;
  
  /// Prefix ikonu
  final IconData? prefixIcon;
  
  /// Suffix ikonu
  final IconData? suffixIcon;
  
  /// Suffix widget (özel)
  final Widget? suffixWidget;
  
  /// Keyboard tipi
  final TextInputType? keyboardType;
  
  /// Input action
  final TextInputAction? textInputAction;
  
  /// Maksimum satır sayısı
  final int? maxLines;
  
  /// Minimum satır sayısı
  final int? minLines;
  
  /// Maksimum karakter sayısı
  final int? maxLength;
  
  /// Sadece okunabilir
  final bool readOnly;
  
  /// Etkin durumda mı
  final bool enabled;
  
  /// Otomatik odaklan
  final bool autofocus;
  
  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;
  
  /// Değişiklik callback'i
  final ValueChanged<String>? onChanged;
  
  /// Submit callback'i
  final ValueChanged<String>? onSubmitted;
  
  /// Focus callback'i
  final VoidCallback? onTap;
  
  /// Focus node
  final FocusNode? focusNode;
  
  /// Validation fonksiyonu
  final String? Function(String?)? validator;
  
  /// Input tipi
  final AppInputType type;
  
  /// Boyut
  final AppInputSize size;
  
  /// Accessibility label
  final String? semanticLabel;
  
  /// Özel border radius
  final double? borderRadius;
  
  /// Özel padding
  final EdgeInsetsGeometry? contentPadding;

  const AppInput({
    Key? key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixWidget,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.validator,
    this.type = AppInputType.standard,
    this.size = AppInputSize.medium,
    this.semanticLabel,
    this.borderRadius,
    this.contentPadding,
  }) : super(key: key);

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _labelAnimation;
  late Animation<Color?> _borderColorAnimation;
  
  bool _isFocused = false;
  bool _obscureText = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _obscureText = widget.obscureText;
    _errorText = widget.errorText;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: AppDimensions.animationFast),
      vsync: this,
    );
    
    _labelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Theme.of() çağrıları burada yapılmalı
    _borderColorAnimation = ColorTween(
      begin: _getBorderColor(false, false),
      end: _getBorderColor(true, false),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != oldWidget.errorText) {
      setState(() {
        _errorText = widget.errorText;
      });
    }
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _onChanged(String value) {
    // Validation
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != _errorText) {
        setState(() {
          _errorText = error;
        });
      }
    }
    
    widget.onChanged?.call(value);
  }

  double _getInputHeight() {
    switch (widget.size) {
      case AppInputSize.small:
        return 40.0;
      case AppInputSize.medium:
        return AppDimensions.inputHeight;
      case AppInputSize.large:
        return 56.0;
    }
  }

  EdgeInsetsGeometry _getContentPadding() {
    if (widget.contentPadding != null) return widget.contentPadding!;
    
    switch (widget.size) {
      case AppInputSize.small:
        return const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 8.0,
        );
      case AppInputSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.inputPaddingHorizontal,
          vertical: AppDimensions.inputPaddingVertical,
        );
      case AppInputSize.large:
        return const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 16.0,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case AppInputSize.small:
        return AppTypography.bodySmall;
      case AppInputSize.medium:
        return AppTypography.inputText;
      case AppInputSize.large:
        return AppTypography.bodyLarge;
    }
  }

  Color _getBorderColor(bool focused, bool hasError) {
    if (hasError) return AppColors.error;
    if (focused) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return isDark ? AppColors.primaryLight : AppColors.primary;
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.borderDark : AppColors.borderLight;
  }

  Color _getFillColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    switch (widget.type) {
      case AppInputType.standard:
        return isDark ? AppColors.darkSurface : AppColors.surface;
      case AppInputType.filled:
        return isDark 
          ? AppColors.primary.withOpacity(0.1)
          : AppColors.prayerTime;
      case AppInputType.outlined:
        return Colors.transparent;
    }
  }

  Widget? _buildPrefixIcon() {
    if (widget.prefixIcon == null) return null;
    
    return Icon(
      widget.prefixIcon,
      color: _isFocused 
        ? (_errorText != null ? AppColors.error : AppColors.primary)
        : AppColors.textSecondary,
      size: widget.size == AppInputSize.small ? 18 : 20,
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixWidget != null) return widget.suffixWidget;
    
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
          color: AppColors.textSecondary,
          size: widget.size == AppInputSize.small ? 18 : 20,
        ),
        onPressed: _toggleObscureText,
        splashRadius: 20,
      );
    }
    
    if (widget.suffixIcon != null) {
      return Icon(
        widget.suffixIcon,
        color: _isFocused 
          ? (_errorText != null ? AppColors.error : AppColors.primary)
          : AppColors.textSecondary,
        size: widget.size == AppInputSize.small ? 18 : 20,
      );
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? AppDimensions.radiusMd(context);
    final hasError = _errorText != null;
    final borderColor = _getBorderColor(_isFocused, hasError);
    final fillColor = _getFillColor();
    
    Widget inputField = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          inputFormatters: widget.inputFormatters,
          onChanged: _onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          style: _getTextStyle().copyWith(
            color: widget.enabled 
              ? (Theme.of(context).brightness == Brightness.dark 
                ? AppColors.darkOnSurface 
                : AppColors.textPrimary)
              : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            errorText: hasError ? _errorText : null,
            helperText: widget.helperText,
            prefixIcon: _buildPrefixIcon(),
            suffixIcon: _buildSuffixIcon(),
            filled: widget.type != AppInputType.outlined,
            fillColor: fillColor,
            contentPadding: _getContentPadding(),
            
            // Border styles
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: widget.type == AppInputType.outlined 
                ? BorderSide(color: borderColor)
                : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: widget.type == AppInputType.outlined 
                ? BorderSide(color: borderColor)
                : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: AppColors.textHint.withOpacity(0.3),
              ),
            ),
            
            // Text styles
            labelStyle: AppTypography.inputLabel.copyWith(
              color: _isFocused 
                ? (hasError ? AppColors.error : AppColors.primary)
                : AppColors.textSecondary,
            ),
            hintStyle: AppTypography.inputText.copyWith(
              color: AppColors.textHint,
            ),
            errorStyle: AppTypography.errorText.copyWith(
              color: AppColors.error,
            ),
            helperStyle: AppTypography.errorText.copyWith(
              color: AppColors.textSecondary,
            ),
            
            // Counter style
            counterStyle: AppTypography.errorText.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        );
      },
    );

    // Semantic wrapper
    if (widget.semanticLabel != null) {
      inputField = Semantics(
        label: widget.semanticLabel,
        textField: true,
        enabled: widget.enabled,
        child: inputField,
      );
    }

    return inputField;
  }
}

/// Input tipleri
enum AppInputType {
  /// Standart input - filled background
  standard,
  
  /// Doldurulmuş input - renkli background
  filled,
  
  /// Çerçeveli input - sadece border
  outlined,
}

/// Input boyutları
enum AppInputSize {
  /// Küçük input
  small,
  
  /// Orta input (varsayılan)
  medium,
  
  /// Büyük input
  large,
}

/// Özel input varyasyonları
extension AppInputVariants on AppInput {
  /// Arama input'u
  static AppInput search({
    TextEditingController? controller,
    String? hint,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? semanticLabel,
  }) {
    return AppInput(
      controller: controller,
      hint: hint ?? 'Ara...',
      prefixIcon: Icons.search,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      semanticLabel: semanticLabel ?? 'Arama alanı',
      type: AppInputType.filled,
    );
  }

  /// Email input'u
  static AppInput email({
    TextEditingController? controller,
    String? label,
    String? errorText,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    String? semanticLabel,
  }) {
    return AppInput(
      controller: controller,
      label: label ?? 'E-posta',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.email_outlined,
      errorText: errorText,
      onChanged: onChanged,
      validator: validator ?? _defaultEmailValidator,
      semanticLabel: semanticLabel ?? 'E-posta adresi',
    );
  }

  /// Şifre input'u
  static AppInput password({
    TextEditingController? controller,
    String? label,
    String? errorText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? Function(String?)? validator,
    String? semanticLabel,
  }) {
    return AppInput(
      controller: controller,
      label: label ?? 'Şifre',
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      prefixIcon: Icons.lock_outlined,
      errorText: errorText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      validator: validator ?? _defaultPasswordValidator,
      semanticLabel: semanticLabel ?? 'Şifre',
    );
  }

  /// Çok satırlı metin input'u
  static AppInput multiline({
    TextEditingController? controller,
    String? label,
    String? hint,
    int maxLines = 4,
    int? maxLength,
    ValueChanged<String>? onChanged,
    String? semanticLabel,
  }) {
    return AppInput(
      controller: controller,
      label: label,
      hint: hint,
      maxLines: maxLines,
      minLines: 2,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      onChanged: onChanged,
      semanticLabel: semanticLabel ?? 'Çok satırlı metin alanı',
      type: AppInputType.outlined,
    );
  }

  /// Telefon input'u
  static AppInput phone({
    TextEditingController? controller,
    String? label,
    String? errorText,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    String? semanticLabel,
  }) {
    return AppInput(
      controller: controller,
      label: label ?? 'Telefon',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.phone_outlined,
      errorText: errorText,
      onChanged: onChanged,
      validator: validator,
      semanticLabel: semanticLabel ?? 'Telefon numarası',
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
    );
  }
}

// Varsayılan validator fonksiyonları
String? _defaultEmailValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'E-posta adresi gerekli';
  }
  
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) {
    return 'Geçerli bir e-posta adresi girin';
  }
  
  return null;
}

String? _defaultPasswordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Şifre gerekli';
  }
  
  if (value.length < 6) {
    return 'Şifre en az 6 karakter olmalı';
  }
  
  return null;
}