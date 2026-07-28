/// Notification toggle state for the Notification Preferences screen —
/// local UI-only state per the Phase 4 brief, no backend/push wiring yet.
class NotificationPreferences {
  const NotificationPreferences({
    this.orderAndInquiryUpdates = true,
    this.promotionsAndOffers = true,
    this.newArrivals = false,
  });

  final bool orderAndInquiryUpdates;
  final bool promotionsAndOffers;
  final bool newArrivals;

  NotificationPreferences copyWith({
    bool? orderAndInquiryUpdates,
    bool? promotionsAndOffers,
    bool? newArrivals,
  }) {
    return NotificationPreferences(
      orderAndInquiryUpdates: orderAndInquiryUpdates ?? this.orderAndInquiryUpdates,
      promotionsAndOffers: promotionsAndOffers ?? this.promotionsAndOffers,
      newArrivals: newArrivals ?? this.newArrivals,
    );
  }
}
