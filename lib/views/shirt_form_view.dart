import 'package:cangaia_de_jegue/controllers/shirts_controller.dart';
import 'package:cangaia_de_jegue/models/shirt_order_model.dart';
import 'package:cangaia_de_jegue/models/shirt_size_model.dart';
import 'package:flutter/material.dart';

class ShirtFormView extends StatefulWidget {
  const ShirtFormView({super.key});

  @override
  State<ShirtFormView> createState() => _ShirtFormViewState();
}

class _ShirtFormViewState extends State<ShirtFormView> {
  final _controller = ShirtsController();
  final _formKey = GlobalKey<FormState>();
  final List<_ShirtEntry> _entries = [
    _ShirtEntry(size: ShirtSizeModel.validSizes.first, quantity: 1),
  ];
  bool _isSaving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final validEntries = _entries.where((e) => e.quantity > 0).toList();
    if (validEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos um tamanho.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final nowIso = DateTime.now().toIso8601String();
      final orders = validEntries
          .map(
            (e) => ShirtOrderModel(
              size: e.size,
              quantity: e.quantity,
              createdAt: nowIso,
            ),
          )
          .toList();

      await _controller.saveOrders(orders);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camisas cadastradas com sucesso.')),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar camisas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tamanhos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _entries.add(
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
              const SizedBox(height: 8),
              ...List.generate(_entries.length, (index) {
                final entry = _entries[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
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
                              () => _entries[index] = _ShirtEntry(
                                size: value,
                                quantity: entry.quantity,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          initialValue: entry.quantity.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantidade',
                            isDense: true,
                          ),
                          onChanged: (value) {
                            final qty = int.tryParse(value) ?? 1;
                            setState(
                              () => _entries[index] = _ShirtEntry(
                                size: entry.size,
                                quantity: qty,
                              ),
                            );
                          },
                          validator: (value) {
                            final qty = int.tryParse(value ?? '');
                            if (qty == null || qty <= 0) return 'Invalido';
                            return null;
                          },
                        ),
                      ),
                      if (_entries.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.red,
                          onPressed: () =>
                              setState(() => _entries.removeAt(index)),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ),
              const SizedBox(height: 32),
            ],
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
