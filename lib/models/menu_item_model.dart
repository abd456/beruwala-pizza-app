import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String imageUrl;
  final bool available;
  final Map<String, double> prices; // {small: 1200, medium: 1800, large: 2400}
  final DateTime createdAt;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.available,
    required this.prices,
    required this.createdAt,
  });

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final pricesRaw = data['prices'] as Map<String, dynamic>? ?? {};
    return MenuItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      available: data['available'] ?? true,
      prices: pricesRaw.map((key, value) => MapEntry(key, (value as num).toDouble())),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'available': available,
      'prices': prices,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  double getPrice(String size) => prices[size] ?? 0.0;
}
