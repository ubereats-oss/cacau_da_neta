import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: FirebaseAuth.instance,
    userRepository: ref.read(userRepositoryProvider),
  );
});
class AuthService {
  AuthService({
    required FirebaseAuth auth,
    required UserRepository userRepository,
  })  : _auth = auth,
        _userRepository = userRepository;
  final FirebaseAuth _auth;
  final UserRepository _userRepository;
  User? get currentUser => _auth.currentUser;
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _ensureUserDocument(credential.user);
  }
  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    // 1. Cria a conta no Firebase Auth PRIMEIRO (agora o usuário está autenticado)
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'Não foi possível criar o usuário.',
      );
    }
    await user.updateDisplayName(name.trim());
    // 2. Agora autenticado, consulta o Firestore com segurança
    final usersCount = await _userRepository.getUsersCount();
    final role = usersCount == 0 ? 'master' : 'user';
    // 3. Salva o documento do usuário
    await _userRepository.createUser(
      UserModel(
        uid: user.uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
      ),
    );
  }
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
  Future<void> signOut() async {
    await _auth.signOut();
  }
  Future<void> _ensureUserDocument(User? user) async {
    if (user == null) {
      return;
    }
    final existingUser = await _userRepository.getUser(user.uid);
    if (existingUser != null) {
      return;
    }
    final usersCount = await _userRepository.getUsersCount();
    final role = usersCount == 0 ? 'master' : 'user';
    await _userRepository.createUser(
      UserModel(
        uid: user.uid,
        name: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : user.email?.split('@').first ?? 'Usuário',
        email: user.email ?? '',
        role: role,
      ),
    );
  }
}
