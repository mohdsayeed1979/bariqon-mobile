import '../../catalog/domain/entities/product.dart';
import 'entities/inquiry_item.dart';

/// Repository contract for the Inquiry Cart, per docs/ARCHITECTURE.md §7's
/// repository pattern — this interface is the stable contract the UI (via
/// [InquiryCartNotifier]) depends on. [InMemoryInquiryCartRepository] is
/// the only implementation for now (local state, per the Phase 3 brief);
/// swapping in a Supabase-backed implementation later means writing a new
/// class against this same interface and changing one provider override —
/// nothing in the UI or the notifier's method signatures needs to change.
abstract class InquiryCartRepository {
  List<InquiryItem> getItems();

  void addItem(Product product, {int quantity = 1});

  void removeItem(String productId);

  void updateQuantity(String productId, int quantity);

  void clear();
}
