import 'package:flutter/material.dart';

/// Thin wrapper around [Scaffold] so every screen gets consistent safe-area
/// and background handling by construction, per docs/DESIGN_SYSTEM.md §8
/// and docs/IMPLEMENTATION_ROADMAP.md §2. Feature screens should reach for
/// this instead of a bare [Scaffold].
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.safeArea = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: safeArea ? SafeArea(child: body) : body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
