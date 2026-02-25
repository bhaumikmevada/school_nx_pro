import 'package:flutter/material.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.buttonText,
    required this.onTap,
    this.margin,
    this.backgroundColor,
    this.style,
    this.padding,
    this.radius = 25,
    this.min = false,
  });
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final String buttonText;
  final VoidCallback onTap;
  final TextStyle? style;
  final double radius;
  final bool min;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        onPressed: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.symmetric(vertical: 0),
          child: Row(
            mainAxisSize: min ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(buttonText, style: style ?? boldWhite),
            ],
          ),
        ),
      ),
    );
  }
}
