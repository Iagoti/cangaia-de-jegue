import 'package:cangaia_de_jegue/controllers/shirts_controller.dart';
import 'package:cangaia_de_jegue/models/shirt_order_model.dart';
import 'package:cangaia_de_jegue/views/shirt_form_view.dart';
import 'package:flutter/material.dart';

class ShirtsListView extends StatefulWidget {
  const ShirtsListView({super.key});

  @override
  State<ShirtsListView> createState() => _ShirtsListViewState();
}

class _ShirtsListViewState extends State<ShirtsListView> {
  final _controller = ShirtsController();
  late Future<(List<ShirtSummary>, List<ShirtOrderModel>)> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = Future.wait([
      _controller.getShirtSummary(),
      _controller.getOrders(),
    ]).then((results) => (
          results[0] as List<ShirtSummary>,
          results[1] as List<ShirtOrderModel>,
        ));
  }

  void _reload() => setState(_load);

  Future<void> _goToForm() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ShirtFormView()),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _confirmDelete(ShirtOrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir registro'),
        content: Text(
          'Excluir ${order.quantity}× ${order.size} cadastrado em ${_formatDate(order.createdAt)}?',
        ),
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
      ),
    );
    if (confirm != true || order.id == null) return;
    await _controller.deleteOrder(order.id!);
    if (mounted) _reload();
  }

  String _formatDate(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camisas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToForm,
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar'),
      ),
      body: FutureBuilder<(List<ShirtSummary>, List<ShirtOrderModel>)>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final (summaries, orders) = snapshot.data!;
          final totalStock = summaries.fold(0, (s, e) => s + e.stock);
          final totalSold = summaries.fold(0, (s, e) => s + e.sold);
          final totalRemaining = summaries.fold(0, (s, e) => s + e.remaining);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // ── Resumo geral ──────────────────────────────────────
                Row(
                  children: [
                    _TotalChip(
                      label: 'Cadastradas',
                      value: totalStock,
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    _TotalChip(
                      label: 'Vendidas',
                      value: totalSold,
                      color: Colors.green.shade300,
                    ),
                    const SizedBox(width: 8),
                    _TotalChip(
                      label: 'Restantes',
                      value: totalRemaining,
                      color: Colors.orange.shade300,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Por tamanho ───────────────────────────────────────
                Text(
                  'Por tamanho',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...summaries.map(
                  (s) => _SizeRow(summary: s),
                ),
                const SizedBox(height: 20),

                // ── Registros de estoque ──────────────────────────────
                Text(
                  'Estoque cadastrado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Nenhuma camisa cadastrada no estoque.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...orders.map(
                    (order) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            order.size,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '${order.quantity} camisa${order.quantity != 1 ? 's' : ''} — ${order.size}',
                        ),
                        subtitle: Text(
                          'Cadastrado em ${_formatDate(order.createdAt)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                          onPressed: () => _confirmDelete(order),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  const _SizeRow({required this.summary});

  final ShirtSummary summary;

  @override
  Widget build(BuildContext context) {
    final hasStock = summary.stock > 0;
    final isLow = summary.remaining == 0 && summary.stock > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isLow ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: hasStock
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(
                summary.size,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: hasStock
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BarStat(
                    label: 'Cadastradas',
                    value: summary.stock,
                    max: summary.stock == 0 ? 1 : summary.stock,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  _BarStat(
                    label: 'Vendidas',
                    value: summary.sold,
                    max: summary.stock == 0 ? 1 : summary.stock,
                    color: Colors.green.shade400,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${summary.remaining}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isLow
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Text(
                  'restantes',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarStat extends StatelessWidget {
  const _BarStat({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            '$label: $value',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

