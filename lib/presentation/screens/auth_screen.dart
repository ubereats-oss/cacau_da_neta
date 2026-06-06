import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _passwordVisible = false;
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
    });
    try {
      final authService = ref.read(authServiceProvider);
      if (_isLogin) {
        await authService.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text.trim(),
        );
      } else {
        await authService.registerWithEmail(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text.trim(),
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapAuthError(error))));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível concluir a operação.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe seu e-mail para recuperar a senha.'),
        ),
      );
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail de recuperacao enviado.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mapAuthError(error))));
    }
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'email-already-in-use':
        return 'Este e-mail ja esta em uso.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'E-mail ou senha inválidos.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      default:
        return error.message ?? 'Falha na autenticação.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Entrar' : 'Criar conta';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          'assets/images/Logomarca com nome.jpeg',
                          height: 80,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isLogin
                              ? 'Entre para comprar e acompanhar sua conta.'
                              : 'Crie sua conta para comprar na Cacau da Neta.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe seu nome.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Informe seu e-mail.';
                            }
                            if (!text.contains('@') || !text.contains('.')) {
                              return 'Informe um e-mail válido.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_passwordVisible,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Informe sua senha.';
                            }
                            if (text.length < 6) {
                              return 'A senha deve ter pelo menos 6 caracteres.';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            if (!_isLoading) {
                              _submit();
                            }
                          },
                        ),
                        if (_isLogin) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              child: const Text('Esqueci minha senha'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(title),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                          child: Text(
                            _isLogin
                                ? 'Ainda não tem conta? Criar conta'
                                : 'Já tem conta? Entrar',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
