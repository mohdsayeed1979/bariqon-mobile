import '../domain/wishlist_repository.dart';

/// Local-only mock: in-memory, no network — same pattern as
/// [MockInquirySubmissionRepository]. Used automatically whenever the app
/// is unconfigured (tests, dev builds without `--dart-define` credentials).
class MockWishlistRepository implements WishlistRepository {
  final Set<String> _ids = {};

  @override
  Future<List<String>> getWishlistedProductIds() async => _ids.toList();

  @override
  Future<void> add(String productId) async => _ids.add(productId);

  @override
  Future<void> remove(String productId) async => _ids.remove(productId);
}
