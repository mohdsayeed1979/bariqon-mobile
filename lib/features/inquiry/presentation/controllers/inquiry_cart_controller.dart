import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../data/in_memory_inquiry_cart_repository.dart';
import '../../data/mock_inquiry_submission_repository.dart';
import '../../data/supabase_inquiry_submission_repository.dart';
import '../../domain/entities/inquiry_item.dart';
import '../../domain/inquiry_cart_repository.dart';
import '../../domain/inquiry_submission_repository.dart';

/// The cart itself stays local/in-memory regardless of environment — it's
/// presentation-layer scratch state, never persisted or sent anywhere
/// until [InquirySubmissionRepository.submit] is called.
final inquiryCartRepositoryProvider = Provider<InquiryCartRepository>((ref) {
  return InMemoryInquiryCartRepository();
});

/// Same env-conditional selection as auth/catalog — unconfigured (every
/// `flutter test` run, or a dev run without `--dart-define` credentials)
/// falls back to the mock; a configured build submits real inquiries to
/// the same backend the website uses (see [SupabaseInquirySubmissionRepository]).
final inquirySubmissionRepositoryProvider = Provider<InquirySubmissionRepository>((ref) {
  if (!EnvConfig.isConfigured) return MockInquirySubmissionRepository();
  return SupabaseInquirySubmissionRepository(ref.watch(supabaseClientProvider));
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
