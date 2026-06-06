import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/payment_config_repository.dart';
import 'auth_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});
final paymentConfigRepositoryProvider = Provider<PaymentConfigRepository>((
  ref,
) {
  return PaymentConfigRepository();
});
// ---- Config do Mercado Pago ----
final mercadoPagoConfigProvider = StreamProvider<MercadoPagoConfig>((ref) {
  return ref.read(paymentConfigRepositoryProvider).watchConfig();
});
// ---- Pedidos do cliente logado ----
final customerOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.read(orderRepositoryProvider).watchCustomerOrders(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.value([]),
  );
});
// ---- Watch de um pedido específico (para polling de pagamento) ----
final orderStreamProvider = StreamProvider.family<OrderModel?, String>((
  ref,
  orderId,
) {
  return ref.read(orderRepositoryProvider).watchOrder(orderId);
});
// ---- Admin: filtro de status ----
final adminOrderStatusFilterProvider = StateProvider<String?>((ref) => null);
// ---- Admin: stream com filtro ----
final adminOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final filter = ref.watch(adminOrderStatusFilterProvider);
  final repo = ref.read(orderRepositoryProvider);
  if (filter == null) return repo.watchAllOrders();
  return repo.watchOrdersByStatus(filter);
});
// ---- Ações ----
final orderActionsProvider = Provider<OrderActions>((ref) {
  return OrderActions(
    repository: ref.read(orderRepositoryProvider),
    configRepository: ref.read(paymentConfigRepositoryProvider),
  );
});

class PixPaymentData {
  const PixPaymentData({
    required this.orderId,
    required this.pixCode,
    required this.pixQrCodeBase64,
    required this.paymentId,
  });
  final String orderId;
  final String pixCode;
  final String pixQrCodeBase64;
  final String paymentId;
}

class OrderActions {
  const OrderActions({
    required OrderRepository repository,
    required PaymentConfigRepository configRepository,
  }) : _repository = repository,
       _configRepository = configRepository;
  final OrderRepository _repository;
  final PaymentConfigRepository _configRepository;

  /// Cria o pedido no Firestore e gera o Pix via Cloud Function.
  /// Retorna [PixPaymentData] com QR Code e código copia-e-cola.
  Future<PixPaymentData> placeOrderWithPix({
    required String customerId,
    required String customerName,
    required String customerEmail,
    required List<CartItemModel> items,
  }) async {
    // 1. Verifica se MP está configurado
    final config = await _configRepository.getConfig();
    if (!config.isConfigured) {
      throw Exception(
        'Pagamento não configurado. Solicite ao administrador que configure o Mercado Pago.',
      );
    }
    // 2. Monta itens do pedido
    final orderItems = items
        .map(
          (i) => OrderItemModel(
            productId: i.product.id,
            productName: i.product.name,
            productImageUrl: i.product.imageUrl,
            quantity: i.quantity,
            unitPrice: i.product.price,
          ),
        )
        .toList();
    final total = orderItems.fold(0.0, (acc, i) => acc + i.subtotal);
    // 3. Cria pedido com status awaiting_payment
    final order = OrderModel(
      id: '',
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      items: orderItems,
      total: total,
      status: OrderStatus.awaitingPayment.value,
    );
    final orderId = await _repository.createOrder(order);
    // 4. Chama Cloud Function para gerar Pix
    final functions = FirebaseFunctions.instanceFor(
      region: 'southamerica-east1',
    );
    final callable = functions.httpsCallable('criarPagamentoPix');
    final result = await callable.call({
      'orderId': orderId,
      'total': total,
      'customerEmail': customerEmail,
      'customerName': customerName,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final pixCode = data['pixCode'] as String;
    final pixQrCodeBase64 = data['pixQrCodeBase64'] as String;
    final paymentId = data['paymentId'].toString();
    // 5. Salva dados do Pix no pedido
    //await _repository.updatePaymentData(
    //orderId: orderId,
    //pixCode: pixCode,
    //pixQrCodeBase64: pixQrCodeBase64,
    //paymentId: paymentId,
    //);
    return PixPaymentData(
      orderId: orderId,
      pixCode: pixCode,
      pixQrCodeBase64: pixQrCodeBase64,
      paymentId: paymentId,
    );
  }

  Future<void> updateStatus(String orderId, String status) async {
    await _repository.updateStatus(orderId, status);
  }

  Future<void> savePaymentConfig(MercadoPagoConfig config) async {
    await _configRepository.saveConfig(config);
  }
}
