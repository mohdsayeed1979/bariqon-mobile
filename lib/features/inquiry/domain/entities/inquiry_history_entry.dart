/// A lightweight local record of a past inquiry submission — shown on
/// the "My Orders" screen. `cms_contact_messages` has no `user_id`/order
/// concept (this is a wholesale quote-request table, not an e-commerce
/// orders table — see docs/API_CONTRACT.md §"Inquiry History"), so
/// history is kept on-device per signed-in user rather than fetched from
/// the backend.
class InquiryHistoryEntry {
  const InquiryHistoryEntry({
    required this.referenceNumber,
    required this.submittedAt,
    required this.itemCount,
    required this.totalQuantity,
  });

  final String referenceNumber;
  final DateTime submittedAt;
  final int itemCount;
  final int totalQuantity;

  Map<String, dynamic> toJson() => {
    'referenceNumber': referenceNumber,
    'submittedAt': submittedAt.toIso8601String(),
    'itemCount': itemCount,
    'totalQuantity': totalQuantity,
  };

  factory InquiryHistoryEntry.fromJson(Map<String, dynamic> json) {
    return InquiryHistoryEntry(
      referenceNumber: json['referenceNumber'] as String,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      itemCount: json['itemCount'] as int,
      totalQuantity: json['totalQuantity'] as int,
    );
  }
}
