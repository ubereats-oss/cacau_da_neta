import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/order_provider.dart';
import '../../../core/extensions/order_status_ui.dart';
import '../../../core/extensions/format_extensions.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProfileProvider).value;
    if (currentUser == null || !currentUser.isMaster) {
      return const Scaffold(body: Center(child: Text('Acesso negado.')));
    }
    final filter = ref.watch(adminOrderStatusFilterProvider);
    final ordersAsync = ref.watch(adminOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: Column(
        children: [
          // Chips de filtro por status
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: [
                _StatusFilterChip(
                  label: 'Todos',
                  selected: filter == null,
                  onSelected: () =>
                      ref.read(adminOrderStatusFilterProvider.notifier).state =
                          null,
                ),
                const SizedBox(width: 8),
                ...OrderStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _StatusFilterChip(
                      label: status.label,
                      selected: filter == status.value,
                      color: status.color,
                      onSelected: () =>
                          ref
                                  .read(adminOrderStatusFilterProvider.notifier)
                                  .state =
                              status.value,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Erro ao carregar pedidos.')),
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: AppColors.grey400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          filter == null
                              ? 'Nenhum pedido ainda.'
                              : 'Nenhum pedido com este status.',
                          style: const TextStyle(color: AppColors.grey600),
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
                    return _AdminOrderTile(order: orders[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: effectiveColor.withValues(alpha: 0.15),
      checkmarkColor: effectiveColor,
      labelStyle: TextStyle(
        color: selected ? effectiveColor : AppColors.grey700,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _AdminOrderTile extends ConsumerWidget {
  const _AdminOrderTile({required this.order});
  final OrderModel order;
  String _formatCurrency(double value) => value.toBRL();
  String _formatDateTime(DateTime date) => date.toDisplayDateTime();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = order.createdAt?.toDate();
    final dateStr = date != null ? _formatDateTime(date) : '—';
    final shortId = '#${order.id.substring(0, 8).toUpperCase()}';
    final status = order.orderStatus;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortId,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.customerName,
                      style: const TextStyle(
                        color: AppColors.grey700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppColors.grey500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.totalItems} ${order.totalItems == 1 ? 'item' : 'itens'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(status: status),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(order.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OrderDetailSheet(order: order, ref: ref),
    );
  }
}

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({required this.order, required this.ref});
  final OrderModel order;
  final WidgetRef ref;
  String _formatCurrency(double value) => value.toBRL();
  String _formatDateTime(DateTime date) => date.toDisplayDateTime();
  @override
  Widget build(BuildContext context) {
    final date = order.createdAt?.toDate();
    final dateStr = date != null ? _formatDateTime(date) : '—';
    final shortId = '#${order.id.substring(0, 8).toUpperCase()}';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pedido $shortId',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: const TextStyle(color: AppColors.grey600, fontSize: 13),
              ),
              Text(
                '${order.customerName} · ${order.customerEmail}',
                style: const TextStyle(color: AppColors.grey700, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'Itens',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.productName}',
                              ),
                            ),
                            Text(
                              _formatCurrency(item.subtotal),
                              style: const TextStyle(
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
                    const SizedBox(height: 24),
                    const Text(
                      'Alterar status',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: OrderStatus.values
                          .map(
                            (s) => _StatusButton(
                              status: s,
                              isSelected: order.orderStatus == s,
                              onTap: () async {
                                await ref
                                    .read(orderActionsProvider)
                                    .updateStatus(order.id, s.value);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });
  final OrderStatus status;
  final bool isSelected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return GestureDetector(
      onTap: isSelected ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withValues(alpha: isSelected ? 1.0 : 0.3),
          ),
        ),
        child: Text(
          status.label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : color,
            fontSize: 13,
          ),
        ),
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
