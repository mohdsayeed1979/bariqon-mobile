import 'entities/inquiry.dart';

/// Submits a completed inquiry to Bariqon. [InquiryDetailsFormScreen]
/// depends on this, not on Supabase directly, mirroring every other
/// repository in the app.
abstract class InquiryRepository {
  /// [sector] is a human-readable summary of which product category/
  /// categories the inquiry covers — resolved by the caller (which has
  /// access to category names) since this repository only knows how to
  /// submit, not how to look up a category by id.
  Future<void> submit(Inquiry inquiry, {required String sector});
}
