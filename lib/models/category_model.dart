import 'dart:convert';

/// Model representing a child category with a name and an image URL/path.
class Category {
  final String name;
  final String image;

  Category({required this.name, required this.image});

  Category copyWith({String? name, String? image}) {
    return Category(name: name ?? this.name, image: image ?? this.image);
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'image': image};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      name: map['name'] as String? ?? '',
      image: map['image'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Category.fromJson(String source) =>
      Category.fromMap(json.decode(source));

  @override
  String toString() => 'Category(name: $name, image: $image)';
}

/// Model representing a main category (super category) that has a name
/// and a list of child `Category` items.
class SupCatModel {
  final String name;
  final List<Category> categories;

  SupCatModel({required this.name, required this.categories});

  SupCatModel copyWith({String? name, List<Category>? categories}) {
    return SupCatModel(
      name: name ?? this.name,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categories': categories.map((c) => c.toMap()).toList(),
    };
  }

  factory SupCatModel.fromMap(Map<String, dynamic> map) {
    final rawList = map['categories'];
    List<Category> parsed = [];
    if (rawList is List) {
      parsed = rawList.map((e) {
        if (e is Map<String, dynamic>) return Category.fromMap(e);
        if (e is String) return Category.fromJson(e);
        return Category(name: '', image: '');
      }).toList();
    }

    return SupCatModel(name: map['name'] as String? ?? '', categories: parsed);
  }

  String toJson() => json.encode(toMap());

  factory SupCatModel.fromJson(String source) =>
      SupCatModel.fromMap(json.decode(source));

  @override
  String toString() => 'SupCatModel(name: $name, categories: $categories)';
}
