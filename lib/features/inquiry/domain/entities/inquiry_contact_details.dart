import 'package:flutter/foundation.dart';

/// Contact fields collected on the Inquiry Details Form. [fullName],
/// [email], [mobile], and [company] map directly onto `cms_contact_messages`
/// columns (`name`, `email`, `phone`, `company`). [country] and [notes] do
/// **not** — that table has no matching columns for either — so
/// [SupabaseInquiryRepository][supabase_inquiry_repository.dart] folds both
/// into the free-text `specs` column instead of sending them as fields.
@immutable
class InquiryContactDetails {
  const InquiryContactDetails({
    required this.fullName,
    required this.company,
    required this.email,
    required this.mobile,
    required this.country,
    required this.notes,
  });

  const InquiryContactDetails.empty()
    : fullName = '',
      company = '',
      email = '',
      mobile = '',
      country = '',
      notes = '';

  final String fullName;
  final String company;
  final String email;
  final String mobile;
  final String country;
  final String notes;
}
