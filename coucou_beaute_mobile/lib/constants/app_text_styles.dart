import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Styles de titre
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Styles de corps de texte
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Styles de bouton
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Styles spéciaux
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 1.5,
  );

  // Styles avec couleur primaire
  static TextStyle get h1Primary => h1.copyWith(color: AppColors.primary);
  static TextStyle get h2Primary => h2.copyWith(color: AppColors.primary);
  static TextStyle get bodyPrimary =>
      bodyMedium.copyWith(color: AppColors.primary);

  // Styles avec couleur secondaire
  static TextStyle get bodySecondary =>
      bodyMedium.copyWith(color: AppColors.textSecondary);
  static TextStyle get captionSecondary =>
      caption.copyWith(color: AppColors.textSecondary);
}
