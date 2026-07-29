import 'package:flutter/material.dart';

/// Content-shape widths shared across every screen that wraps itself in
/// [ResponsiveCenter], so "how wide should this get on a tablet" has one
/// answer per shape instead of a different guessed number per screen.
///
/// - [narrow]: a single-column form or focused action (Login, Register,
///   Forgot Password, Edit Profile, Inquiry Confirmation).
/// - [wide]: scrolling detail/list content (Product Detail, Search,
///   Inquiry Cart/Details, Profile, Settings and its sub-screens).
/// - [grid]: card grids/rails (Home, Categories, Product Listing) —
///   already the value those three screens used before this existed.
enum ContentWidth {
  narrow(420),
  wide(700),
  grid(900);

  const ContentWidth(this.maxWidth);

  final double maxWidth;
}

/// Centers [child] and caps its width past a phone-sized viewport. A no-op
/// on phones (the constraint never binds there) — this exists purely so
/// content doesn't stretch into unreadably-wide lines/oversized cards on
/// tablets, matching what Category List/Detail and Product Listing already
/// did for their own grids.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.width = ContentWidth.wide,
  });

  final Widget child;
  final ContentWidth width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width.maxWidth),
        child: child,
      ),
    );
  }
}
