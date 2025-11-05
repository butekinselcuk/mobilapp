import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/typography.dart';
import '../animations/fade_in_animation.dart';
import '../animations/slide_animation.dart';

/// Hızlı erişim butonu modeli
class QuickAccessItem {
  final String emoji;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final String? semanticLabel;

  const QuickAccessItem({
    required this.emoji,
    required this.label,
    required this.onTap,
    this.color,
    this.semanticLabel,
  });
}

/// Modern hızlı erişim grid'i
class QuickAccessGrid extends StatelessWidget {
  /// Hızlı erişim öğeleri
  final List<QuickAccessItem> items;
  
  /// Grid sütun sayısı
  final int crossAxisCount;
  
  /// Öğeler arası boşluk
  final double spacing;
  
  /// Animasyon gecikmesi
  final Duration animationDelay;

  const QuickAccessGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 3,
    this.spacing = 16.0,
    this.animationDelay = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    final responsiveSpacing = AppDimensions.paddingMd(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.marginMd(context)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: responsiveSpacing,
          mainAxisSpacing: responsiveSpacing,
          childAspectRatio: 0.9,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return SlideAnimation(
            delay: Duration(
              milliseconds: animationDelay.inMilliseconds * index,
            ),
            direction: SlideDirection.bottomToTop,
            distance: 0.3,
            child: FadeInAnimation(
              delay: Duration(
                milliseconds: animationDelay.inMilliseconds * index + 50,
              ),
              child: QuickAccessButton(item: item),
            ),
          );
        },
      ),
    );
  }
}

/// Hızlı erişim butonu widget'ı
class QuickAccessButton extends StatefulWidget {
  final QuickAccessItem item;

  const QuickAccessButton({
    super.key,
    required this.item,
  });

  @override
  State<QuickAccessButton> createState() => _QuickAccessButtonState();
}

class _QuickAccessButtonState extends State<QuickAccessButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 6.0,
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

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
    widget.item.onTap();
  }

  void _handleTap() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
    widget.item.onTap();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = widget.item.color ?? 
      (isDark ? AppColors.cardDark : AppColors.surface);
    
    return Semantics(
      label: widget.item.semanticLabel ?? widget.item.label,
      button: true,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? _scaleAnimation.value : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(AppDimensions.quickButtonRadius(context)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: _isPressed ? _elevationAnimation.value : 2.0,
                      offset: Offset(0, _isPressed ? _elevationAnimation.value / 2 : 1.0),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.quickButtonRadius(context)),
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.paddingSm(context)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Emoji container
                        Container(
                          width: AppDimensions.iconXl(context),
                          height: AppDimensions.iconXl(context),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg(context)),
                          ),
                          child: Center(
                            child: Text(
                              widget.item.emoji,
                              style: TextStyle(fontSize: AppDimensions.iconMd(context)),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: AppDimensions.paddingXs(context)),
                        
                        // Label
                        Text(
                          widget.item.label,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Önceden tanımlanmış hızlı erişim öğeleri
class QuickAccessItems {
  /// Kur'an okuma
  static QuickAccessItem quran(VoidCallback onTap) {
    return QuickAccessItem(
      emoji: '📖',
      label: 'Kur\'an Oku',
      onTap: onTap,
      semanticLabel: 'Kur\'an okuma sayfasına git',
    );
  }

  /// Hadis
  static QuickAccessItem hadith(VoidCallback onTap) {
    return QuickAccessItem(
      emoji: '📜',
      label: 'Hadis',
      onTap: onTap,
      semanticLabel: 'Hadis koleksiyonuna git',
    );
  }

  /// Dua
  static QuickAccessItem prayer(VoidCallback onTap) {
    return QuickAccessItem(
      emoji: '🤲',
      label: 'Dua',
      onTap: onTap,
      semanticLabel: 'Dua koleksiyonuna git',
    );
  }

  /// Zikir
  static QuickAccessItem dhikr(VoidCallback onTap) {
    return QuickAccessItem(
      emoji: '📿',
      label: 'Zikir',
      onTap: onTap,
      semanticLabel: 'Zikir koleksiyonuna git',
    );
  }

  /// Tefsir
  static QuickAccessItem tafsir(VoidCallback onTap) {
    return QuickAccessItem(
      emoji: '📚',
      label: 'Tefsir',
      onTap: onTap,
      semanticLabel: 'Tefsir koleksiyonuna git',
    );
  }

  /// Kıble
  static QuickAccessItem qibla(VoidCallback onTap) {
    return QuickAccessItem(
      emoji: '🧭',
      label: 'Kıble',
      onTap: onTap,
      semanticLabel: 'Kıble pusulasını aç',
    );
  }

  /// İlim Yolculukları
  static QuickAccessItem journey(VoidCallback onTap) {
    return QuickAccessItem(
      emoji: '🎓',
      label: 'İlim Yolculukları',
      onTap: onTap,
      semanticLabel: 'İlim yolculuklarına git',
    );
  }

  /// Namaz Vakitleri
  static QuickAccessItem prayerTimes(VoidCallback onTap) {
    return QuickAccessItem(
      emoji: '🕐',
      label: 'Namaz Vakitleri',
      onTap: onTap,
      semanticLabel: 'Namaz vakitleri ayarları',
    );
  }
}

/// Hızlı erişim grid'i için skeleton loader
class QuickAccessGridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double spacing;

  const QuickAccessGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 3,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.marginMd(context)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 0.9,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppDimensions.quickButtonRadius(context)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.paddingSm(context)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji skeleton
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg(context)),
                    ),
                  ),
                  
                  SizedBox(height: AppDimensions.paddingXs(context)),
                  
                  // Label skeleton
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}