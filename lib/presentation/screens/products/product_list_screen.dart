import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../cart/cart_screen.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedCategory = 'Todos';

  static const _categories = ['Todos', 'Nibs', 'Chá', 'Amêndoas', 'Geral'];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(productPaginationProvider.notifier).loadMore();
    }
  }

  int _categoryWeight(String category) {
    final idx = _categories.indexOf(category);
    return idx >= 0 ? idx : _categories.length;
  }

  List<ProductModel> _applyFilters(List<ProductModel> products) {
    var filtered = products;

    if (_selectedCategory != 'Todos') {
      filtered = filtered
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query),
          )
          .toList();
    }

    filtered.sort((a, b) {
      final weightA = _categoryWeight(a.category);
      final weightB = _categoryWeight(b.category);
      if (weightA != weightB) return weightA.compareTo(weightB);
      return a.name.compareTo(b.name);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final pageState = ref.watch(productPaginationProvider);
    final cartCount = ref.watch(cartProvider).totalItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          Badge(
            label: Text('$cartCount'),
            isLabelVisible: cartCount > 0,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(productPaginationProvider.notifier).fetchFirst(),
        child: Builder(
          builder: (context) {
            if (pageState.isLoading && pageState.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (pageState.error != null && pageState.products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    const Text('Erro ao carregar produtos.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref
                          .read(productPaginationProvider.notifier)
                          .fetchFirst(),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }

            final filtered = _applyFilters(pageState.products);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Buscar produto...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;

                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) => setState(() {
                          _selectedCategory = selected ? category : 'Todos';
                        }),
                        selectedColor: AppColors.primary.withValues(
                          alpha: 0.15,
                        ),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.grey700,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 48,
                                color: AppColors.grey400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty ||
                                        _selectedCategory != 'Todos'
                                    ? 'Nenhum produto encontrado.'
                                    : 'Nenhum produto disponível.',
                                style: const TextStyle(
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width >= 1100
                                ? 4
                                : width >= 700
                                    ? 3
                                    : 2;
                            return GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount:
                                  filtered.length +
                                  (pageState.isLoading &&
                                          pageState.products.isNotEmpty
                                      ? 1
                                      : (!pageState.hasMore &&
                                                pageState.products.isNotEmpty
                                            ? 1
                                            : 0)),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.68,
                                  ),
                              itemBuilder: (context, index) {
                            if (index == filtered.length) {
                              if (pageState.isLoading) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    '\${filtered.length} produto(s) encontrado(s)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final product = filtered[index];
                            return ProductCard(
                              product: product,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                            );
                          },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
