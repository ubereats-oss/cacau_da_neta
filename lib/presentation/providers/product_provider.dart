import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/services/image_upload_service.dart';
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService();
});
// Stream reativo — tela admin de produtos
final allProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.read(productRepositoryProvider).watchAllProducts();
});
// ---- Paginação ----
const int _kPageSize = 50;
class ProductPageState {
  const ProductPageState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDoc,
    this.error,
  });
  final List<ProductModel> products;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final String? error;
  ProductPageState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    String? error,
    bool clearLastDoc = false,
    bool clearError = false,
  }) {
    return ProductPageState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDoc: clearLastDoc ? null : (lastDoc ?? this.lastDoc),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
class ProductPaginationNotifier
    extends StateNotifier<ProductPageState> {
  ProductPaginationNotifier(this._repository)
      : super(const ProductPageState()) {
    fetchFirst();
  }
  final ProductRepository _repository;
  Future<void> fetchFirst() async {
    state = const ProductPageState(isLoading: true);
    try {
      final page = await _repository.getActiveProductsPage(
        limit: _kPageSize,
      );
      state = ProductPageState(
        products: page.products,
        lastDoc: page.lastDoc,
        hasMore: page.products.length >= _kPageSize,
        isLoading: false,
      );
    } catch (e) {
      state = ProductPageState(isLoading: false, error: e.toString());
    }
  }
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.lastDoc == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final page = await _repository.getActiveProductsPage(
        limit: _kPageSize,
        startAfter: state.lastDoc,
      );
      state = state.copyWith(
        products: [...state.products, ...page.products],
        lastDoc: page.lastDoc,
        hasMore: page.products.length >= _kPageSize,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
final productPaginationProvider =
    StateNotifierProvider<ProductPaginationNotifier, ProductPageState>(
  (ref) => ProductPaginationNotifier(ref.read(productRepositoryProvider)),
);
// ---- Ações de escrita (admin) ----
final productActionsProvider = Provider<ProductActions>((ref) {
  return ProductActions(
    repository: ref.read(productRepositoryProvider),
    imageUploadService: ref.read(imageUploadServiceProvider),
  );
});
class ProductActions {
  const ProductActions({
    required ProductRepository repository,
    required ImageUploadService imageUploadService,
  })  : _repository = repository,
        _imageUploadService = imageUploadService;
  final ProductRepository _repository;
  final ImageUploadService _imageUploadService;
  Future<void> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required bool isActive,
    required bool isFeatured,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    var imageUrl = '';
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${_sanitizeFileName(name)}.jpg';
    if (imageBytes != null) {
      imageUrl = await _imageUploadService.uploadProductImageBytes(
        bytes: imageBytes,
        fileName: fileName,
      );
    } else if (imageFile != null) {
      imageUrl = await _imageUploadService.uploadProductImage(
        file: imageFile,
        fileName: fileName,
      );
    }
    final product = ProductModel.empty().copyWith(
      name: name.trim(),
      description: description.trim(),
      price: price,
      category: category.trim(),
      imageUrl: imageUrl,
      isActive: isActive,
      isFeatured: isFeatured,
    );
    await _repository.createProduct(product);
  }

  Future<void> updateProduct({
    required ProductModel product,
    File? newImageFile,
    Uint8List? newImageBytes,
  }) async {
    var imageUrl = product.imageUrl;
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${_sanitizeFileName(product.name)}.jpg';
    if (newImageBytes != null) {
      imageUrl = await _imageUploadService.uploadProductImageBytes(
        bytes: newImageBytes,
        fileName: fileName,
      );
    } else if (newImageFile != null) {
      imageUrl = await _imageUploadService.uploadProductImage(
        file: newImageFile,
        fileName: fileName,
      );
    }
    await _repository.updateProduct(product.copyWith(imageUrl: imageUrl));
  }
  Future<void> setProductActive({
    required String productId,
    required bool isActive,
  }) async {
    await _repository.setProductActive(
      productId: productId,
      isActive: isActive,
    );
  }
  Future<void> deleteProduct(String productId) async {
    await _repository.deleteProduct(productId);
  }
  String _sanitizeFileName(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'produto' : normalized;
  }
}
