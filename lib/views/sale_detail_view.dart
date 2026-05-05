import 'package:cangaia_de_jegue/controllers/sales_controller.dart';
import 'package:cangaia_de_jegue/controllers/shirts_controller.dart';
import 'package:cangaia_de_jegue/models/payment_receipt_model.dart';
import 'package:cangaia_de_jegue/models/shirt_size_model.dart';
import 'package:cangaia_de_jegue/models/ticket_sale_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SaleDetailView extends StatefulWidget {
  const SaleDetailView({super.key, required this.sale});

  final TicketSaleModel sale;

  @override
  State<SaleDetailView> createState() => _SaleDetailViewState();
}

class _SaleDetailViewState extends State<SaleDetailView> {
  static const double _ticketUnitPrice = 180.0;
  static const List<String> _paymentMethods = ['PIX', 'dinheiro', 'cartao'];
  final _formKey = GlobalKey<FormState>();
  final _controller = SalesController();
  final _shirtsController = ShirtsController();
  late TicketSaleModel _sale;
  late final TextEditingController _buyerController;
  late final TextEditingController _buyerPhoneController;
  late final TextEditingController _quantityController;
  late int _installments;
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isDeliveringShirt = false;
  late Future<List<PaymentReceiptModel>> _receiptsFuture;
  late Future<List<ShirtSizeModel>> _shirtSizesFuture;
  List<_ShirtEntry> _editShirtEntries = [];
  Map<String, int> _remainingStock = {};

  @override
  void initState() {
    super.initState();
    _sale = widget.sale;
    _buyerController = TextEditingController(text: _sale.buyerName);
    _buyerPhoneController = TextEditingController(text: _sale.buyerPhone);
    _quantityController = TextEditingController(
      text: _sale.ticketQuantity.toString(),
    );
    _installments = _sale.installments;
    _receiptsFuture = _sale.id == null
        ? Future.value([])
        : _controller.getReceiptsBySale(_sale.id!);
    _shirtSizesFuture = _sale.id == null
        ? Future.value([])
        : _controller.getShirtSizesBySale(_sale.id!);
  }

  @override
  void dispose() {
    _buyerController.dispose();
    _buyerPhoneController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  int get _currentQuantity => _isEditMode
      ? _editShirtEntries.fold(0, (sum, e) => sum + e.quantity)
      : _sale.ticketQuantity;
  double get _calculatedTotal => _currentQuantity * _ticketUnitPrice;

  void _refreshReceipts() {
    _receiptsFuture = _sale.id == null
        ? Future.value([])
        : _controller.getReceiptsBySale(_sale.id!);
  }

  Future<void> _saveChanges() async {
    if (!_isEditMode) return;

    if (_currentQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione ao menos um tamanho de camisa.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_calculatedTotal < _sale.receivedAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Quantidade invalida: total nao pode ficar menor que o valor ja recebido.',
          ),
        ),
      );
      return;
    }

    // Valida estoque (já descontando camisas desta venda)
    final requestedBySize = <String, int>{};
    for (final e in _editShirtEntries) {
      requestedBySize[e.size] = (requestedBySize[e.size] ?? 0) + e.quantity;
    }
    final stockErrors = <String>[];
    for (final entry in requestedBySize.entries) {
      final available = _remainingStock[entry.key] ?? 0;
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
          content: Text('Sem estoque suficiente:\n${stockErrors.join('\n')}'),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _controller.updateSale(
        originalSale: _sale,
        buyerName: _buyerController.text.trim(),
        buyerPhone: _buyerPhoneController.text.trim(),
        ticketQuantity: _currentQuantity,
        totalAmount: _calculatedTotal,
        installments: _installments,
        receivedNow: 0,
      );

      final newSizes = _editShirtEntries
          .where((e) => e.quantity > 0)
          .map(
            (e) => ShirtSizeModel(
              saleId: _sale.id!,
              size: e.size,
              quantity: e.quantity,
            ),
          )
          .toList();
      await _controller.updateShirtSizes(_sale.id!, newSizes);

      if (!mounted) return;
      Navigator.of(context).pop('updated');
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _digitsOnly(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _phoneForWhatsApp(String input) {
    var digits = _digitsOnly(input);
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.isEmpty) return '';

    if (digits.startsWith('55') && digits.length >= 12) {
      return digits;
    }
    if (digits.length == 10 || digits.length == 11) {
      return '55$digits';
    }
    if (!digits.startsWith('55')) {
      return '55$digits';
    }
    return digits;
  }

  String get _whatsappMessage {
    return 'Ola ${_sale.buyerName}, tudo bem? Sobre sua compra na Cangaia de Jegue.';
  }

  Future<bool> _launchWhatsAppWithMessage(String message) async {
    final phone = _phoneForWhatsApp(_buyerPhoneController.text);
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefone do comprador nao informado.')),
        );
      }
      return false;
    }
    if (phone.length < 12) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Numero incompleto. Informe DDD + numero (ex.: 11987654321).',
            ),
          ),
        );
      }
      return false;
    }

    final whatsappSend = Uri(
      scheme: 'whatsapp',
      host: 'send',
      queryParameters: {'phone': phone, 'text': message},
    );
    final httpsSend = Uri.https('api.whatsapp.com', '/send', {
      'phone': phone,
      'text': message,
    });

    if (await launchUrl(whatsappSend, mode: LaunchMode.externalApplication)) {
      return true;
    }
    if (!mounted) return false;
    if (await launchUrl(httpsSend, mode: LaunchMode.externalApplication)) {
      return true;
    }
    return false;
  }

  Future<void> _openWhatsApp() async {
    if (!await _launchWhatsAppWithMessage(_whatsappMessage)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel abrir o WhatsApp.')),
      );
    }
  }

  Future<void> _confirmDeliverShirt() async {
    if (_sale.id == null || _sale.shirtDeliveredAt != null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Entregar camisa'),
          content: const Text(
            'Deseja realmente registrar a entrega da camisa? '
            'A data e hora serao salvas e uma mensagem sera enviada ao WhatsApp do comprador.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim, entregar'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeliveringShirt = true);
    try {
      final at = await _controller.markShirtDelivered(_sale);
      if (!mounted) return;
      setState(() {
        _sale = _sale.copyWith(shirtDeliveredAt: at);
      });

      final shirtQuantity = _sale.ticketQuantity;
      final shirtLabel = shirtQuantity == 1 ? 'camisa' : 'camisas';
      final msg =
          'Ola, ${_sale.buyerName}! Camisa entregue. Quantidade: $shirtQuantity $shirtLabel.';
      final whatsOk = await _launchWhatsAppWithMessage(msg);
      if (!mounted) return;
      if (!whatsOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Entrega registrada. Nao foi possivel abrir o WhatsApp — envie a mensagem manualmente se precisar.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrega da camisa registrada.')),
        );
      }
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    } finally {
      if (mounted) setState(() => _isDeliveringShirt = false);
    }
  }

  Future<void> _openRegisterPaymentDialog() async {
    if (_sale.id == null || _sale.remainingAmount <= 0) return;

    final paymentFormKey = GlobalKey<FormState>();
    var amountText = '';
    var selectedDate = DateTime.now();
    var selectedPaymentMethod = _paymentMethods.first;
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submitPayment() async {
              if (!paymentFormKey.currentState!.validate()) return;

              final amount = double.parse(
                amountText.trim().replaceAll(',', '.'),
              );
              setDialogState(() => isSubmitting = true);
              final messenger = ScaffoldMessenger.of(context);
              final dialogNavigator = Navigator.of(context);

              try {
                final updatedSale = await _controller.registerPayment(
                  sale: _sale,
                  amount: amount,
                  receivedAt: selectedDate,
                  paymentMethod: selectedPaymentMethod,
                );

                if (!mounted) return;
                setState(() {
                  _sale = updatedSale;
                  _refreshReceipts();
                });
                if (dialogNavigator.mounted) {
                  dialogNavigator.pop();
                }
                messenger.showSnackBar(
                  const SnackBar(content: Text('Pagamento registrado.')),
                );
              } on ArgumentError catch (error) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(error.message.toString())),
                );
                if (dialogNavigator.mounted) {
                  setDialogState(() => isSubmitting = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('Registrar pagamento'),
              content: SingleChildScrollView(
                child: Form(
                  key: paymentFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: amountText,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Valor recebido',
                          helperText:
                              'Pendente: R\$ ${_sale.remainingAmount.toStringAsFixed(2)}',
                        ),
                        onChanged: (value) => amountText = value,
                        validator: (value) {
                          final amount = double.tryParse(
                            (value ?? '').trim().replaceAll(',', '.'),
                          );
                          if (amount == null || amount <= 0) {
                            return 'Informe um valor valido';
                          }
                          if (amount > _sale.remainingAmount) {
                            return 'Valor maior que o pendente';
                          }
                          amountText = value ?? '';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: isSubmitting
                            ? null
                            : () async {
                                final pickedDate = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (pickedDate == null) return;
                                setDialogState(() {
                                  selectedDate = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    selectedDate.hour,
                                    selectedDate.minute,
                                    selectedDate.second,
                                  );
                                });
                              },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data do pagamento',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_formatDateOnly(selectedDate)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPaymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Forma de pagamento',
                        ),
                        items: _paymentMethods
                            .map(
                              (method) => DropdownMenuItem(
                                value: method,
                                child: Text(_paymentMethodLabel(method)),
                              ),
                            )
                            .toList(),
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(
                                  () => selectedPaymentMethod = value,
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submitPayment,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar pagamento'),
                ),
              ],
            );
          },
        );
      },
    );
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

    if (confirm != true || _sale.id == null) return;

    setState(() => _isDeleting = true);
    await _controller.deleteSale(_sale.id!);
    if (!mounted) return;
    Navigator.of(context).pop('deleted');
  }

  Future<void> _enterEditMode() async {
    final sizes = _sale.id == null
        ? <ShirtSizeModel>[]
        : await _controller.getShirtSizesBySale(_sale.id!);
    final remaining = _sale.id == null
        ? <String, int>{}
        : await _shirtsController.getRemainingStockForEdit(_sale.id!);
    if (!mounted) return;
    setState(() {
      _editShirtEntries = sizes
          .map((s) => _ShirtEntry(size: s.size, quantity: s.quantity))
          .toList();
      _remainingStock = remaining;
      _isEditMode = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _buyerPhoneController.text = _sale.buyerPhone;
      _installments = _sale.installments;
      _editShirtEntries = [];
      _remainingStock = {};
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

  String _formatDateOnly(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _paymentMethodLabel(String paymentMethod) {
    switch (paymentMethod) {
      case 'PIX':
        return 'PIX';
      case 'dinheiro':
        return 'Dinheiro';
      case 'cartao':
        return 'Cartao';
      default:
        return 'Nao informado';
    }
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
                'Status: ${_sale.paymentStatus.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Valor recebido: R\$ ${_sale.receivedAmount.toStringAsFixed(2)}',
              ),
              Text(
                'Valor pendente: R\$ ${_sale.remainingAmount.toStringAsFixed(2)}',
              ),
              Text(
                'Data do ultimo recebimento: ${_formatDate(_sale.receivedAt)}',
              ),
              const SizedBox(height: 16),
              if (_sale.remainingAmount > 0) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openRegisterPaymentDialog,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Registrar pagamento'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_sale.shirtDeliveredAt == null) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isDeliveringShirt ? null : _confirmDeliverShirt,
                    icon: _isDeliveringShirt
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.checkroom_outlined),
                    label: const Text('Entregar camisa'),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade800),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Camisa entregue em ${_formatDate(_sale.shirtDeliveredAt)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                            subtitle: Text(
                              '${_formatDate(receipt.receivedAt)} - '
                              '${_paymentMethodLabel(receipt.paymentMethod)}',
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tamanhos de camisa',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_isEditMode)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _editShirtEntries.add(
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
              if (_isEditMode) ...[
                if (_editShirtEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Nenhum tamanho adicionado',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...List.generate(_editShirtEntries.length, (index) {
                    final entry = _editShirtEntries[index];
                    final available = _remainingStock[entry.size] ?? 0;
                    final exceedsStock = entry.quantity > available;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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
                                      () => _editShirtEntries[index] =
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
                                    errorText:
                                        exceedsStock ? 'Max: $available' : null,
                                  ),
                                  onChanged: (value) {
                                    final qty = int.tryParse(value) ?? 1;
                                    setState(
                                      () => _editShirtEntries[index] =
                                          _ShirtEntry(
                                            size: entry.size,
                                            quantity: qty,
                                          ),
                                    );
                                  },
                                  validator: (value) {
                                    final qty = int.tryParse(value ?? '');
                                    if (qty == null || qty <= 0) {
                                      return 'Invalido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.red,
                                onPressed: () => setState(
                                  () => _editShirtEntries.removeAt(index),
                                ),
                              ),
                            ],
                          ),
                          if (_remainingStock.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 2),
                              child: Text(
                                'Disponivel: $available',
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      exceedsStock ? Colors.red : Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
              ] else
                FutureBuilder<List<ShirtSizeModel>>(
                  future: _shirtSizesFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final sizes = snapshot.data!;
                    if (sizes.isEmpty) {
                      return const Text(
                        'Nenhum tamanho registrado.',
                        style: TextStyle(color: Colors.grey),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sizes
                          .map(
                            (s) => Chip(
                              avatar: const Icon(Icons.checkroom, size: 16),
                              label: Text(
                                '${s.size} × ${s.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                decoration: const InputDecoration(
                  labelText: 'Nome do comprador',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _buyerPhoneController,
                enabled: _isEditMode,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numero de telefone',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o telefone'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                enabled: false,
                key: ValueKey<int>(_currentQuantity),
                initialValue: '$_currentQuantity',
                decoration: const InputDecoration(
                  labelText: 'Quantidade de camisas',
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
                key: ValueKey<String>(
                  'detail_total_${_calculatedTotal.toStringAsFixed(2)}',
                ),
                enabled: false,
                initialValue: 'R\$ ${_calculatedTotal.toStringAsFixed(2)}',
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
                onChanged: _isEditMode
                    ? (value) => setState(() => _installments = value ?? 1)
                    : null,
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
                                _enterEditMode();
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openWhatsApp,
                  icon: const FaIcon(FontAwesomeIcons.whatsapp),
                  label: const Text('Falar no WhatsApp'),
                ),
              ),
              const SizedBox(height: 42),
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
