import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddress {
  final String id;
  final String label;        // e.g. "Home", "Work", "Mum's Place"
  final String address;      // delivery address text
  final String contactName;  // name of the person receiving the order
  final String contactPhone; // phone of the person receiving (may differ from account)
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    this.contactName = '',
    this.contactPhone = '',
    this.isDefault = false,
  });

  factory SavedAddress.fromMap(Map<String, dynamic> data) {
    return SavedAddress(
      id: data['id'] as String? ?? '',
      label: data['label'] as String? ?? '',
      address: data['address'] as String? ?? '',
      contactName: data['contactName'] as String? ?? '',
      contactPhone: data['contactPhone'] as String? ?? '',
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'address': address,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'isDefault': isDefault,
      };

  SavedAddress copyWith({
    String? id,
    String? label,
    String? address,
    String? contactName,
    String? contactPhone,
    bool? isDefault,
  }) =>
      SavedAddress(
        id: id ?? this.id,
        label: label ?? this.label,
        address: address ?? this.address,
        contactName: contactName ?? this.contactName,
        contactPhone: contactPhone ?? this.contactPhone,
        isDefault: isDefault ?? this.isDefault,
      );
}

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String role;
  final DateTime createdAt;
  final List<SavedAddress> addresses;

  const UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.addresses = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawAddresses = data['addresses'] as List<dynamic>? ?? [];
    return UserModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: data['role'] as String? ?? 'customer',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      addresses: rawAddresses
          .map((a) => SavedAddress.fromMap(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'phone': phone,
        'role': role,
        'createdAt': Timestamp.fromDate(createdAt),
        'addresses': addresses.map((a) => a.toMap()).toList(),
      };

  bool get isAdmin => role == 'admin';
  bool get isCustomer => role == 'customer';

  /// Returns the address marked as default, or the first one if none is marked.
  SavedAddress? get defaultAddress {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );
  }
}
