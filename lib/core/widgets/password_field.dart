import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// A password [TextFormField] with a visibility toggle — reused across
/// Sign In and Registration rather than each screen managing its own
/// obscure-text state and eye icon.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;

  /// Fires on the keyboard's "Next"/"Done" action — see AppTextField's
  /// param of the same name.
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          tooltip: _obscure ? l10n.passwordShowTooltip : l10n.passwordHideTooltip,
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
