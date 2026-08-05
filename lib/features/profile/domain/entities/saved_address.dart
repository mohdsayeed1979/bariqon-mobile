/// A customer's saved delivery/contact address. There is no `addresses`
/// table on the shared backend today, so this is kept on-device per
/// signed-in user — see [AddressBookRepository].
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.country,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String country;
  final bool isDefault;

  SavedAddress copyWith({
    String? label,
    String? fullName,
    String? phone,
    String? addressLine,
    String? city,
    String? country,
    bool? isDefault,
  }) {
    return SavedAddress(
      id: id,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'fullName': fullName,
    'phone': phone,
    'addressLine': addressLine,
    'city': city,
    'country': country,
    'isDefault': isDefault,
  };

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String,
      label: json['label'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      addressLine: json['addressLine'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
