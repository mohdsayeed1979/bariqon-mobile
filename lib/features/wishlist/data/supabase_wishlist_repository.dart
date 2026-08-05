import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/constants/supabase_tables.dart';
import '../../../core/error/exception_mapper.dart';
import '../domain/wishlist_repository.dart';

/// Real Supabase-backed wishlist, per
/// `docs/DISCOUNT_WISHLIST_MIGRATION.sql` (`wishlist` table, RLS scoped to
/// `auth.uid()`). Requires a signed-in user — callers (see
/// `wishlist_controller.dart`) never construct this for a Guest/Signed Out
/// session.
///
/// Every method degrades gracefully — not just reads — when the migration
/// hasn't been applied yet: PostgREST reports a missing table as
/// `PGRST205` ("Could not find the table ... in the schema cache"), not
/// the raw Postgres `42P01` that a direct `psql` error would use, and
/// this is what actually comes back over the REST API (confirmed live
/// against production). Before the migration runs, the wishlist behaves
/// as an in-session-only, non-persistent toggle instead of throwing —
/// matching what was already promised for reads, and fixing the "we
/// couldn't complete that" error that add/remove had no guard against at
/// all.
class SupabaseWishlistRepository implements WishlistRepository {
  SupabaseWishlistRepository(this._client);

  final supabase.SupabaseClient _client;

  static const _missingTableCode = 'PGRST205';

  String get _userId => _client.auth.currentUser!.id;

  bool _isMissingTable(Object error) =>
      error is supabase.PostgrestException && error.code == _missingTableCode;

  @override
  Future<List<String>> getWishlistedProductIds() async {
    try {
      final rows = await _client
          .from(SupabaseTables.wishlist)
          .select('product_id')
          .eq('user_id', _userId);
      return (rows as List<dynamic>)
          .map((row) => (row as Map<String, dynamic>)['product_id'].toString())
          .toList();
    } catch (error, stackTrace) {
      if (_isMissingTable(error)) return const [];
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> add(String productId) async {
    try {
      await _client.from(SupabaseTables.wishlist).insert({
        'user_id': _userId,
        'product_id': int.parse(productId),
      });
    } catch (error, stackTrace) {
      if (_isMissingTable(error)) return;
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  @override
  Future<void> remove(String productId) async {
    try {
      await _client
          .from(SupabaseTables.wishlist)
          .delete()
          .eq('user_id', _userId)
          .eq('product_id', int.parse(productId));
    } catch (error, stackTrace) {
      if (_isMissingTable(error)) return;
      throw ExceptionMapper.map(error, stackTrace);
    }
  }
}
