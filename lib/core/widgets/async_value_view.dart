import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_state_view.dart';

/// Dispatches an [AsyncValue] to loading/error/data rendering, per
/// docs/ARCHITECTURE.md §4 and docs/IMPLEMENTATION_ROADMAP.md §12/§14 — the
/// standard shape every Supabase-backed screen renders through, so screens
/// don't hand-roll `.when(...)` with inconsistent loading/error UI.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.error,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget Function()? loading;
  final Widget Function(Object error, StackTrace stackTrace)? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () =>
          loading?.call() ??
          const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          error?.call(err, stack) ??
          Center(child: ErrorStateView(onRetry: onRetry)),
    );
  }
}
