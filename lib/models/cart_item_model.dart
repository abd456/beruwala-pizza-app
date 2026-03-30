class CartItemModel {
  final String itemId;
  final String name;
  final String imageUrl;
  final String size;
  final int quantity;
  final double price; // price per unit for selected size

  const CartItemModel({
    required this.itemId,
    required this.name,
    required this.imageUrl,
    required this.size,
    required this.quantity,
    required this.price,
  });

  double get totalPrice => price * quantity;

  CartItemModel copyWith({
    String? itemId,
    String? name,
    String? imageUrl,
    String? size,
    int? quantity,
    double? price,
  }) {
    return CartItemModel(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toOrderItem() {
    return {
      'itemId': itemId,
      'name': name,
      'size': size,
      'quantity': quantity,
      'price': price,
    };
  }
}
