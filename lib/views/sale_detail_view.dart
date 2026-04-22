import 'package:cangaia_de_jegue/controllers/sales_controller.dart';
import 'package:cangaia_de_jegue/models/payment_receipt_model.dart';
import 'package:cangaia_de_jegue/models/ticket_sale_model.dart';
import 'package:flutter/material.dart';

class SaleDetailView extends StatefulWidget {
  const SaleDetailView({super.key, required this.sale});

  final TicketSaleModel sale;

  @override
  State<SaleDetailView> createState() => _SaleDetailViewState();
}

class _SaleDetailViewState extends State<SaleDetailView> {
  static const double _ticketUnitPrice = 180.0;
  final _formKey = GlobalKey<FormState>();
  final _controller = SalesController();
  late final TextEditingController _buyerController;
  late final TextEditingController _quantityController;
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  late final Future<List<PaymentReceiptModel>> _receiptsFuture;

  @override
  void initState() {
    super.initState();
    _buyerController = TextEditingController(text: widget.sale.buyerName);
    _quantityController =
        TextEditingController(text: widget.sale.ticketQuantity.toString());
    _receiptsFuture = widget.sale.id == null
        ? Future.value([])
        : _controller.getReceiptsBySale(widget.sale.id!);
  }

  @override
  void dispose() {
    _buyerController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  int get _currentQuantity => int.tryParse(_quantityController.text) ?? 0;
  double get _calculatedTotal => _currentQuantity * _ticketUnitPrice;

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditMode) return;

    if (_calculatedTotal < widget.sale.receivedAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantidade invalida: total nao pode ficar menor que o valor ja recebido.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _controller.updateSale(
        originalSale: widget.sale,
        buyerName: widget.sale.buyerName,
        ticketQuantity: int.parse(_quantityController.text),
        totalAmount: _calculatedTotal,
        installments: widget.sale.installments,
        receivedNow: 0,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteSale() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir venda'),
          content: const Text('Deseja realmente excluir este registro?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm != true || widget.sale.id == null) return;

    setState(() => _isDeleting = true);
    await _controller.deleteSale(widget.sale.id!);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _cancelEdit() {
    setState(() {
      _quantityController.text = widget.sale.ticketQuantity.toString();
      _isEditMode = false;
    });
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da venda')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status: ${widget.sale.paymentStatus.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Valor recebido: R\$ ${widget.sale.receivedAmount.toStringAsFixed(2)}'),
              Text('Valor pendente: R\$ ${widget.sale.remainingAmount.toStringAsFixed(2)}'),
              Text('Data do ultimo recebimento: ${_formatDate(widget.sale.receivedAt)}'),
              const SizedBox(height: 16),
              const Text(
                'Historico de recebimentos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<PaymentReceiptModel>>(
                future: _receiptsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final receipts = snapshot.data!;
                  if (receipts.isEmpty) {
                    return const Text('Nenhum recebimento registrado.');
                  }

                  return Column(
                    children: receipts
                        .map(
                          (receipt) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.payments_outlined),
                            title: Text(
                              'R\$ ${receipt.amount.toStringAsFixed(2)}',
                            ),
                            subtitle: Text(_formatDate(receipt.receivedAt)),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _buyerController,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Nome do comprador'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _quantityController,
                enabled: _isEditMode,
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
                decoration: const InputDecoration(labelText: 'Valor por ingresso (fixo)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: ValueKey<String>('detail_total_${_calculatedTotal.toStringAsFixed(2)}'),
                enabled: false,
                initialValue: 'R\$ ${_calculatedTotal.toStringAsFixed(2)}',
                decoration: const InputDecoration(labelText: 'Valor total (calculado)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                enabled: false,
                initialValue: '${widget.sale.installments}x',
                decoration: const InputDecoration(labelText: 'Parcelamento'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (_isEditMode) {
                                _saveChanges();
                              } else {
                                setState(() => _isEditMode = true);
                              }
                            },
                      child: Text(_isEditMode ? 'Salvar alteracoes' : 'Editar'),
                    ),
                  ),
                  if (_isEditMode) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _cancelEdit,
                        child: const Text('Cancelar edicao'),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isDeleting ? null : _deleteSale,
                  child: _isDeleting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Excluir venda'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
