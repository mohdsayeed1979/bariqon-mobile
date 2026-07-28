/// Hand-rolled field validators, per docs/PACKAGE_SELECTION.md §11 (no form
/// package pulled in for this app's modest validation needs). Pure
/// functions returning a nullable error message, following Flutter's
/// `FormFieldValidator<String>` shape so they drop straight into a
/// `TextFormField.validator` once forms exist.
class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );

  static String? required(String? value, {String message = 'Required'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(
    String? value, {
    String message = 'Enter a valid email address',
  }) {
    if (value == null || value.trim().isEmpty) return message;
    if (!_emailPattern.hasMatch(value.trim())) return message;
    return null;
  }

  /// Deliberately permissive — this validates that a phone number was
  /// plausibly entered (enough digits), not that it's a real, dialable
  /// number in a specific country's format. Good enough for a UI-only
  /// form; a stricter/format-aware check can replace this once real
  /// submission (and whatever the backend expects) exists.
  static String? phone(
    String? value, {
    String message = 'Enter a valid mobile number',
  }) {
    if (value == null || value.trim().isEmpty) return message;
    final digitCount = value.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (digitCount < 6) return message;
    return null;
  }
}
