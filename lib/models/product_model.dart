// Simple product model used by product screens.
// Fields: name, images, quantity, price, discountPercent,
// optional description, productDetail, returnPolicy.
import 'dart:convert';

class ProductModel {
  final String?
  id; // optional identifier (assumption: some payloads include an id)
  final String name;
  final List<String> images;
  final String quantity;
  final double price;
  final double discountPercent;
  final String? superCategory;
  final String? subCategory;
  final String? description;
  final String? productDetail;
  final String? returnPolicy;

  ProductModel({
    this.id,
    required this.name,
    List<String>? images,
    String? quantity,
    double? price,
    double? discountPercent,
    this.superCategory,
    this.subCategory,
    this.description,
    this.productDetail,
    this.returnPolicy,
  }) : images = images ?? [],
       quantity = quantity ?? '0',
       price = price ?? 0.0,
       discountPercent = discountPercent ?? 0.0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // images may be under 'image' or 'images'
    List<String> parseImages(dynamic val) {
      if (val is List) return val.map((e) => e?.toString() ?? '').toList();
      if (val is String && val.isNotEmpty) return [val];
      return <String>[];
    }

    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return ProductModel(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      images: parseImages(json['image'] ?? json['images']),
      quantity: json['quantity']?.toString() ?? '0',
      price: toDouble(json['price'] ?? json['mrp'] ?? json['rate']),
      discountPercent: toDouble(
        json['discountpercent'] ?? json['discount_percent'] ?? json['discount'],
      ),
      superCategory:
          json['superCategory']?.toString() ??
          json['super_category']?.toString() ??
          json['super category']?.toString(),
      subCategory:
          json['subCategory']?.toString() ??
          json['sub_category']?.toString() ??
          json['sub category']?.toString(),
      description: json['description']?.toString(),
      productDetail:
          json['product detail']?.toString() ??
          json['product_detail']?.toString() ??
          json['productDetail']?.toString(),
      returnPolicy:
          json['return']?.toString() ?? json['returnPolicy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    // keep key `image` to match existing backend shape in the repo
    'image': images,
    'quantity': quantity,
    'price': price,
    'discountpercent': discountPercent,
    'superCategory': superCategory,
    'subCategory': subCategory,
    'description': description,
    'product detail': productDetail,
    'return': returnPolicy,
  };

  ProductModel copyWith({
    String? id,
    String? name,
    List<String>? images,
    String? quantity,
    double? price,
    double? discountPercent,
    String? superCategory,
    String? subCategory,
    String? description,
    String? productDetail,
    String? returnPolicy,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      images: images ?? this.images,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      discountPercent: discountPercent ?? this.discountPercent,
      superCategory: superCategory ?? this.superCategory,
      subCategory: subCategory ?? this.subCategory,
      description: description ?? this.description,
      productDetail: productDetail ?? this.productDetail,
      returnPolicy: returnPolicy ?? this.returnPolicy,
    );
  }

  @override
  String toString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel &&
        other.id == id &&
        other.name == name &&
        _listEquals(other.images, images) &&
        other.quantity == quantity &&
        other.price == price &&
        other.discountPercent == discountPercent &&
        other.superCategory == superCategory &&
        other.subCategory == subCategory &&
        other.description == description &&
        other.productDetail == productDetail &&
        other.returnPolicy == returnPolicy;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    Object.hashAll(images),
    quantity,
    price,
    discountPercent,
    superCategory,
    subCategory,
    description,
    productDetail,
    returnPolicy,
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
