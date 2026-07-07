import 'package:cangaia_de_jegue/services/neon_admin_service.dart';
import 'package:cangaia_de_jegue/views/login_view.dart';
import 'package:flutter/material.dart';

class AdminSetupView extends StatefulWidget {
  const AdminSetupView({super.key});

  @override
  State<AdminSetupView> createState() => _AdminSetupViewState();
}

class _AdminSetupViewState extends State<AdminSetupView> {
  final _adminService = const NeonAdminService();
  bool _isLoading = false;

  Future<void> _criarTabelas() async {
    setState(() => _isLoading = true);
    debugPrint('[SYNC][UI] Botao criar tabelas acionado');
    try {
      final mensagem = await _adminService.criarTabelas();
      debugPrint('[SYNC][UI] Resultado: $mensagem');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagem)));
    } catch (error) {
      debugPrint('[SYNC][UI] Erro exibido para usuario: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sairDaAreaAdmin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Administrador - Neon'),
        actions: [
          IconButton(
            onPressed: _sairDaAreaAdmin,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Criar tabelas no Neon',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use esta acao para criar ou verificar as tabelas no banco Neon configurado.',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _isLoading ? null : _criarTabelas,
                icon: const Icon(Icons.cloud_upload),
                label: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Criar tabelas no Neon'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
