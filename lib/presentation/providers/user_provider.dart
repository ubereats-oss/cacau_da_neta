import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import 'auth_provider.dart';

final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(null);
      }
      return ref.read(userRepositoryProvider).watchUser(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});
// Stream de todos os usuários — usado pelo painel admin
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final currentUser = ref.watch(currentUserProfileProvider).value;
  if (currentUser == null || !currentUser.isMaster) return Stream.value([]);
  return ref.read(userRepositoryProvider).watchAllUsers();
});
