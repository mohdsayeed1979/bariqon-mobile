import 'package:flutter/material.dart';

/// Outlined text field with label/error text, per docs/DESIGN_SYSTEM.md §8.
/// Reused across every form screen (Inquiry Details today; Sign In/Up,
/// Edit Profile once they exist) so field styling and error presentation
/// stay consistent.
///
/// Wraps [TextFormField] (not a plain [TextField]) so it drops straight
/// into a [Form] with a [validator] — the shape [Validators] was already
/// documented to expect, per docs/PACKAGE_SELECTION.md §11, before any
/// form actually needed it.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.onChanged,
    this.maxLines = 1,
    this.validator,
    this.autovalidateMode,
    this.textInputAction,
  });

  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      onChanged: onChanged,
      maxLines: obscureText ? 1 : maxLines,
      validator: validator,
      autovalidateMode: autovalidateMode,
      textInputAction: textInputAction,
      decoration: InputDecoration(labelText: label, errorText: errorText),
    );
  }
}
