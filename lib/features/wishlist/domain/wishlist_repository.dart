/// Persists which products a signed-in customer has saved. Returns/accepts
/// product ids only (not full [Product] objects) — the presentation layer
/// cross-references these against the already-fetched catalog list
/// (`productsProvider`), the same "derive client-side from what's already
/// fetched" pattern `catalog_selectors.dart` uses, rather than this
/// repository owning a second product-fetching path.
abstract class WishlistRepository {
  Future<List<String>> getWishlistedProductIds();
  Future<void> add(String productId);
  Future<void> remove(String productId);
}
