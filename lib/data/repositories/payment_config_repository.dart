import 'package:cloud_firestore/cloud_firestore.dart';
class MercadoPagoConfig {
  const MercadoPagoConfig({
    required this.accessToken,
    required this.sandbox,
    required this.isConfigured,
  });
  final String accessToken;
  final bool sandbox;
  final bool isConfigured;
  factory MercadoPagoConfig.empty() {
    return const MercadoPagoConfig(
      accessToken: '',
      sandbox: true,
      isConfigured: false,
    );
  }
  factory MercadoPagoConfig.fromMap(Map<String, dynamic> map) {
    return MercadoPagoConfig(
      accessToken: (map['accessToken'] ?? '').toString(),
      sandbox: map['sandbox'] == true,
      isConfigured: (map['accessToken'] ?? '').toString().isNotEmpty,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'accessToken': accessToken,
      'sandbox': sandbox,
    };
  }
}
class PaymentConfigRepository {
  PaymentConfigRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  DocumentReference<Map<String, dynamic>> get _configRef =>
      _db.collection('settings').doc('mercadopago');
  Future<MercadoPagoConfig> getConfig() async {
    final doc = await _configRef.get();
    if (!doc.exists || doc.data() == null) {
      return MercadoPagoConfig.empty();
    }
    return MercadoPagoConfig.fromMap(doc.data()!);
  }
  Stream<MercadoPagoConfig> watchConfig() {
    return _configRef.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return MercadoPagoConfig.empty();
      }
      return MercadoPagoConfig.fromMap(doc.data()!);
    });
  }
  Future<void> saveConfig(MercadoPagoConfig config) async {
    await _configRef.set({
      ...config.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
