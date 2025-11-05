import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/typography.dart';
import '../animations/fade_in_animation.dart';

/// Bottom navigation item modeli
class BottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? semanticLabel;
  final int? badgeCount;
  final Color? badgeColor;

  const BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.semanticLabel,
    this.badgeCount,
    this.badgeColor,
  });
}

/// Modern custom bottom navigation
class CustomBottomNavigation extends StatefulWidget {
  /// Navigation item'ları
  final List<BottomNavItem> items;
  
  /// Aktif index
  final int currentIndex;
  
  /// Item tıklama callback'i
  final Function(int) onTap;
  
  /// Arka plan rengi
  final Color? backgroundColor;
  
  /// Seçili item rengi
  final Color? selectedItemColor;
  
  /// Seçili olmayan item rengi
  final Color? unselectedItemColor;
  
  /// Elevation
  final double elevation;
  
  /// Haptic feedback
  final bool enableHapticFeedback;
  
  /// Animasyon süresi
  final Duration animationDuration;

  const CustomBottomNavigation({
    Key? key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = AppDimensions.bottomNavElevation,
    this.enableHapticFeedback = true,
    this.animationDuration = const Duration(milliseconds: AppDimensions.animationNormal),
  }) : super(key: key);

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      ),
    );

    _scaleAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));
    }).toList();

    _fadeAnimations = _animationControllers.map((controller) {
      return Tween<double>(
        begin: 0.6,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    // Aktif item'ın animasyonunu başlat
    if (widget.currentIndex < _animationControllers.length) {
      _animationControllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(CustomBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Eski aktif item'ın animasyonunu durdur
      if (oldWidget.currentIndex < _animationControllers.length) {
        _animationControllers[oldWidget.currentIndex].reverse();
      }
      
      // Yeni aktif item'ın animasyonunu başlat
      if (widget.currentIndex < _animationControllers.length) {
        _animationControllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = widget.backgroundColor ?? 
      (isDark ? AppColors.darkSurface : AppColors.surface);
    final selectedColor = widget.selectedItemColor ?? AppColors.primary;
    final unselectedColor = widget.unselectedItemColor ?? AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : AppColors.shadowLight,
            blurRadius: widget.elevation * 2,
            offset: Offset(0, -widget.elevation / 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: AppDimensions.bottomNavHeight,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMd(context),
            vertical: AppDimensions.paddingSm(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == widget.currentIndex;
              
              return Expanded(
                child: _buildNavItem(
                  item,
                  index,
                  isSelected,
                  selectedColor,
                  unselectedColor,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BottomNavItem item,
    int index,
    bool isSelected,
    Color selectedColor,
    Color unselectedColor,
  ) {
    return Semantics(
      label: item.semanticLabel ?? item.label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => _handleTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimations[index],
            _fadeAnimations[index],
          ]),
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(
                vertical: 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Transform.scale(
                        scale: isSelected ? _scaleAnimations[index].value : 1.0,
                        child: AnimatedContainer(
                          duration: widget.animationDuration,
                          padding: EdgeInsets.all(AppDimensions.paddingXs(context)),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? selectedColor.withOpacity(0.1)
                              : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm(context)),
                          ),
                          child: Icon(
                            isSelected && item.activeIcon != null 
                              ? item.activeIcon!
                              : item.icon,
                            color: isSelected 
                              ? selectedColor
                              : unselectedColor.withOpacity(
                                  isSelected ? 1.0 : _fadeAnimations[index].value
                                ),
                            size: isSelected 
                              ? AppDimensions.bottomNavIconSize + 2
                              : AppDimensions.bottomNavIconSize,
                          ),
                        ),
                      ),
                      
                      // Badge
                      if (item.badgeCount != null && item.badgeCount! > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: FadeInAnimation(
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: item.badgeColor ?? AppColors.error,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                item.badgeCount! > 99 ? '99+' : '${item.badgeCount}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Label
                  AnimatedSwitcher(
                    duration: widget.animationDuration,
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    child: Text(
                      item.label,
                      key: ValueKey<bool>(isSelected),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected 
                          ? selectedColor
                          : unselectedColor,
                        fontWeight: isSelected 
                          ? FontWeight.w600
                          : FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  // Active indicator
                  AnimatedContainer(
                    duration: widget.animationDuration,
                    margin: EdgeInsets.only(top: AppDimensions.paddingXs(context)),
                    width: isSelected ? 20 : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Önceden tanımlanmış navigation item'ları
class BottomNavItems {
  /// Ana sayfa
  static BottomNavItem home({int? badgeCount}) {
    return BottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Ana Sayfa',
      semanticLabel: 'Ana sayfaya git',
      badgeCount: badgeCount,
    );
  }

  /// Kitaplık
  static BottomNavItem library({int? badgeCount}) {
    return BottomNavItem(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: 'Kitaplık',
      semanticLabel: 'Kitaplığa git',
      badgeCount: badgeCount,
    );
  }

  /// Asistan
  static BottomNavItem assistant({int? badgeCount}) {
    return BottomNavItem(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology,
      label: 'Asistan',
      semanticLabel: 'AI asistanına git',
      badgeCount: badgeCount,
    );
  }

  /// İlim Yolculukları
  static BottomNavItem journey({int? badgeCount}) {
    return BottomNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Yolculuklar',
      semanticLabel: 'İlim yolculuklarına git',
      badgeCount: badgeCount,
    );
  }

  /// Profil
  static BottomNavItem profile({int? badgeCount}) {
    return BottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
      semanticLabel: 'Profile git',
      badgeCount: badgeCount,
    );
  }

  /// Admin
  static BottomNavItem admin({int? badgeCount}) {
    return BottomNavItem(
      icon: Icons.admin_panel_settings_outlined,
      activeIcon: Icons.admin_panel_settings,
      label: 'Admin',
      semanticLabel: 'Admin paneline git',
      badgeCount: badgeCount,
    );
  }
}

/// Bottom navigation için skeleton loader
class CustomBottomNavigationSkeleton extends StatelessWidget {
  final int itemCount;

  const CustomBottomNavigationSkeleton({
    Key? key,
    this.itemCount = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: AppDimensions.bottomNavHeight,
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMd(context),
            vertical: AppDimensions.paddingSm(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(itemCount, (index) => 
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: AppDimensions.bottomNavIconSize,
                      height: AppDimensions.bottomNavIconSize,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm(context)),
                      ),
                    ),
                    SizedBox(height: AppDimensions.paddingXs(context)),
                    Container(
                      width: 40,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}