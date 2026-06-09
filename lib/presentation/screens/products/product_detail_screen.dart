import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../auth_screen.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.product});
  final ProductModel product;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final cart = ref.watch(cartProvider);
    final isAuthenticated = authState.when(
      data: (user) => user != null,
      loading: () => false,
      error: (_, _) => false,
    );
    final inCart = cart.containsProduct(product.id);
    final priceText =
        'R\$ ${product.price.toStringAsFixed(2).replaceAll('.', ',')}';
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          Badge(
            label: Text('${cart.totalItems}'),
            isLabelVisible: cart.totalItems > 0,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWeb = constraints.maxWidth >= AppDimensions.webBreakpoint;

          if (isWeb) {
            // ── Web layout ──────────────────────────────────────────────
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left — image (40 %)
                      Flexible(
                        flex: 4,
                        child: SizedBox(
                          height: 400,
                          child: product.imageUrl.isNotEmpty
                              ? Image.network(
                                  product.imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  cacheWidth: 800,
                                  errorBuilder: (_, _, _) =>
                                      const _ProductPlaceholder(),
                                )
                              : const _ProductPlaceholder(),
                        ),
                      ),
                      // Right — details (60 %)
                      Flexible(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _DetailContent(
                            product: product,
                            priceText: priceText,
                            inCart: inCart,
                            isAuthenticated: isAuthenticated,
                            ref: ref,
                            context: context,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // ── Mobile layout (original) ──────────────────────────────────
          return ListView(
            children: [
              SizedBox(
                height: 280,
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: 800,
                        errorBuilder: (_, _, _) => const _ProductPlaceholder(),
                      )
                    : const _ProductPlaceholder(),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _DetailContent(
                  product: product,
                  priceText: priceText,
                  inCart: inCart,
                  isAuthenticated: isAuthenticated,
                  ref: ref,
                  context: context,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.product,
    required this.priceText,
    required this.inCart,
    required this.isAuthenticated,
    required this.ref,
    required this.context,
  });
  final ProductModel product;
  final String priceText;
  final bool inCart;
  final bool isAuthenticated;
  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.category,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          priceText,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          product.description.isEmpty
              ? 'Sem descrição cadastrada.'
              : product.description,
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(cartProvider.notifier).add(product);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 2),
                    content: Text(
                      inCart
                          ? '${product.name} atualizado no carrinho.'
                          : '${product.name} adicionado ao carrinho.',
                    ),
                  ),
                );
            },
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text(
              inCart ? 'Adicionar mais' : 'Adicionar ao carrinho',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: isAuthenticated
              ? OutlinedButton.icon(
                  onPressed: () {
                    ref.read(cartProvider.notifier).add(product);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CartScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('Comprar agora'),
                )
              : OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AuthScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar para comprar'),
                ),
        ),
      ],
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey200,
      child: Center(
        child: Image.asset(
          'assets/images/Logomarca com nome.jpeg',
          height: 64,
          opacity: const AlwaysStoppedAnimation(0.3),
        ),
      ),
    );
  }
}
