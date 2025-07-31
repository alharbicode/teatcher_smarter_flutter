import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// ثيم التطبيق الرئيسي
class AppTheme {
  // الثيم الرئيسي للتطبيق
  static ThemeData lightTheme = ThemeData(
    // الألوان الأساسية
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.scaffoldBackgroundColor,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      error: AppColors.errorColor,
    ),

    // تعيين الخط الافتراضي
    fontFamily: 'Cairo',

    // أنماط النصوص
    textTheme: TextTheme(
      displayLarge: AppTextStyles.headingLarge.copyWith(fontFamily: 'Cairo'),
      displayMedium: AppTextStyles.headingMedium.copyWith(fontFamily: 'Cairo'),
      displaySmall: AppTextStyles.headingSmall.copyWith(fontFamily: 'Cairo'),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(fontFamily: 'Cairo'),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(fontFamily: 'Cairo'),
      bodySmall: AppTextStyles.bodySmall.copyWith(fontFamily: 'Cairo'),
      labelLarge: AppTextStyles.buttonLarge.copyWith(fontFamily: 'Cairo'),
      labelMedium: AppTextStyles.buttonMedium.copyWith(fontFamily: 'Cairo'),
      labelSmall: AppTextStyles.buttonSmall.copyWith(fontFamily: 'Cairo'),
    ),

    // أنماط الأزرار
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.buttonPrimaryColor,
        foregroundColor: AppColors.buttonTextColor,
        disabledBackgroundColor: AppColors.buttonDisabledColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: AppTextStyles.buttonMedium.copyWith(fontFamily: 'Cairo'),
        elevation: 4,
        shadowColor: AppColors.primaryColor.withOpacity(0.2),
      ),
    ),

    // أنماط البطاقات
    cardTheme: CardTheme(
      color: AppColors.cardBackgroundColor,
      elevation: 4,
      shadowColor: AppColors.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),

    // أنماط الحقول النصية
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primaryColor),
      ),
      labelStyle: AppTextStyles.bodyMedium.copyWith(fontFamily: 'Cairo'),
      hintStyle: AppTextStyles.bodySmall.copyWith(fontFamily: 'Cairo'),
    ),

    // أنماط شريط التطبيق
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.primaryColor),
      titleTextStyle: AppTextStyles.headingMedium.copyWith(
        color: AppColors.primaryColor,
        fontFamily: 'Cairo',
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      shadowColor: AppColors.primaryColor.withOpacity(0.08),
    ),

    // أنماط مؤشر التقدم
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.primaryColor,
      linearTrackColor: AppColors.primaryColor.withOpacity(0.15),
    ),

    // أنماط الأيقونات
    iconTheme: IconThemeData(
      color: AppColors.primaryColor,
      size: 26,
    ),

    // أنماط الحوارات
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      titleTextStyle: AppTextStyles.headingMedium.copyWith(fontFamily: 'Cairo'),
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(fontFamily: 'Cairo'),
    ),

    // أنماط التبويب
    tabBarTheme: TabBarTheme(
      labelColor: AppColors.primaryColor,
      unselectedLabelColor: AppColors.secondaryTextColor,
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.secondaryColor],
        ),
      ),
      labelStyle: AppTextStyles.buttonMedium.copyWith(fontFamily: 'Cairo'),
      unselectedLabelStyle:
          AppTextStyles.buttonMedium.copyWith(fontFamily: 'Cairo'),
    ),
  );

  // الثيم الداكن للتطبيق (يمكن إضافته لاحقاً)
  static ThemeData darkTheme = ThemeData.dark().copyWith(
      // يمكن تخصيص الثيم الداكن هنا
      );
}
