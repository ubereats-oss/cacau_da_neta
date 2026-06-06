import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import 'admin_import_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_users_screen.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProfileProvider).value;
    if (currentUser == null || !currentUser.isMaster) {
      return const Scaffold(body: Center(child: Text('Acesso negado.')));
    }
    final items = [
      _PanelItem(
        icon: Icons.inventory_2_outlined,
        label: 'Produtos',
        screen: const AdminProductsScreen(),
      ),
      _PanelItem(
        icon: Icons.receipt_long_outlined,
        label: 'Pedidos',
        screen: const AdminOrdersScreen(),
      ),
      _PanelItem(
        icon: Icons.people_outline,
        label: 'Usuários',
        screen: const AdminUsersScreen(),
      ),
      _PanelItem(
        icon: Icons.upload_file_outlined,
        label: 'Importar\nPlanilha',
        screen: const AdminImportScreen(),
      ),
      _PanelItem(
        icon: Icons.payment_outlined,
        label: 'Configurações\nde Pagamento',
        screen: const AdminSettingsScreen(),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Painel Admin')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: items
            .map(
              (item) => Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => item.screen),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PanelItem {
  const _PanelItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
  final IconData icon;
  final String label;
  final Widget screen;
}
