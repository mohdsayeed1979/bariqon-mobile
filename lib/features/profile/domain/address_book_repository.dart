import 'entities/saved_address.dart';

abstract class AddressBookRepository {
  Future<List<SavedAddress>> getAddresses(String userId);
  Future<void> save(String userId, SavedAddress address);
  Future<void> delete(String userId, String addressId);
  Future<void> setDefault(String userId, String addressId);
}
