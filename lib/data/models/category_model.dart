class CategoryModel {
  final int id;
  final String name;
  final String? imageSrc;
  final int parent;
  final int count;

  CategoryModel({
    required this.id,
    required this.name,
    this.imageSrc,
    this.parent = 0,
    this.count = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String? imgUrl;
    if (json['image'] != null && json['image'] is Map) {
      final src = json['image']['src'];
      if (src is String) {
        imgUrl = src;
      }
    }

    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imageSrc: imgUrl,
      parent: json['parent'] ?? 0,
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': imageSrc != null ? {'src': imageSrc} : null,
      'parent': parent,
      'count': count,
    };
  }
}
