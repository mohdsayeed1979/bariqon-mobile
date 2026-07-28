import 'package:flutter/material.dart';

/// Reusable search input, per docs/DESIGN_SYSTEM.md §8 and
/// docs/IMPLEMENTATION_ROADMAP.md §15. Phase 2A ships the UI shell only —
/// [onChanged]/[onSubmitted] are wired up by the caller but nothing calls
/// into a repository yet; real query execution (debounce, results) lands
/// with the Catalog feature in a later phase.
class AppBarSearchField extends StatelessWidget {
  const AppBarSearchField({
    super.key,
    this.controller,
    this.hintText,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String? hintText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hintText,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
      ),
    );
  }
}
