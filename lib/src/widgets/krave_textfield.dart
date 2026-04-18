import 'package:flutter/material.dart';
import 'glass_container.dart';

class KraveTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final int? maxLength;
  final TextInputAction? textInputAction;

  const KraveTextField({
    super.key,
    this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onChanged,
    this.maxLength,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GlassContainer(
          borderRadius: BorderRadius.circular(16),
          opacity: 0.05,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            maxLength: maxLength,
            textInputAction: textInputAction,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              counterText: "", // Hide character counter
              hintText: hintText,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                fontSize: 14,
              ),
              prefixIcon: prefixIcon != null 
                ? Icon(prefixIcon, color: theme.colorScheme.primary.withOpacity(0.7), size: 20)
                : null,
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}
