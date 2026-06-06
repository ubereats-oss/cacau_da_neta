import 'package:cloud_firestore/cloud_firestore.dart';
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isActive;
  final bool isFeatured;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isActive,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
  });
  factory ProductModel.empty() {
    return const ProductModel(
      id: '',
      name: '',
      description: '',
      price: 0,
      imageUrl: '',
      category: '',
      isActive: true,
      isFeatured: false,
      createdAt: null,
      updatedAt: null,
    );
  }
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    bool? isActive,
    bool? isFeatured,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      price: _parsePrice(map['price']),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      isActive: map['isActive'] == true,
      isFeatured: map['isFeatured'] == true,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }
  static double _parsePrice(dynamic value) {
    if (value is int) {
      return value.toDouble();
    }
    if (value is double) {
      return value;
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }
}
