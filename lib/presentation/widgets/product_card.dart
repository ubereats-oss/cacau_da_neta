import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../../core/extensions/format_extensions.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});
  final ProductModel product;
  final VoidCallback? onTap;
  // Extrai "250g" de "Embalagem: 250g"
  String _parseQuantidade(String description) {
    if (description.isEmpty) return '';
    final parts = description.split(':');
    if (parts.length < 2) return description.trim();
    return parts.last.trim();
  }

  @override
  Widget build(BuildContext context) {
    final priceText = product.price.toBRL();
    final quantidade = _parseQuantidade(product.description);
    final categoriaLabel = product.category;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 400,
                      errorBuilder: (_, _, _) {
                        return const _ProductPlaceholder();
                      },
                    )
                  : const _ProductPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (quantidade.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      quantidade,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    categoriaLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    priceText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black12,
      child: Center(
        child: Image.asset(
          'assets/images/Logomarca com nome.jpeg',
          height: 48,
          opacity: const AlwaysStoppedAnimation(0.3),
        ),
      ),
    );
  }
}
