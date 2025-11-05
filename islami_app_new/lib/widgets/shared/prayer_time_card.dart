import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/dimensions.dart';
import '../../theme/typography.dart';
import '../animations/fade_in_animation.dart';
import '../animations/slide_animation.dart';

/// Modern namaz vakitleri kartı
class PrayerTimeCard extends StatelessWidget {
  /// Şehir adı
  final String city;
  
  /// Miladi tarih
  final String readableDate;
  
  /// Hicri tarih
  final String hijriDate;
  
  /// Sıradaki namaz vakti
  final String nextPrayer;
  
  /// Geri sayım
  final String countdown;
  
  /// Namaz vakitleri
  final Map<String, String> prayerTimes;
  
  /// Konum kullanılıyor mu
  final bool usingLocation;
  
  /// Namaz vakti tıklama callback'i
  final Function(String prayerName, String prayerTime)? onPrayerTimeTap;

  const PrayerTimeCard({
    Key? key,
    required this.city,
    required this.readableDate,
    required this.hijriDate,
    required this.nextPrayer,
    required this.countdown,
    required this.prayerTimes,
    this.usingLocation = false,
    this.onPrayerTimeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.marginMd(context)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.prayerTimeCardRadius(context)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [
                AppColors.primary.withOpacity(0.2),
                AppColors.primaryDark.withOpacity(0.1),
              ]
            : AppColors.prayerTimeGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.prayerTimeCardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kısım - Şehir ve tarih
            FadeInAnimation(
              delay: const Duration(milliseconds: 100),
              child: _buildHeader(context),
            ),
            
            SizedBox(height: AppDimensions.paddingLg(context)),
            
            // Orta kısım - Geri sayım
            FadeInAnimation(
              delay: const Duration(milliseconds: 200),
              child: _buildCountdown(context),
            ),
            
            SizedBox(height: AppDimensions.paddingLg(context)),
            
            // Alt kısım - Namaz vakitleri
            SlideAnimation(
              delay: const Duration(milliseconds: 300),
              direction: SlideDirection.bottomToTop,
              distance: 0.3,
              child: _buildPrayerTimes(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    usingLocation ? Icons.my_location : Icons.location_on,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    size: 18,
                  ),
                  SizedBox(width: AppDimensions.paddingXs(context)),
                  Expanded(
                    child: Text(
                      city.toUpperCase(),
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark ? AppColors.primaryLight : AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.paddingXs(context)),
              if (readableDate.isNotEmpty)
                Text(
                  "$readableDate / $hijriDate",
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark 
                      ? AppColors.textHint 
                      : AppColors.prayerTimeText.withOpacity(0.8),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(AppDimensions.paddingSm(context)),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl(context)),
          ),
          child: Icon(
            Icons.mosque,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        children: [
          if (nextPrayer.isNotEmpty)
            Text(
              "$nextPrayer VAKTİNE",
              style: AppTypography.labelMedium.copyWith(
                color: isDark 
                  ? AppColors.textSecondary 
                  : AppColors.prayerTimeText.withOpacity(0.7),
                letterSpacing: 1.0,
              ),
            ),
          SizedBox(height: AppDimensions.paddingXs(context)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLg(context),
              vertical: AppDimensions.paddingSm(context),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg(context)),
              border: Border.all(
                color: (isDark ? AppColors.primaryLight : AppColors.primary).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              countdown.isNotEmpty ? countdown : '--:--:--',
              style: AppTypography.prayerTime.copyWith(
                color: isDark ? AppColors.primaryLight : AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimes(BuildContext context) {
    if (prayerTimes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMd(context)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd(context)),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: prayerTimes.entries.map((entry) {
          final isNext = entry.key == nextPrayer;
          return _buildPrayerTimeItem(
            context,
            entry.key,
            entry.value,
            isNext,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrayerTimeItem(
    BuildContext context,
    String name,
    String time,
    bool isNext,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onPrayerTimeTap?.call(name, time),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: AppDimensions.paddingSm(context),
            horizontal: AppDimensions.paddingXs(context),
          ),
          decoration: BoxDecoration(
            color: isNext 
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm(context)),
            border: isNext 
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                )
              : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: AppTypography.prayerName.copyWith(
                  color: isNext 
                    ? AppColors.primary
                    : AppColors.prayerTimeText,
                  fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.paddingXs(context)),
              Text(
                time,
                style: AppTypography.labelMedium.copyWith(
                  color: isNext 
                    ? AppColors.primary
                    : AppColors.prayerTimeText,
                  fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                  fontSize: isNext ? 13 : 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Namaz vakti kartı için skeleton loader
class PrayerTimeCardSkeleton extends StatelessWidget {
  const PrayerTimeCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.marginMd(context)),
      padding: EdgeInsets.all(AppDimensions.prayerTimeCardPadding(context)),
      decoration: BoxDecoration(
        color: AppColors.prayerTime,
        borderRadius: BorderRadius.circular(AppDimensions.prayerTimeCardRadius(context)),
      ),
      child: Column(
        children: [
          // Header skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 150,
                    height: 13,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppDimensions.paddingLg(context)),
          
          // Countdown skeleton
          Column(
            children: [
              Container(
                width: 120,
                height: 13,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 150,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppDimensions.paddingLg(context)),
          
          // Prayer times skeleton
          Container(
            padding: EdgeInsets.all(AppDimensions.paddingMd(context)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => 
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 35,
                        height: 12,
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
        ],
      ),
    );
  }
}