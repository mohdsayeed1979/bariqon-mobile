import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_preferences_service.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/local_inquiry_history_repository.dart';
import '../../domain/entities/inquiry_history_entry.dart';
import '../../domain/inquiry_history_repository.dart';

final inquiryHistoryRepositoryProvider = Provider<InquiryHistoryRepository>((ref) {
  return LocalInquiryHistoryRepository(ref.watch(sharedPreferencesProvider));
});

/// The signed-in user's past inquiry submissions, newest first. Empty
/// for Guest/Signed Out — history only exists per real account.
class InquiryHistoryController extends AsyncNotifier<List<InquiryHistoryEntry>> {
  InquiryHistoryRepository get _repository => ref.read(inquiryHistoryRepositoryProvider);

  @override
  Future<List<InquiryHistoryEntry>> build() async {
    final session = ref.watch(authControllerProvider);
    if (session is! SignedInSession) return const [];
    return _repository.getHistory(session.user.id);
  }

  /// Called by [InquiryDetailsFormScreen] right after a successful
  /// submission. A no-op for a guest submission — there's no account to
  /// attach the record to, matching how the "My Orders" entry point
  /// itself is only reachable from the signed-in Profile list.
  Future<void> record(InquiryHistoryEntry entry) async {
    final session = ref.read(authControllerProvider);
    if (session is! SignedInSession) return;
    await _repository.record(session.user.id, entry);
    ref.invalidateSelf();
    await future;
  }
}

final inquiryHistoryControllerProvider =
    AsyncNotifierProvider<InquiryHistoryController, List<InquiryHistoryEntry>>(
      InquiryHistoryController.new,
    );
