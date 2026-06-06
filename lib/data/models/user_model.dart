class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });
  bool get isMaster => role == 'master';
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      role: (map['role'] ?? 'user').toString(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
