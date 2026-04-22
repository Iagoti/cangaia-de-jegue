import 'package:cangaia_de_jegue/controllers/auth_controller.dart';
import 'package:cangaia_de_jegue/database/app_database.dart';
import 'package:cangaia_de_jegue/views/admin_setup_view.dart';
import 'package:cangaia_de_jegue/views/dashboard_view.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const String _adminUsuario = 'iago';
  static const String _adminSenha = '1234';
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = AuthController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.database;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.toLowerCase() == _adminUsuario && password == _adminSenha) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminSetupView()),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = await _authController.login(
      username: username,
      password: password,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario ou senha invalidos.')),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardView(loggedUser: user.username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login - Cangaia de Jegue')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F1AB6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '9a Cavalgada Cangaia de Jegue',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Acesso de vendedores',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'Usuario'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe o usuario' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Senha'),
                        obscureText: true,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe a senha' : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Entrar'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Usuarios padrao: Elana e William\nSenha: cangaiadejegue',
                        textAlign: TextAlign.center,
                      ),
                    ],
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
