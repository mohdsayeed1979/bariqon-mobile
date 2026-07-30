import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Masked numeric PIN entry — reused by every App Lock PIN dialog (create/
/// change/remove) and the lock screen itself, rather than each rebuilding
/// its own `TextField` configuration.
class PinInputField extends StatelessWidget {
  const PinInputField({
    super.key,
    required this.controller,
    this.label,
    this.autofocus = false,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? label;
  final bool autofocus;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  static const int maxLength = 6;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      obscureText: true,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: maxLength,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(letterSpacing: 12),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        counterText: '',
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
