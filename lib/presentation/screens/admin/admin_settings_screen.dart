import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/payment_config_repository.dart';
import '../../providers/order_provider.dart';
import '../../providers/user_provider.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});
  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _sandbox = true;
  bool _isLoading = false;
  bool _tokenVisible = false;
  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final repo = ref.read(paymentConfigRepositoryProvider);
    final config = await repo.getConfig();
    if (!mounted) return;
    setState(() {
      _tokenController.text = config.accessToken;
      _sandbox = config.sandbox;
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(orderActionsProvider)
          .savePaymentConfig(
            MercadoPagoConfig(
              accessToken: _tokenController.text.trim(),
              sandbox: _sandbox,
              isConfigured: true,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações salvas com sucesso.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider).value;
    if (currentUser == null || !currentUser.isMaster) {
      return const Scaffold(body: Center(child: Text('Acesso negado.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações de Pagamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mercado Pago
              const Text(
                'Mercado Pago — Pix',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Insira as credenciais da sua conta Mercado Pago. '
                'O Access Token é encontrado em Sua conta → '
                'Credenciais → Produção.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.grey600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Access Token
              TextFormField(
                controller: _tokenController,
                obscureText: !_tokenVisible,
                decoration: InputDecoration(
                  labelText: 'Access Token',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _tokenVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _tokenVisible = !_tokenVisible),
                  ),
                  hintText: 'APP_USR-...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o Access Token.';
                  }
                  if (!value.trim().startsWith('APP_USR-') &&
                      !value.trim().startsWith('TEST-')) {
                    return 'Token inválido. Deve começar com APP_USR- ou TEST-';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Modo Sandbox
              SwitchListTile(
                value: _sandbox,
                onChanged: (val) => setState(() => _sandbox = val),
                title: const Text('Modo de teste (Sandbox)'),
                subtitle: const Text(
                  'Ative para testar pagamentos sem cobrar de verdade. '
                  'Desative ao ir para produção.',
                  style: TextStyle(fontSize: 12),
                ),
                activeThumbColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              if (_sandbox) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Modo teste ativo — nenhum pagamento real será processado.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isLoading ? null : _salvar,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isLoading ? 'Salvando...' : 'Salvar configurações',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
