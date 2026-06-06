import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    final currentUser = currentUserAsync.value;
    if (currentUser == null || !currentUser.isMaster) {
      return const Scaffold(body: Center(child: Text('Acesso negado.')));
    }
    final usersAsync = ref.watch(allUsersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Usuários')),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Nenhum usuário cadastrado.'));
          }
          final currentUser = currentUserAsync.value;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isMaster = user.isMaster;
              final isCurrentUser = currentUser?.uid == user.uid;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isMaster
                      ? Colors.amber
                      : Colors.blueGrey.shade100,
                  child: Icon(
                    isMaster ? Icons.star : Icons.person_outline,
                    color: isMaster ? Colors.white : Colors.blueGrey,
                  ),
                ),
                title: Text(user.name.isEmpty ? '(sem nome)' : user.name),
                subtitle: Text(user.email),
                trailing: Chip(
                  label: Text(isMaster ? 'Master' : 'Usuario'),
                  backgroundColor: isMaster
                      ? Colors.amber.shade100
                      : Colors.grey.shade200,
                ),
                onTap: () => _changeRole(
                  context: context,
                  ref: ref,
                  targetUser: user,
                  isCurrentUser: isCurrentUser,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Erro ao carregar usuarios.')),
      ),
    );
  }

  Future<void> _changeRole({
    required BuildContext context,
    required WidgetRef ref,
    required UserModel targetUser,
    required bool isCurrentUser,
  }) async {
    final repository = ref.read(userRepositoryProvider);
    final currentRole = targetUser.role;
    final newRole = currentRole == 'master' ? 'user' : 'master';
    if (currentRole == 'master' && isCurrentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não pode rebaixar seu próprio usuário.'),
        ),
      );
      return;
    }
    if (currentRole == 'master') {
      final isLastMaster = await repository.isLastMaster(targetUser.uid);
      if (isLastMaster) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não é permitido remover o último master do app.'),
          ),
        );
        return;
      }
    }
    if (!context.mounted) {
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alterar perfil'),
        content: Text(
          'Alterar "${targetUser.name}" para ${newRole == "master" ? "Master" : "Usuario"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    await repository.updateRole(targetUser.uid, newRole);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado com sucesso.')),
    );
  }
}

// allUsersProvider movido para presentation/providers/user_provider.dart
