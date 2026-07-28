import 'package:flutter/foundation.dart';

import 'inquiry_contact_details.dart';
import 'inquiry_item.dart';

/// A completed (locally, in this phase — no backend submission yet)
/// inquiry: the cart snapshot plus contact details plus a mock reference
/// number, shown on the Confirmation screen. [referenceNumber] is
/// generated client-side purely for display continuity — the real
/// reference (if any) would come back from Supabase once submission is
/// actually wired up.
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
