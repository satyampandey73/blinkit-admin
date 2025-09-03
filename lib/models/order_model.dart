import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String id;
  final String productId;
  final String name;
  final String image;
  final double price;
  final String quantity; // e.g. "1 kg"
  final int count;
  final double totalPrice;
  final double originalAmount;
  final double savings;
  final int? discountPercent;

  OrderItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    required this.count,
    required this.totalPrice,
    required this.originalAmount,
    required this.savings,
    this.discountPercent,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id']?.toString() ?? '',
      productId: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
      price: (map['price'] is num)
          ? (map['price'] as num).toDouble()
          : double.tryParse('${map['price']}') ?? 0.0,
      quantity: map['quantity']?.toString() ?? '',
      count: (map['count'] is int)
          ? map['count'] as int
          : int.tryParse('${map['count']}') ?? 0,
      totalPrice: (map['totalPrice'] is num)
          ? (map['totalPrice'] as num).toDouble()
          : double.tryParse('${map['totalPrice']}') ?? 0.0,
      originalAmount: (map['originalAmount'] is num)
          ? (map['originalAmount'] as num).toDouble()
          : double.tryParse('${map['originalAmount']}') ?? 0.0,
      savings: (map['savings'] is num)
          ? (map['savings'] as num).toDouble()
          : double.tryParse('${map['savings']}') ?? 0.0,
      discountPercent: (map['discountPercent'] is int)
          ? map['discountPercent'] as int
          : (map['discountPercent'] is num)
          ? (map['discountPercent'] as num).toInt()
          : (map['discountPercent'] != null
                ? int.tryParse('${map['discountPercent']}')
                : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
      'count': count,
      'totalPrice': totalPrice,
      'originalAmount': originalAmount,
      'savings': savings,
      if (discountPercent != null) 'discountPercent': discountPercent,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String status;
  final DateTime createdAt;
  final double totalAmount;
  final double? originalAmount;
  final double? savings;
  final Map<String, dynamic>? deliveryAddress;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.totalAmount,
    this.originalAmount,
    this.savings,
    this.deliveryAddress,
    required this.items,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, {String? id}) {
    // createdAt in Firestore may be a Timestamp
    DateTime created;
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      created = rawCreated.toDate();
    } else if (rawCreated is int) {
      created = DateTime.fromMillisecondsSinceEpoch(rawCreated);
    } else if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    final itemsRaw = map['items'];
    final itemsList = <OrderItem>[];
    if (itemsRaw is List) {
      for (final e in itemsRaw) {
        if (e is Map<String, dynamic>) {
          itemsList.add(OrderItem.fromMap(e));
        } else if (e is Map) {
          itemsList.add(OrderItem.fromMap(Map<String, dynamic>.from(e)));
        }
      }
    }

    return OrderModel(
      id: id ?? map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      status: map['status']?.toString() ?? 'placed',
      createdAt: created,
      totalAmount: (map['totalAmount'] is num)
          ? (map['totalAmount'] as num).toDouble()
          : double.tryParse('${map['totalAmount']}') ?? 0.0,
      originalAmount: (map['originalAmount'] is num)
          ? (map['originalAmount'] as num).toDouble()
          : (map['originalAmount'] != null
                ? double.tryParse('${map['originalAmount']}')
                : null),
      savings: (map['savings'] is num)
          ? (map['savings'] as num).toDouble()
          : (map['savings'] != null
                ? double.tryParse('${map['savings']}')
                : null),
      deliveryAddress: map['deliveryAddress'] is Map
          ? Map<String, dynamic>.from(map['deliveryAddress'])
          : null,
      items: itemsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalAmount': totalAmount,
      if (originalAmount != null) 'originalAmount': originalAmount,
      if (savings != null) 'savings': savings,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }
}
