import 'package:cangaia_de_jegue/controllers/sales_controller.dart';
import 'package:cangaia_de_jegue/views/login_view.dart';
import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.loggedUser});

  final String loggedUser;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const double _ticketUnitPrice = 180.0;
  final _formKey = GlobalKey<FormState>();
  final _buyerController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _controller = SalesController();
  int _installments = 1;
  bool _isSaving = false;

  int get _currentQuantity => int.tryParse(_quantityController.text) ?? 0;
  double get _currentTotal => _currentQuantity * _ticketUnitPrice;

  @override
  void dispose() {
    _buyerController.dispose();
    _buyerPhoneController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _controller.registerSale(
        buyerName: _buyerController.text.trim(),
        buyerPhone: _buyerPhoneController.text.trim(),
        ticketQuantity: int.parse(_quantityController.text),
        totalAmount: _currentTotal,
        installments: _installments,
        sellerUsername: widget.loggedUser,
      );

      _buyerController.clear();
      _buyerPhoneController.clear();
      _quantityController.text = '1';
      _installments = 1;
      setState(() {});

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de vendas'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vendedor logado: ${widget.loggedUser}'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _buyerController,
                        decoration: const InputDecoration(labelText: 'Nome do comprador'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe o comprador' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _buyerPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Numero de telefone'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Informe o telefone' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Quantidade de ingressos'),
                        validator: (value) {
                          final quantity = int.tryParse(value ?? '');
                          if (quantity == null || quantity <= 0) return 'Quantidade invalida';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        enabled: false,
                        initialValue: 'R\$ ${_ticketUnitPrice.toStringAsFixed(2)}',
                        decoration: const InputDecoration(
                          labelText: 'Valor por ingresso (fixo)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        enabled: false,
                        initialValue: 'R\$ ${_currentTotal.toStringAsFixed(2)}',
                        key: ValueKey<String>('total_${_currentTotal.toStringAsFixed(2)}'),
                        decoration: const InputDecoration(
                          labelText: 'Valor total (calculado)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        initialValue: _installments,
                        decoration: const InputDecoration(labelText: 'Parcelamento'),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1x')),
                          DropdownMenuItem(value: 2, child: Text('2x')),
                          DropdownMenuItem(value: 3, child: Text('3x')),
                        ],
                        onChanged: (value) => setState(() => _installments = value ?? 1),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _saveSale,
                          child: const Text('Registrar venda'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
