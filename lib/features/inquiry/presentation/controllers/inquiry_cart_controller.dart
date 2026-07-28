import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../catalog/domain/entities/product.dart';
import '../../data/in_memory_inquiry_cart_repository.dart';
import '../../domain/entities/inquiry_item.dart';
import '../../domain/inquiry_cart_repository.dart';

/// The single place the cart's backing repository is chosen — swap
/// [InMemoryInquiryCartRepository] for a Supabase-backed implementation
/// here, later, and nothing else in this file or in the UI needs to
/// change (see docs on [InquiryCartRepository]).
final inquiryCartRepositoryProvider = Provider<InquiryCartRepository>((ref) {
  return InMemoryInquiryCartRepository();
});

/// Riverpod state for the Inquiry Cart, per the Phase 3 brief ("use
/// Riverpod, keep state local, design it so it can later be replaced with
/// Supabase without changing the UI"). Every method here just delegates to
/// [InquiryCartRepository] and re-reads its state — this class is
/// presentation-layer glue, not where the actual cart logic lives, so a
/// future repository swap needs no changes here either.
class InquiryCartNotifier extends Notifier<List<InquiryItem>> {
  InquiryCartRepository get _repository => ref.read(inquiryCartRepositoryProvider);

  @override
  List<InquiryItem> build() => _repository.getItems();

  void addProduct(Product product, {int quantity = 1}) {
    _repository.addItem(product, quantity: quantity);
    state = _repository.getItems();
  }

  void removeProduct(String productId) {
    _repository.removeItem(productId);
    state = _repository.getItems();
  }

  void updateQuantity(String productId, int quantity) {
    _repository.updateQuantity(productId, quantity);
    state = _repository.getItems();
  }

  void clear() {
    _repository.clear();
    state = _repository.getItems();
  }
}

final inquiryCartProvider =
    NotifierProvider<InquiryCartNotifier, List<InquiryItem>>(
      InquiryCartNotifier.new,
    );

/// Derived, read-only providers — kept here alongside the cart so every
/// screen that just needs a count/total (the nav badge, the cart summary)
/// watches a small provider instead of recomputing a fold over the full
/// item list itself.
final inquiryCartItemCountProvider = Provider<int>((ref) {
  return ref
      .watch(inquiryCartProvider)
      .fold<int>(0, (sum, item) => sum + item.quantity);
});

final inquiryCartSubtotalProvider = Provider<double>((ref) {
  return ref
      .watch(inquiryCartProvider)
      .fold<double>(0, (sum, item) => sum + item.subtotal);
});
