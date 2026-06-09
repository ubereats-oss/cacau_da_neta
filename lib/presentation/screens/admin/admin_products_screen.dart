import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../../core/extensions/format_extensions.dart';
import '../../providers/user_provider.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});
  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _isActive = true;
  bool _isFeatured = false;
  bool _isSaving = false;
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  ProductModel? _editingProduct;
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _startEditing(ProductModel product) {
    setState(() {
      _editingProduct = product;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _categoryController.text = product.category;
      _isActive = product.isActive;
      _isFeatured = product.isFeatured;
      _selectedImage = null;
    });
    Scrollable.ensureVisible(
      _formKey.currentContext ?? context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _cancelEditing() {
    setState(() {
      _editingProduct = null;
      _selectedImage = null;
      _selectedImageBytes = null;
      _isActive = true;
      _isFeatured = false;
    });
    _formKey.currentState?.reset();
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _categoryController.clear();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xfile == null) return;
    if (kIsWeb) {
      final bytes = await xfile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImage = null;
      });
    } else {
      setState(() {
        _selectedImage = File(xfile.path);
        _selectedImageBytes = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final rawPrice = _priceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(rawPrice);
    if (price == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preço inválido.')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final actions = ref.read(productActionsProvider);
      if (_editingProduct != null) {
        await actions.updateProduct(
          product: _editingProduct!.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            price: price,
            category: _categoryController.text.trim(),
            isActive: _isActive,
            isFeatured: _isFeatured,
          ),
          newImageFile: kIsWeb ? null : _selectedImage,
          newImageBytes: kIsWeb ? _selectedImageBytes : null,
        );
      } else {
        await actions.createProduct(
          name: _nameController.text,
          description: _descriptionController.text,
          price: price,
          category: _categoryController.text,
          isActive: _isActive,
          isFeatured: _isFeatured,
          imageFile: kIsWeb ? null : _selectedImage,
          imageBytes: kIsWeb ? _selectedImageBytes : null,
        );
      }
      if (!mounted) return;
      _cancelEditing();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editingProduct != null
                ? 'Produto atualizado com sucesso.'
                : 'Produto cadastrado com sucesso.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao salvar produto.')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text(
          'Excluir "${product.name}"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(productActionsProvider).deleteProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produto excluído.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao excluir produto.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider).value;
    if (currentUser == null || !currentUser.isMaster) {
      return const Scaffold(body: Center(child: Text('Acesso negado.')));
    }
    final productsAsync = ref.watch(allProductsProvider);
    final isEditing = _editingProduct != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Produto' : 'Admin - Produtos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isEditing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.edit,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Editando: ${_editingProduct!.name}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _cancelEditing,
                          child: const Text('Cancelar edição'),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome do produto.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe a categoria.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Preço'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o preço.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isActive,
                  title: const Text('Produto ativo'),
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                SwitchListTile(
                  value: _isFeatured,
                  title: const Text('Produto em destaque'),
                  onChanged: (value) => setState(() => _isFeatured = value),
                ),
                const SizedBox(height: 12),
                if (_selectedImage != null || _selectedImageBytes != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedImageBytes != null
                        ? Image.memory(
                            _selectedImageBytes!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            _selectedImage!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(height: 8),
                ] else if (isEditing &&
                    _editingProduct!.imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _editingProduct!.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 360,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Selecione uma nova foto para substituir.',
                    style: TextStyle(fontSize: 12, color: AppColors.grey600),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton(
                  onPressed: _pickImage,
                  child: Text(isEditing ? 'Trocar foto' : 'Selecionar foto'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isEditing ? 'Salvar alterações' : 'Cadastrar produto',
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Produtos cadastrados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Erro ao carregar produtos.'),
            data: (products) {
              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nenhum produto cadastrado.'),
                );
              }
              return Column(children: products.map(_buildProductTile).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(ProductModel product) {
    final priceText = product.price.toBRL();
    return Card(
      child: ListTile(
        leading: product.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  cacheWidth: 104,
                  errorBuilder: (_, _, _) => SizedBox(
                    width: 52,
                    height: 52,
                    child: Image.asset('assets/images/Logomarca com nome.jpeg'),
                  ),
                ),
              )
            : SizedBox(
                width: 52,
                height: 52,
                child: Image.asset('assets/images/Logomarca com nome.jpeg'),
              ),
        title: Text(product.name),
        subtitle: Text('${product.category} · $priceText'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: product.isActive,
              onChanged: (value) {
                ref
                    .read(productActionsProvider)
                    .setProductActive(productId: product.id, isActive: value);
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: () => _startEditing(product),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(product),
            ),
          ],
        ),
      ),
    );
  }
}
