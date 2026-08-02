import 'entities/inquiry.dart';

/// Submits a completed [Inquiry] to the backend. Separate from
/// [InquiryCartRepository] (which only manages the local cart list) —
/// this is the actual "send it" step.
abstract class InquirySubmissionRepository {
  Future<void> submit(Inquiry inquiry);
}
