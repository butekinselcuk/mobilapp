import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';

/// Skeleton loading animasyonu
/// İçerik yüklenirken gösterilen shimmer efektli placeholder
class SkeletonLoader extends StatefulWidget {
  /// Skeleton genişliği
  final double? width;
  
  /// Skeleton yüksekliği
  final double? height;
  
  /// Border radius
  final double borderRadius;
  
  /// Animasyon süresi
  final Duration duration;
  
  /// Base renk
  final Color? baseColor;
  
  /// Highlight renk
  final Color? highlightColor;
  
  /// Animasyon etkin mi
  final bool enabled;

  const SkeletonLoader({
    Key? key,
    this.width,
    this.height,
    this.borderRadius = AppDimensions.radiusSmStatic,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SkeletonLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.baseColor ?? 
      (isDark ? AppColors.darkSurface : Colors.grey[300]!);
    final highlightColor = widget.highlightColor ?? 
      (isDark ? AppColors.borderDark : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: widget.enabled
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    baseColor,
                    highlightColor,
                    baseColor,
                  ],
                  stops: [
                    _animation.value - 0.3,
                    _animation.value,
                    _animation.value + 0.3,
                  ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                )
              : null,
            color: widget.enabled ? null : baseColor,
          ),
        );
      },
    );
  }
}

/// Önceden tanımlanmış skeleton şekilleri
class SkeletonShapes {
  /// Metin satırı skeleton'ı
  static Widget textLine({
    double? width,
    double height = 16,
    double borderRadius = 4,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  /// Başlık skeleton'ı
  static Widget title({
    double? width,
    double height = 24,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: AppDimensions.radiusSmStatic,
    );
  }

  /// Avatar skeleton'ı
  static Widget avatar({
    double size = AppDimensions.avatarMd,
  }) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }

  /// Kart skeleton'ı
  static Widget card({
    double? width,
    double height = 120,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: AppDimensions.radiusMdStatic,
    );
  }

  /// Buton skeleton'ı
  static Widget button({
    double? width,
    double height = AppDimensions.buttonHeightMdStatic,
  }) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: AppDimensions.radiusMdStatic,
    );
  }

  /// İkon skeleton'ı
  static Widget icon({
    double size = AppDimensions.iconMdStatic,
  }) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: AppDimensions.radiusXsStatic,
    );
  }
}

/// Karmaşık skeleton layout'ları
class SkeletonLayouts {
  /// Liste öğesi skeleton'ı
  static Widget listItem({
    bool showAvatar = true,
    bool showSubtitle = true,
    bool showTrailing = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMdStatic),
      child: Row(
        children: [
          if (showAvatar) ...[
            SkeletonShapes.avatar(),
            const SizedBox(width: AppDimensions.paddingMdStatic),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonShapes.title(width: 200),
                if (showSubtitle) ...[
                  const SizedBox(height: AppDimensions.paddingXsStatic),
                  SkeletonShapes.textLine(width: 150),
                ],
              ],
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: AppDimensions.paddingMdStatic),
            SkeletonShapes.icon(),
          ],
        ],
      ),
    );
  }

  /// Kart skeleton'ı
  static Widget card({
    bool showImage = true,
    bool showSubtitle = true,
    bool showActions = false,
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.marginSmStatic),
      padding: const EdgeInsets.all(AppDimensions.paddingMdStatic),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMdStatic),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImage) ...[
            SkeletonShapes.card(height: 120),
            const SizedBox(height: AppDimensions.paddingMdStatic),
          ],
          SkeletonShapes.title(width: 180),
          if (showSubtitle) ...[
            const SizedBox(height: AppDimensions.paddingXsStatic),
            SkeletonShapes.textLine(width: 120),
            const SizedBox(height: AppDimensions.paddingXsStatic),
            SkeletonShapes.textLine(width: 200),
          ],
          if (showActions) ...[
            const SizedBox(height: AppDimensions.paddingMdStatic),
            Row(
              children: [
                SkeletonShapes.button(width: 80),
                const SizedBox(width: AppDimensions.paddingSmStatic),
                SkeletonShapes.button(width: 100),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Namaz vakti kartı skeleton'ı
  static Widget prayerTimeCard() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.marginSmStatic),
      padding: const EdgeInsets.all(AppDimensions.prayerTimeCardPaddingStatic),
      decoration: BoxDecoration(
        color: AppColors.prayerTime,
        borderRadius: BorderRadius.circular(AppDimensions.prayerTimeCardRadiusStatic),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonShapes.title(width: 100),
                  const SizedBox(height: AppDimensions.paddingXsStatic),
                  SkeletonShapes.textLine(width: 150),
                ],
              ),
              SkeletonShapes.icon(),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingLgStatic),
          SkeletonShapes.title(width: 120, height: 32),
          const SizedBox(height: AppDimensions.paddingLgStatic),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) => 
              Column(
                children: [
                  SkeletonShapes.textLine(width: 40, height: 12),
                  const SizedBox(height: AppDimensions.paddingXsStatic),
                  SkeletonShapes.textLine(width: 35, height: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// AI asistanı kartı skeleton'ı
  static Widget aiAssistantCard() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.marginSmStatic),
      padding: const EdgeInsets.all(AppDimensions.aiCardPaddingStatic),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppDimensions.aiCardRadiusStatic),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonShapes.title(width: 150),
          const SizedBox(height: AppDimensions.paddingSmStatic),
          Row(
            children: [
              Expanded(
                child: SkeletonShapes.button(height: AppDimensions.aiInputHeightStatic),
              ),
              const SizedBox(width: AppDimensions.paddingSmStatic),
              SkeletonShapes.button(width: 40, height: AppDimensions.aiInputHeightStatic),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMdStatic),
          SkeletonShapes.textLine(width: 200),
          const SizedBox(height: AppDimensions.paddingXsStatic),
          SkeletonShapes.textLine(width: 180),
        ],
      ),
    );
  }
}