import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../auth_screen.dart';
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Conta'),
      ),
      body: currentUser.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Erro ao carregar conta.')),
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Você não está logado.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuthScreen(),
                        ),
                      );
                    },
                    child: const Text('Entrar'),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _InfoTile(
                icon: Icons.person_outline,
                label: 'Nome',
                value: user.name.isEmpty ? '—' : user.name,
              ),
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.email_outlined,
                label: 'E-mail',
                value: user.email.isEmpty ? '—' : user.email,
              ),
              const SizedBox(height: 12),
              _InfoTile(
                icon: Icons.verified_user_outlined,
                label: 'Perfil',
                value: user.isMaster ? 'Administrador' : 'Cliente',
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Sair'),
                      content: const Text('Deseja sair da sua conta?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar'),
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
                  if (confirm != true) return;
                  await ref.read(authServiceProvider).signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
              ),
            ],
          );
        },
      ),
    );
  }
}
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
