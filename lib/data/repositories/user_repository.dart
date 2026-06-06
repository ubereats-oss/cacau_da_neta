import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
class UserRepository {
  UserRepository({
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');
  Future<void> createUser(UserModel user) async {
    await _usersRef.doc(user.uid).set(user.toMap());
  }
  Future<UserModel?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return UserModel.fromMap(uid, doc.data()!);
  }
  Stream<UserModel?> watchUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return null;
      }
      return UserModel.fromMap(uid, snap.data()!);
    });
  }
  Stream<List<UserModel>> watchAllUsers() {
    return _usersRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
  Future<List<UserModel>> listAllUsers() async {
    final snapshot = await _usersRef.orderBy('name').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.id, doc.data()))
        .toList();
  }
  Future<void> updateRole(String uid, String role) async {
    await _usersRef.doc(uid).update({'role': role});
  }
  Future<int> getUsersCount() async {
    final snapshot = await _usersRef.count().get();
    return snapshot.count ?? 0;
  }
  Future<int> getMasterCount() async {
    final snapshot = await _usersRef.where('role', isEqualTo: 'master').count().get();
    return snapshot.count ?? 0;
  }
  Future<bool> isLastMaster(String uid) async {
    final user = await getUser(uid);
    if (user == null || !user.isMaster) {
      return false;
    }
    final masterCount = await getMasterCount();
    return masterCount <= 1;
  }
}
