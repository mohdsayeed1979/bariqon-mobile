import 'package:flutter/foundation.dart';

import 'inquiry_contact_details.dart';
import 'inquiry_item.dart';

/// A completed inquiry: the cart snapshot plus contact details plus a
/// reference number, submitted via [InquiryRepository][inquiry_repository.dart]
/// and shown on the Confirmation screen. [referenceNumber] is generated
/// client-side and is the *only* reference number that will ever exist for
/// this submission — the anon Supabase role can insert into
/// `cms_contact_messages` but cannot read rows back, so there is no
/// server-generated id/timestamp this app could substitute in instead.
@immutable
class Inquiry {
  const Inquiry({
    required this.referenceNumber,
    required this.items,
    required this.contact,
    required this.submittedAt,
  });

  final String referenceNumber;
  final List<InquiryItem> items;
  final InquiryContactDetails contact;
  final DateTime submittedAt;

  int get totalQuantity =>
      items.fold(0, (sum, item) => sum + item.quantity);

  double get estimatedTotal =>
      items.fold(0.0, (sum, item) => sum + item.subtotal);
}
