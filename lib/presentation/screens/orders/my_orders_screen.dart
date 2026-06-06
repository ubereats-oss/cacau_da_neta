import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../../core/extensions/order_status_ui.dart';
import '../../../core/extensions/format_extensions.dart';
class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Pedidos')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Erro ao carregar pedidos.')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppColors.grey400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Você ainda não fez nenhum pedido.',
                    style: TextStyle(color: AppColors.grey600),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _OrderTile(order: orders[index]);
            },
          );
        },
      ),
    );
  }
}
class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final OrderModel order;
  String _formatCurrency(double value) => value.toBRL();
  String _formatDate(DateTime date) => date.toDisplayDate();
  @override
  Widget build(BuildContext context) {
    final date = order.createdAt?.toDate();
    final dateStr = date != null ? _formatDate(date) : '—';
    final shortId = '#${order.id.substring(0, 8).toUpperCase()}';
    final status = order.orderStatus;
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: status.color.withValues(alpha: 0.15),
          child: Icon(
            status.icon,
            color: status.color,
            size: 20,
          ),
        ),
        title: Text(
          shortId,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$dateStr · ${_formatCurrency(order.total)}',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: _StatusBadge(status: status),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.productName}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          _formatCurrency(item.subtotal),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _formatCurrency(order.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final OrderStatus status;
  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
