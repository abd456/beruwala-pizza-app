import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final List<String> imageUrls;
  final bool available;
  final Map<String, double> prices;
  final Map<String, String> variationDetails; // optional detail per variation key
  final DateTime createdAt;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.imageUrls,
    required this.available,
    required this.prices,
    this.variationDetails = const {},
    required this.createdAt,
  });

  // Convenience getter so existing code using item.imageUrl still works
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final pricesRaw = data['prices'] as Map<String, dynamic>? ?? {};

    // Back-compat: old docs store a single imageUrl string
    List<String> imageUrls;
    if (data['imageUrls'] is List) {
      imageUrls = List<String>.from(data['imageUrls'] as List);
    } else if ((data['imageUrl'] as String?)?.isNotEmpty == true) {
      imageUrls = [data['imageUrl'] as String];
    } else {
      imageUrls = [];
    }

    return MenuItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      imageUrls: imageUrls,
      available: data['available'] ?? true,
      prices: pricesRaw.map((key, value) => MapEntry(key, (value as num).toDouble())),
      variationDetails: (data['variationDetails'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'imageUrls': imageUrls,
      'available': available,
      'prices': prices,
      'variationDetails': variationDetails,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  double getPrice(String size) => prices[size] ?? 0.0;
}
