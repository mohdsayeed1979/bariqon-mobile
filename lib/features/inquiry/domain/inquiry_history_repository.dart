import 'entities/inquiry_history_entry.dart';

abstract class InquiryHistoryRepository {
  Future<List<InquiryHistoryEntry>> getHistory(String userId);
  Future<void> record(String userId, InquiryHistoryEntry entry);
}
