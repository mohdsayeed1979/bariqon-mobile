import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/address_book_repository.dart';
import '../domain/entities/saved_address.dart';

/// Persists a signed-in user's address book on-device — same
/// per-user-keyed `SharedPreferences?` pattern as
/// `LocalInquiryHistoryRepository`. There is no `addresses` table on the
/// shared backend, so this is genuinely local, not a stand-in for a
/// future sync — CRUD works fully offline.
class LocalAddressBookRepository implements AddressBookRepository {
  LocalAddressBookRepository(this._prefs);

  final SharedPreferences? _prefs;

  String _key(String userId) => 'address_book_$userId';

  @override
  Future<List<SavedAddress>> getAddresses(String userId) async {
    final raw = _prefs?.getString(_key(userId));
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _write(String userId, List<SavedAddress> addresses) async {
    await _prefs?.setString(
      _key(userId),
      jsonEncode(addresses.map((a) => a.toJson()).toList()),
    );
  }

  @override
  Future<void> save(String userId, SavedAddress address) async {
    final existing = await getAddresses(userId);
    final index = existing.indexWhere((a) => a.id == address.id);
    final updated = [...existing];
    // The very first address a user ever saves becomes the default —
    // otherwise nothing would ever be marked default and "Set as
    // Default" would be the only way to get one, which is needless
    // friction for the common single-address case.
    final effectiveAddress = existing.isEmpty
        ? address.copyWith(isDefault: true)
        : address;
    if (index >= 0) {
      updated[index] = effectiveAddress;
    } else {
      updated.add(effectiveAddress);
    }
    await _write(userId, updated);
  }

  @override
  Future<void> delete(String userId, String addressId) async {
    final existing = await getAddresses(userId);
    final wasDefault = existing.any((a) => a.id == addressId && a.isDefault);
    var updated = existing.where((a) => a.id != addressId).toList();
    // If the deleted address was the default, promote the next one so
    // there's never a saved address book with zero default when it's
    // non-empty.
    if (wasDefault && updated.isNotEmpty) {
      updated[0] = updated[0].copyWith(isDefault: true);
    }
    await _write(userId, updated);
  }

  @override
  Future<void> setDefault(String userId, String addressId) async {
    final existing = await getAddresses(userId);
    final updated = [
      for (final address in existing) address.copyWith(isDefault: address.id == addressId),
    ];
    await _write(userId, updated);
  }
}
