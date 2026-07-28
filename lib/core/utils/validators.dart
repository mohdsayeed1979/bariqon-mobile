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
}
