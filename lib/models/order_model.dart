import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String itemId;
  final String name;
  final String size;
  final int quantity;
  final double price;

  const OrderItem({
    required this.itemId,
    required this.name,
    required this.size,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      itemId: map['itemId'] ?? '',
      name: map['name'] ?? '',
      size: map['size'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'size': size,
      'quantity': quantity,
      'price': price,
    };
  }

  double get totalPrice => price * quantity;
}

class OrderModel {
  final String id;
  final int orderNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String type; // "delivery" or "pickup"
  final String address;
  final String status; // "received" | "preparing" | "ready" | "delivered"
  final String note;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.type,
    required this.address,
    required this.status,
    required this.note,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>?) ?? [];

    return OrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? 0,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      type: data['type'] ?? 'pickup',
      address: data['address'] ?? '',
      status: data['status'] ?? 'received',
      note: data['note'] ?? '',
      items: itemsList.map((e) => OrderItem.fromMap(e as Map<String, dynamic>)).toList(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'type': type,
      'address': address,
      'status': status,
      'note': note,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isDelivery => type == 'delivery';
  bool get isPickup => type == 'pickup';
}
