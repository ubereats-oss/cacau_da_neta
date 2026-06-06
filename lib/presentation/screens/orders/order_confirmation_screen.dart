import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../../../core/extensions/format_extensions.dart';
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    required this.order,
  });
  final String orderId;
  final OrderModel order;
  String _formatCurrency(double value) => value.toBRL();
  @override
  Widget build(BuildContext context) {
    final shortId = '#${orderId.substring(0, 8).toUpperCase()}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido realizado'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: AppColors.accent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pedido recebido!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Número: $shortId',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Itens do pedido',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: order.items.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = order.items[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            '${item.quantity}x ${_formatCurrency(item.unitPrice)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.grey600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(item.subtotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _formatCurrency(order.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
