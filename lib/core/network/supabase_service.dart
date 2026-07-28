import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Single access point for the Supabase client, per docs/ARCHITECTURE.md §8
/// and docs/SUPABASE_INTEGRATION.md §1 — repositories depend on this, not
/// on `package:supabase_flutter` directly, so the backend touchpoint stays
/// centralized.
///
/// The client itself is created by `Supabase.initialize(...)` during
/// bootstrap (see bootstrap.dart); this just exposes the already-initialized
/// singleton through Riverpod.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
