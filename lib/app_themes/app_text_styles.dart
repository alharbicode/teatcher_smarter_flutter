import 'package:flutter/material.dart';
import 'app_colors.dart';

/// أنماط النصوص في التطبيق
class AppTextStyles {
  // أنماط العناوين
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTextColor,
    letterSpacing: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTextColor,
    letterSpacing: 1.1,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTextColor,
  );

  // أنماط النصوص العادية
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.primaryTextColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.primaryTextColor,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.secondaryTextColor,
  );

  // أنماط الأزرار
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.buttonTextColor,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.buttonTextColor,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.buttonTextColor,
  );

  // أنماط مخصصة للتطبيق
  static const TextStyle instructionText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryColor,
  );

  static const TextStyle sentenceText = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.secondaryTextColor,
  );

  static const TextStyle wordButtonText = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.buttonTextColor,
  );

  static const TextStyle scoreText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTextColor,
  );

  static const TextStyle resultText = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryTextColor,
  );
}
