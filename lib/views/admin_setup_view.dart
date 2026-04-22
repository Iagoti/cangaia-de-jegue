import 'package:cangaia_de_jegue/services/supabase_admin_service.dart';
import 'package:cangaia_de_jegue/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminSetupView extends StatefulWidget {
  const AdminSetupView({super.key});

  @override
  State<AdminSetupView> createState() => _AdminSetupViewState();
}

class _AdminSetupViewState extends State<AdminSetupView> {
  final _serviceRoleController = TextEditingController();
  final _adminService = const SupabaseAdminService();
  bool _isLoading = false;
  bool _ocultarChave = true;

  @override
  void dispose() {
    _serviceRoleController.dispose();
    super.dispose();
  }

  Future<void> _criarTabelas() async {
    final chave = _serviceRoleController.text.trim();
    if (chave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe a Service Role Key do Supabase.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('[SYNC][UI] Botao criar tabelas acionado');
    try {
      final mensagem = await _adminService.criarTabelas(serviceRoleKey: chave);
      debugPrint('[SYNC][UI] Resultado: $mensagem');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem)),
      );
    } catch (error) {
      debugPrint('[SYNC][UI] Erro exibido para usuario: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
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

  Future<void> _colarChave() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final texto = data?.text?.trim() ?? '';
    if (texto.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Area de transferencia vazia.')),
      );
      return;
    }

    setState(() {
      _serviceRoleController.text = texto;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Administrador - Supabase'),
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
                'Criar tabelas no Supabase',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Informe a Service Role Key para executar a criacao das tabelas.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serviceRoleController,
                obscureText: _ocultarChave,
                maxLines: 1,
                scrollPadding: const EdgeInsets.only(bottom: 120),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Service Role Key',
                  suffixIcon: IconButton(
                    tooltip: _ocultarChave ? 'Mostrar chave' : 'Ocultar chave',
                    onPressed: () {
                      setState(() => _ocultarChave = !_ocultarChave);
                    },
                    icon: Icon(
                      _ocultarChave ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _colarChave,
                icon: const Icon(Icons.content_paste),
                label: const Text('Colar da area de transferencia'),
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
                    : const Text('Criar tabelas no Supabase'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
