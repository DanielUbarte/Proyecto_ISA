import 'package:flutter/material.dart';
import '../app/theme.dart';

enum CustomButtonVariant { primary, secondary, green, danger, outline }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final CustomButtonVariant variant;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.variant = CustomButtonVariant.primary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case CustomButtonVariant.primary:
        bg = AppColors.primaryTeal;
        fg = Colors.white;
        break;
      case CustomButtonVariant.green:
        bg = AppColors.forestGreen;
        fg = Colors.white;
        break;
      case CustomButtonVariant.secondary:
        bg = const Color(0xFFE2E8F0);
        fg = AppColors.textDark;
        break;
      case CustomButtonVariant.danger:
        bg = AppColors.dangerBg;
        fg = AppColors.dangerRed;
        break;
      case CustomButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.primaryTeal;
        border = const BorderSide(color: AppColors.primaryTeal, width: 1.5);
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: variant == CustomButtonVariant.outline ? 0 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: border,
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
