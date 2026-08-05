import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/inquiry_history_entry.dart';
import '../domain/inquiry_history_repository.dart';

/// Persists inquiry history on-device, keyed per signed-in user id (so a
/// second account signing in on the same device never sees the first
/// account's history) — same `SharedPreferences?`-injected pattern as
/// [LocalPreferencesService], including its "null instance = nothing
/// persisted yet" degrade for `flutter test`/pre-bootstrap runs.
class LocalInquiryHistoryRepository implements InquiryHistoryRepository {
  LocalInquiryHistoryRepository(this._prefs);

  final SharedPreferences? _prefs;

  String _key(String userId) => 'inquiry_history_$userId';

  @override
  Future<List<InquiryHistoryEntry>> getHistory(String userId) async {
    final raw = _prefs?.getString(_key(userId));
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => InquiryHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> record(String userId, InquiryHistoryEntry entry) async {
    final existing = await getHistory(userId);
    final updated = [entry, ...existing];
    await _prefs?.setString(
      _key(userId),
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }
}
