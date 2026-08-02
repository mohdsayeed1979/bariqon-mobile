import '../domain/entities/inquiry.dart';
import '../domain/inquiry_submission_repository.dart';

/// Local-only mock: no network, just a simulated delay so loading states
/// feel real — same pattern as [MockAuthRepository].
class MockInquirySubmissionRepository implements InquirySubmissionRepository {
  static const _simulatedDelay = Duration(milliseconds: 600);

  @override
  Future<void> submit(Inquiry inquiry) async {
    await Future.delayed(_simulatedDelay);
  }
}
