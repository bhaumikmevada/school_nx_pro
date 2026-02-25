import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.keyBoardType,
    this.onTap,
    this.isSuffixIcon = false,
    this.suffixIcon,
    this.obscureText = false,
    this.maxLength,
    this.padding,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final TextInputType? keyBoardType;
  final bool isSuffixIcon;
  final bool obscureText;
  final bool enabled;
  final Widget? suffixIcon;
  final int? maxLength;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: TextFormField(
        controller: controller,
        onTap: onTap,
        obscureText: obscureText,
        cursorColor: Colors.black,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          counterText: "",
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: isSuffixIcon ? suffixIcon : null,
        ),
        enabled: enabled,
        keyboardType: keyBoardType,
        validator: validator,
      ),
    );
  }
}
