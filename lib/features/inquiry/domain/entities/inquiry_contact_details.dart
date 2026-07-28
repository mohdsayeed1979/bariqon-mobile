import 'package:flutter/foundation.dart';

/// Contact fields collected on the Inquiry Details Form — field shape
/// mirrors the confirmed `cms_contact_messages` columns from
/// docs/API_CONTRACT.md §3 (name, company, email, phone) plus `country`
/// and `notes`/specifications, so this maps cleanly onto the real table
/// once submission is actually wired to Supabase (not in this phase).
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
