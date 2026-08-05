import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_preferences_service.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/local_address_book_repository.dart';
import '../../domain/address_book_repository.dart';
import '../../domain/entities/saved_address.dart';

final addressBookRepositoryProvider = Provider<AddressBookRepository>((ref) {
  return LocalAddressBookRepository(ref.watch(sharedPreferencesProvider));
});

/// The signed-in user's saved addresses. Empty for Guest/Signed Out —
/// same as [InquiryHistoryController], an address book only exists per
/// real account.
class AddressBookController extends AsyncNotifier<List<SavedAddress>> {
  AddressBookRepository get _repository => ref.read(addressBookRepositoryProvider);

  String? get _userId {
    final session = ref.read(authControllerProvider);
    return session is SignedInSession ? session.user.id : null;
  }

  @override
  Future<List<SavedAddress>> build() async {
    final session = ref.watch(authControllerProvider);
    if (session is! SignedInSession) return const [];
    return _repository.getAddresses(session.user.id);
  }

  Future<void> save(SavedAddress address) async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.save(userId, address);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String addressId) async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.delete(userId, addressId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> setDefault(String addressId) async {
    final userId = _userId;
    if (userId == null) return;
    await _repository.setDefault(userId, addressId);
    ref.invalidateSelf();
    await future;
  }
}

final addressBookControllerProvider =
    AsyncNotifierProvider<AddressBookController, List<SavedAddress>>(
      AddressBookController.new,
    );
