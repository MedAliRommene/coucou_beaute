import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isPrimary = true,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.primary : Colors.transparent,
          foregroundColor: isPrimary ? Colors.white : AppColors.primary,
          side: isPrimary ? null : const BorderSide(color: AppColors.primary, width: 2),
          elevation: isPrimary ? 0 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: isPrimary 
                        ? AppTextStyles.buttonMedium.copyWith(color: Colors.white)
                        : AppTextStyles.buttonMedium.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
      ),
    );
  }
}
