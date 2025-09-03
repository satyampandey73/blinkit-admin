class BannerModel {
  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final int order;
  final bool active;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.order = 0,
    this.active = true,
  });

  factory BannerModel.fromMap(Map<String, dynamic> map, String id) {
    return BannerModel(
      id: id,
      imageUrl: map['imageUrl'] as String? ?? '',
      title: map['title'] as String?,
      subtitle: map['subtitle'] as String?,
      order: (map['order'] is int)
          ? map['order'] as int
          : int.tryParse('${map['order']}') ?? 0,
      active: map['active'] == null ? true : (map['active'] as bool),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'order': order,
      'active': active,
    };
  }
}
