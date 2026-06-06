import 'package:cloud_firestore/cloud_firestore.dart';
class OrderItemModel {
  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.quantity,
    required this.unitPrice,
  });
  final String productId;
  final String productName;
  final String productImageUrl;
  final int quantity;
  final double unitPrice;
  double get subtotal => unitPrice * quantity;
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: (map['productId'] ?? '').toString(),
      productName: (map['productName'] ?? '').toString(),
      productImageUrl: (map['productImageUrl'] ?? '').toString(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: _parseDouble(map['unitPrice']),
    );
  }
  static double _parseDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return 0;
  }
}
enum OrderStatus {
  awaitingPayment('awaiting_payment', 'Aguardando pagamento'),
  pending('pending', 'Pendente'),
  confirmed('confirmed', 'Confirmado'),
  shipped('shipped', 'Enviado'),
  delivered('delivered', 'Entregue'),
  cancelled('cancelled', 'Cancelado');
  const OrderStatus(this.value, this.label);
  final String value;
  final String label;
  static OrderStatus fromValue(String value) {
    return OrderStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}
class OrderModel {
  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.total,
    required this.status,
    this.pixCode,
    this.pixQrCodeBase64,
    this.paymentId,
    this.createdAt,
    this.updatedAt,
  });
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final List<OrderItemModel> items;
  final double total;
  final String status;
  // Dados do pagamento Pix
  final String? pixCode;
  final String? pixQrCodeBase64;
  final String? paymentId;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  OrderStatus get orderStatus => OrderStatus.fromValue(status);
  int get totalItems => items.fold(0, (acc, item) => acc + item.quantity);
  bool get isPaid =>
      orderStatus != OrderStatus.awaitingPayment &&
      orderStatus != OrderStatus.cancelled;
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'items': items.map((i) => i.toMap()).toList(),
      'total': total,
      'status': status,
      'pixCode': pixCode,
      'pixQrCodeBase64': pixQrCodeBase64,
      'paymentId': paymentId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: id,
      customerId: (map['customerId'] ?? '').toString(),
      customerName: (map['customerName'] ?? '').toString(),
      customerEmail: (map['customerEmail'] ?? '').toString(),
      items: rawItems
          .map((i) => OrderItemModel.fromMap(i as Map<String, dynamic>))
          .toList(),
      total: _parseDouble(map['total']),
      status: (map['status'] ?? 'awaiting_payment').toString(),
      pixCode: map['pixCode'] as String?,
      pixQrCodeBase64: map['pixQrCodeBase64'] as String?,
      paymentId: map['paymentId'] as String?,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }
  static double _parseDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return 0;
  }
}
