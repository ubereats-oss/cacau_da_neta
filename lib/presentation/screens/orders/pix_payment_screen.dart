import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/order_model.dart';
import '../../providers/order_provider.dart';
import 'order_confirmation_screen.dart';
//import 'order_confirmation_screen.dart';
import '../../../core/extensions/format_extensions.dart';
class PixPaymentScreen extends ConsumerStatefulWidget {
  const PixPaymentScreen({
    super.key,
    required this.pixData,
  });
  final PixPaymentData pixData;
  @override
  ConsumerState<PixPaymentScreen> createState() => _PixPaymentScreenState();
}
class _PixPaymentScreenState extends ConsumerState<PixPaymentScreen> {
  bool _copied = false;
  bool _paid = false;
  @override
  Widget build(BuildContext context) {
    // Observa o pedido em tempo real
    final orderAsync =
        ref.watch(orderStreamProvider(widget.pixData.orderId));
    // Detecta pagamento confirmado
    orderAsync.whenData((order) {
      if (order != null && order.isPaid && !_paid) {
        _paid = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSuccessAndNavigate(order);
        });
      }
    });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirm = await _confirmCancel(context);
        if (confirm == true && context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pagar com Pix'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: () async {
                final confirm = await _confirmCancel(context);
                if (confirm == true && context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.white),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Valor
              _TotalCard(
                total: orderAsync.maybeWhen(
                  data: (o) => o?.total ?? 0,
                  orElse: () => 0,
                ),
              ),
              const SizedBox(height: 24),
              // Instruções
              const _StepList(),
              const SizedBox(height: 24),
              // QR Code
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blackWithOpacity(0.08),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Image.memory(
                    base64Decode(widget.pixData.pixQrCodeBase64),
                    width: 220,
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Código copia-e-cola
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pix Copia e Cola',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.grey700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.pixData.pixCode,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.grey600,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Botão copiar
              FilledButton.icon(
                onPressed: _copied ? null : _copiarCodigo,
                icon: Icon(_copied ? Icons.check : Icons.copy_outlined),
                label: Text(_copied ? 'Copiado!' : 'Copiar código Pix'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _copied ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              // Status de espera
              _WaitingIndicator(orderAsync: orderAsync),
              const SizedBox(height: 16),
              const Text(
                'O pagamento é confirmado automaticamente.\nNão feche esta tela até a confirmação.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.grey500,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _copiarCodigo() async {
    await Clipboard.setData(ClipboardData(text: widget.pixData.pixCode));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }
  Future<bool?> _confirmCancel(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar pagamento?'),
        content: const Text(
          'Se sair agora o pedido ficará como "Aguardando pagamento". '
          'Você pode retomá-lo em "Meus Pedidos".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar pagando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
  void _showSuccessAndNavigate(OrderModel order) {
    // Fecha o diálogo de espera e navega para a tela de confirmação
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(
          orderId: order.id,
          order: order,
        ),
      ),
      (route) => route.isFirst,
    );
  }
}
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});
  final double total;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Total a pagar',
            style: TextStyle(color: AppColors.white, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            total.toBRL(),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
class _StepList extends StatelessWidget {
  const _StepList();
  @override
  Widget build(BuildContext context) {
    const steps = [
      'Abra o app do seu banco',
      'Selecione a opção Pix',
      'Escaneie o QR Code ou use o código Copia e Cola',
      'Confirme o pagamento',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Como pagar:',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...steps.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
class _WaitingIndicator extends StatelessWidget {
  const _WaitingIndicator({required this.orderAsync});
  final AsyncValue<OrderModel?> orderAsync;
  @override
  Widget build(BuildContext context) {
    final status = orderAsync.maybeWhen(
      data: (o) => o?.orderStatus,
      orElse: () => null,
    );
    final isPaid = status != null &&
        status != OrderStatus.awaitingPayment &&
        status != OrderStatus.cancelled;
    if (isPaid) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: AppColors.success),
          SizedBox(width: 8),
          Text(
            'Pagamento confirmado!',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 10),
        Text(
          'Aguardando confirmação do pagamento...',
          style: TextStyle(color: AppColors.grey600, fontSize: 13),
        ),
      ],
    );
  }
}
