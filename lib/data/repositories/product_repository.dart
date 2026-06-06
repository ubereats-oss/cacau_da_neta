import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
class ProductPage {
  const ProductPage({required this.products, this.lastDoc});
  final List<ProductModel> products;
  final DocumentSnapshot? lastDoc;
}
class ProductRepository {
  ProductRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');
  Stream<List<ProductModel>> watchActiveProducts() {
    return _productsRef
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(_mapCollection);
  }
  Stream<List<ProductModel>> watchAllProducts() {
    return _productsRef.orderBy('name').snapshots().map(_mapCollection);
  }
  Stream<List<ProductModel>> watchFeaturedProducts() {
    return _productsRef
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map(_mapCollection);
  }
  /// Busca uma página de produtos ativos. [startAfter] é o último documento
  /// da página anterior (null = primeira página).
  Future<ProductPage> getActiveProductsPage({
    required int limit,
    DocumentSnapshot? startAfter,
  }) async {
    var query = _productsRef
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();
    final docs = snapshot.docs;
    return ProductPage(
      products: docs
          .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
          .toList(),
      lastDoc: docs.isNotEmpty ? docs.last : null,
    );
  }
  Future<ProductModel?> getProductById(String productId) async {
    final snapshot = await _productsRef.doc(productId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return ProductModel.fromMap(snapshot.id, snapshot.data()!);
  }
  Future<String> createProduct(ProductModel product) async {
    final now = FieldValue.serverTimestamp();
    final doc = await _productsRef.add({
      ...product.toMap(),
      'createdAt': now,
      'updatedAt': now,
    });
    return doc.id;
  }
  Future<void> updateProduct(ProductModel product) async {
    await _productsRef.doc(product.id).update({
      ...product.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  Future<void> setProductActive({
    required String productId,
    required bool isActive,
  }) async {
    await _productsRef.doc(productId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  Future<void> deleteProduct(String productId) async {
    await _productsRef.doc(productId).delete();
  }
  List<ProductModel> _mapCollection(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
        .toList();
  }
}
