import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _db.collection('orders');
  Future<String> createOrder(OrderModel order) async {
    final now = FieldValue.serverTimestamp();
    final doc = await _ordersRef.add({
      ...order.toMap(),
      'createdAt': now,
      'updatedAt': now,
    });
    return doc.id;
  }
  Future<void> updatePaymentData({
    required String orderId,
    required String pixCode,
    required String pixQrCodeBase64,
    required String paymentId,
  }) async {
    await _ordersRef.doc(orderId).update({
      'pixCode': pixCode,
      'pixQrCodeBase64': pixQrCodeBase64,
      'paymentId': paymentId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  Stream<OrderModel?> watchOrder(String orderId) {
    return _ordersRef.doc(orderId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return OrderModel.fromMap(snap.id, snap.data()!);
    });
  }
  Stream<List<OrderModel>> watchCustomerOrders(String customerId) {
    return _ordersRef
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapCollection);
  }
  Stream<List<OrderModel>> watchAllOrders() {
    return _ordersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapCollection);
  }
  Stream<List<OrderModel>> watchOrdersByStatus(String status) {
    return _ordersRef
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapCollection);
  }
  Future<void> updateStatus(String orderId, String status) async {
    await _ordersRef.doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  List<OrderModel> _mapCollection(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
        .toList();
  }
}
