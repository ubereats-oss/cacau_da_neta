import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import 'account/account_screen.dart';
import 'admin/admin_panel_screen.dart';
import 'auth_screen.dart';
import 'cart/cart_screen.dart';
import 'orders/my_orders_screen.dart';
import 'products/product_list_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = ref.watch(currentUserProfileProvider);
    final cartCount = ref.watch(cartProvider).totalItems;
    final isAuthenticated = authState.when(
      data: (user) => user != null,
      loading: () => false,
      error: (_, _) => false,
    );
    final isMaster = currentUser.when(
      data: (user) => user?.isMaster ?? false,
      loading: () => false,
      error: (_, _) => false,
    );
    final userName = currentUser.when(
      data: (user) => user?.name ?? '',
      loading: () => '',
      error: (_, _) => '',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cacau da Neta'),
        actions: [
          Badge(
            label: Text('$cartCount'),
            isLabelVisible: cartCount > 0,
            child: IconButton(
              tooltip: 'Carrinho',
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
          ),
          if (isMaster)
            IconButton(
              tooltip: 'Painel Admin',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                );
              },
            ),
          IconButton(
            tooltip: isAuthenticated ? 'Sair' : 'Entrar',
            icon: Icon(isAuthenticated ? Icons.logout : Icons.login),
            onPressed: () async {
              if (!isAuthenticated) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
                return;
              }
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Image.asset('assets/images/logomarca.png', height: 100),
              const SizedBox(height: 12),
              const Text(
                'Cacau da Neta',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                isAuthenticated && userName.isNotEmpty
                    ? 'Olá, $userName!'
                    : 'Explore os produtos. O login será exigido ao comprar.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _MenuCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Ver\nProdutos',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductListScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.shopping_cart_outlined,
                      label: cartCount > 0
                          ? 'Carrinho\n($cartCount)'
                          : 'Carrinho',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: isAuthenticated
                          ? Icons.person_outline
                          : Icons.login,
                      label: isAuthenticated
                          ? 'Minha\nConta'
                          : 'Entrar /\nCriar conta',
                      onTap: () {
                        if (!isAuthenticated) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AuthScreen(),
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountScreen(),
                          ),
                        );
                      },
                    ),
                    if (isAuthenticated)
                      _MenuCard(
                        icon: Icons.receipt_long_outlined,
                        label: 'Meus\nPedidos',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyOrdersScreen(),
                            ),
                          );
                        },
                      ),
                    if (isMaster)
                      _MenuCard(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Administração',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminPanelScreen(),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
