import 'package:cangaia_de_jegue/controllers/sales_controller.dart';
import 'package:cangaia_de_jegue/controllers/shirts_controller.dart';
import 'package:cangaia_de_jegue/models/shirt_size_model.dart';
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
  final _quantityController = TextEditingController();
  final _receivedAmountController = TextEditingController();
  final _controller = SalesController();
  final _shirtsController = ShirtsController();
  int _installments = 1;
  bool _isSaving = false;
  bool _markAsPaid = false;
  final List<_ShirtEntry> _shirtEntries = [];
  Map<String, int> _remainingStock = {};

  int get _currentQuantity =>
      _shirtEntries.fold(0, (sum, e) => sum + e.quantity);
  double get _currentTotal => _currentQuantity * _ticketUnitPrice;

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  Future<void> _loadStock() async {
    final summaries = await _shirtsController.getShirtSummary();
    if (!mounted) return;
    setState(() {
      _remainingStock = {for (final s in summaries) s.size: s.remaining};
    });
  }

  @override
  void dispose() {
    _buyerController.dispose();
    _buyerPhoneController.dispose();
    _quantityController.dispose();
    _receivedAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveSale() async {
    if (_currentQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos um tamanho de camisa.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    // Valida estoque antes de salvar
    final summaries = await _shirtsController.getShirtSummary();
    final remaining = {for (final s in summaries) s.size: s.remaining};

    // Agrupa as entradas por tamanho para checar o total pedido vs disponível
    final requestedBySize = <String, int>{};
    for (final entry in _shirtEntries) {
      requestedBySize[entry.size] =
          (requestedBySize[entry.size] ?? 0) + entry.quantity;
    }

    final stockErrors = <String>[];
    for (final entry in requestedBySize.entries) {
      final available = remaining[entry.key] ?? 0;
      if (entry.value > available) {
        stockErrors.add(
          '${entry.key}: solicitado ${entry.value}, disponivel $available',
        );
      }
    }

    if (stockErrors.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sem estoque suficiente:\n${stockErrors.join('\n')}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final receivedAmount =
          double.tryParse(_receivedAmountController.text.trim().replaceAll(',', '.')) ?? 0;

      final shirtSizes = _shirtEntries
          .where((e) => e.quantity > 0)
          .map((e) => ShirtSizeModel(saleId: 0, size: e.size, quantity: e.quantity))
          .toList();

      await _controller.registerSale(
        buyerName: _buyerController.text.trim(),
        buyerPhone: _buyerPhoneController.text.trim(),
        ticketQuantity: _currentQuantity,
        totalAmount: _currentTotal,
        installments: _installments,
        sellerUsername: widget.loggedUser,
        receivedAmount: receivedAmount,
        markAsPaid: _markAsPaid,
        shirtSizes: shirtSizes,
      );

      _buyerController.clear();
      _buyerPhoneController.clear();
      _receivedAmountController.clear();
      _installments = 1;
      _markAsPaid = false;
      _shirtEntries.clear();
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
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
                        enabled: false,
                        key: ValueKey<int>(_currentQuantity),
                        initialValue: '$_currentQuantity',
                        decoration: InputDecoration(
                          labelText: 'Quantidade de camisas',
                          helperText: _currentQuantity == 0
                              ? 'Adicione os tamanhos abaixo'
                              : null,
                        ),
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
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _receivedAmountController,
                        enabled: !_markAsPaid,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Valor recebido (opcional)',
                          prefixText: 'R\$ ',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
                          if (parsed == null || parsed < 0) return 'Valor invalido';
                          if (parsed > _currentTotal) return 'Nao pode ultrapassar o valor total';
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        value: _markAsPaid,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Marcar como pago'),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setState(() {
                            _markAsPaid = value ?? false;
                            if (_markAsPaid) _receivedAmountController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tamanhos de camisa',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _shirtEntries.add(
                                  _ShirtEntry(
                                    size: ShirtSizeModel.validSizes.first,
                                    quantity: 1,
                                  ),
                                );
                              });
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Adicionar'),
                          ),
                        ],
                      ),
                      if (_shirtEntries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Nenhum tamanho adicionado',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...List.generate(_shirtEntries.length, (index) {
                          final entry = _shirtEntries[index];
                          final available =
                              _remainingStock[entry.size] ?? 0;
                          final exceedsStock = entry.quantity > available;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButtonFormField<String>(
                                        value: entry.size,
                                        decoration: const InputDecoration(
                                          labelText: 'Tamanho',
                                          isDense: true,
                                        ),
                                        items: ShirtSizeModel.validSizes
                                            .map(
                                              (s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(s),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(
                                            () => _shirtEntries[index] =
                                                _ShirtEntry(
                                                  size: value,
                                                  quantity: entry.quantity,
                                                ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        initialValue: entry.quantity.toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Qtd',
                                          isDense: true,
                                          errorText: exceedsStock
                                              ? 'Max: $available'
                                              : null,
                                        ),
                                        onChanged: (value) {
                                          final qty =
                                              int.tryParse(value) ?? 1;
                                          setState(
                                            () => _shirtEntries[index] =
                                                _ShirtEntry(
                                                  size: entry.size,
                                                  quantity: qty,
                                                ),
                                          );
                                        },
                                        validator: (value) {
                                          final qty =
                                              int.tryParse(value ?? '');
                                          if (qty == null || qty <= 0) {
                                            return 'Invalido';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      color: Colors.red,
                                      onPressed: () {
                                        setState(
                                          () =>
                                              _shirtEntries.removeAt(index),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                if (_remainingStock.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4,
                                      top: 2,
                                    ),
                                    child: Text(
                                      'Disponivel: $available',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: exceedsStock
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 8),
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
      ),
    );
  }
}

class _ShirtEntry {
  _ShirtEntry({required this.size, required this.quantity});
  final String size;
  final int quantity;
}
