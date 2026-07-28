import '../../catalog/domain/entities/product.dart';
import '../domain/entities/inquiry_item.dart';
import '../domain/inquiry_cart_repository.dart';

/// In-memory [InquiryCartRepository] — the only implementation for Phase
/// 3, per the "local state only, no Supabase" brief. Lives entirely in
/// this instance's memory: cleared on app restart, never persisted, never
/// synced. That's an intentional, temporary limitation, not an oversight —
/// swapping this for a persisted/Supabase-backed implementation later
/// doesn't require touching [InquiryCartRepository]'s interface or any UI
/// code, only adding a new class and changing the provider that supplies
/// it (see inquiry_cart_controller.dart).
class InMemoryInquiryCartRepository implements InquiryCartRepository {
  final List<InquiryItem> _items = [];

  @override
  List<InquiryItem> getItems() => List.unmodifiable(_items);

  @override
  void addItem(Product product, {int quantity = 1}) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + quantity,
      );
    } else {
      _items.add(InquiryItem(product: product, quantity: quantity));
    }
  }

  @override
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
  }

  @override
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
    }
  }

  @override
  void clear() {
    _items.clear();
  }
}
