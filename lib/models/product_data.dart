class ProductData {
  final String title;
  final String description;
  final double price;
  final List<String> imagePaths;
  
  ProductData({
    required this.title,
    required this.description,
    required this.price,
    required this.imagePaths,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'imagePaths': imagePaths,
    };
  }
  
  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
    );
  }
  
  ProductData copyWith({
    String? title,
    String? description,
    double? price,
    List<String>? imagePaths,
  }) {
    return ProductData(
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}
