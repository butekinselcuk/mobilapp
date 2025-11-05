import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'dimensions.dart';

/// İslami App için ana tema konfigürasyonu
/// Material 3 teması üzerine özelleştirilmiş İslami kimlik
class AppTheme {
  // Private constructor - Singleton pattern
  AppTheme._();
  
  /// Light theme konfigürasyonu
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.black,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        background: AppColors.background,
        onBackground: AppColors.onBackground,
        error: AppColors.error,
        onError: Colors.white,
      ),
      
      // Scaffold - Beyaz arkaplan
      scaffoldBackgroundColor: Colors.white,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: AppDimensions.appBarElevation,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24.0,
        ),
      ),
      
      // Card Theme - Beyaz kartlar
      cardTheme: CardThemeData(
        elevation: AppDimensions.cardElevation,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.all(8.0),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: AppDimensions.elevationSm,
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          vertical: 8.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: AppTypography.buttonText,
          minimumSize: const Size(0, 40.0),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          vertical: 8.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: AppTypography.buttonText,
          minimumSize: const Size(0, 40.0),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          vertical: 8.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: AppTypography.buttonText,
          minimumSize: const Size(0, 40.0),
        ),
      ),
      
      // Input Decoration Theme - Beyaz input alanları
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.inputPaddingHorizontal,
          vertical: AppDimensions.inputPaddingVertical,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.inputLabel.copyWith(
          color: AppColors.textHint,
        ),
        hintStyle: AppTypography.inputText.copyWith(
          color: AppColors.textHint,
        ),
        errorStyle: AppTypography.errorText.copyWith(
          color: AppColors.error,
        ),
      ),
      
      // Bottom Navigation Bar Theme - Beyaz navigasyon
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: AppDimensions.bottomNavElevation,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedIconTheme: IconThemeData(
          size: 28.0,
        ),
        unselectedIconTheme: IconThemeData(
          size: 24.0,
        ),
        selectedLabelStyle: AppTypography.labelSmall,
        unselectedLabelStyle: AppTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.secondary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textHint,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelLarge,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.textPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.textPrimary),
        displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.textPrimary),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.textPrimary),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textHint),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textHint),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24.0,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary,
        labelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
          vertical: 4.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }
  
  /// Dark theme konfigürasyonu
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        onPrimary: Colors.black,
        secondary: AppColors.secondary,
        onSecondary: Colors.black,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkOnSurface,
        background: AppColors.darkBackground,
        onBackground: AppColors.darkOnBackground,
        error: AppColors.error,
        onError: Colors.white,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.darkBackground,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: AppDimensions.appBarElevation,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24.0,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: AppDimensions.cardElevation,
        color: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        margin: const EdgeInsets.all(8.0),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.black,
          elevation: AppDimensions.elevationSm,
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: AppTypography.buttonText,
          minimumSize: const Size(0, 40.0),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: AppDimensions.bottomNavElevation,
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.secondary,
        unselectedItemColor: AppColors.textHint,
        selectedIconTheme: IconThemeData(
          size: 28.0,
        ),
        unselectedIconTheme: IconThemeData(
          size: 24.0,
        ),
        selectedLabelStyle: AppTypography.labelSmall,
        unselectedLabelStyle: AppTypography.labelSmall,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Text Theme (Dark)
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.darkOnBackground),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.darkOnBackground),
        displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.darkOnBackground),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.darkOnBackground),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.darkOnBackground),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.darkOnBackground),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.darkOnBackground),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.darkOnBackground),
        titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.darkOnBackground),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.darkOnBackground),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.darkOnBackground),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.darkOnBackground),
        labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textHint),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textHint),
      ),
      
      // Icon Theme (Dark)
      iconTheme: const IconThemeData(
        color: AppColors.darkOnSurface,
        size: 24.0,
      ),
      
      // Input Decoration Theme (Dark)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.inputPaddingHorizontal,
          vertical: AppDimensions.inputPaddingVertical,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        labelStyle: AppTypography.inputLabel.copyWith(
          color: AppColors.textHint,
        ),
        hintStyle: AppTypography.inputText.copyWith(
          color: AppColors.textHint,
        ),
      ),
    );
  }
}