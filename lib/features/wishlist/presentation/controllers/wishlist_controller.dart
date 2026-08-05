import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/mock_wishlist_repository.dart';
import '../../data/supabase_wishlist_repository.dart';
import '../../domain/wishlist_repository.dart';

/// Same env-conditional selection as every other repository — mock for
/// tests/unconfigured builds, real Supabase writes otherwise.
final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  if (!EnvConfig.isConfigured) return MockWishlistRepository();
  return SupabaseWishlistRepository(ref.watch(supabaseClientProvider));
});

/// The signed-in user's wishlisted product ids. Empty for Guest/Signed Out
/// — a wishlist only exists for a real account, so there's nothing to
/// fetch (and no repository call is made) until a session exists.
class WishlistController extends AsyncNotifier<Set<String>> {
  WishlistRepository get _repository => ref.read(wishlistRepositoryProvider);

  @override
  Future<Set<String>> build() async {
    final session = ref.watch(authControllerProvider);
    if (session is! SignedInSession) return const {};
    final ids = await _repository.getWishlistedProductIds();
    return ids.toSet();
  }

  /// Adds or removes [productId], optimistically updating local state
  /// first (so the heart icon flips instantly) and reverting it if the
  /// backend call fails.
  Future<void> toggle(String productId) async {
    final current = state.value ?? const <String>{};
    final wasWishlisted = current.contains(productId);
    final optimistic = current.toSet();
    if (wasWishlisted) {
      optimistic.remove(productId);
    } else {
      optimistic.add(productId);
    }
    state = AsyncData(optimistic);

    try {
      if (wasWishlisted) {
        await _repository.remove(productId);
      } else {
        await _repository.add(productId);
      }
    } catch (error) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final wishlistControllerProvider =
    AsyncNotifierProvider<WishlistController, Set<String>>(
      WishlistController.new,
    );

/// Keeps the wishlist live-updating across a user's devices — Postgres
/// Changes on `wishlist`, filtered to the current user, matching
/// `catalogRealtimeSyncProvider`'s "invalidate and refetch" pattern
/// exactly. A no-op when unconfigured or signed out, and harmless if the
/// `wishlist` table/Realtime publication doesn't exist yet.
final wishlistRealtimeSyncProvider = Provider<void>((ref) {
  if (!EnvConfig.isConfigured) return;
  final session = ref.watch(authControllerProvider);
  if (session is! SignedInSession) return;

  final client = ref.watch(supabaseClientProvider);
  final channel = client.channel('wishlist-sync-${session.user.id}')
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: SupabaseTables.wishlist,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: session.user.id,
      ),
      callback: (_) => ref.invalidate(wishlistControllerProvider),
    )
    ..subscribe();

  ref.onDispose(() => client.removeChannel(channel));
});
