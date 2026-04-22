import 'package:cangaia_de_jegue/controllers/sales_controller.dart';
import 'package:cangaia_de_jegue/models/ticket_sale_model.dart';
import 'package:cangaia_de_jegue/views/home_view.dart';
import 'package:cangaia_de_jegue/views/login_view.dart';
import 'package:cangaia_de_jegue/views/sales_list_view.dart';
import 'package:flutter/material.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key, required this.loggedUser});

  final String loggedUser;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _salesController = SalesController();
  bool _isSyncing = false;

  Future<void> _goToSalesScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeView(loggedUser: widget.loggedUser),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _goToSalesListScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SalesListView()),
    );
    if (mounted) setState(() {});
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  Future<void> _syncData() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);
    try {
      final result = await _salesController.syncBidirectional();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sync concluida. Enviados: ${result.sentEvents} | '
            'Vendas recebidas: ${result.receivedSales} | '
            'Recibos recebidos: ${result.receivedReceipts}',
          ),
        ),
      );
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha na sincronizacao: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: FutureBuilder<List<Object>>(
        future: Future.wait<Object>([
          _salesController.getSales(),
          _salesController.getPendingSyncCount(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final sales = data[0] as List<TicketSaleModel>;
          final pendingSyncCount = data[1] as int;
          final totalSales = sales.length;
          final totalValue =
              sales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);
          final totalTickets =
              sales.fold<int>(0, (sum, sale) => sum + sale.ticketQuantity);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo(a), ${widget.loggedUser}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _DashboardCard(
                  title: 'Vendas registradas',
                  value: '$totalSales',
                  icon: Icons.receipt_long,
                ),
                const SizedBox(height: 10),
                _DashboardCard(
                  title: 'Ingressos vendidos',
                  value: '$totalTickets',
                  icon: Icons.confirmation_num,
                ),
                const SizedBox(height: 10),
                _DashboardCard(
                  title: 'Valor total',
                  value: 'R\$ ${totalValue.toStringAsFixed(2)}',
                  icon: Icons.attach_money,
                ),
                const SizedBox(height: 10),
                _DashboardCard(
                  title: 'Pendentes de sincronizacao',
                  value: '$pendingSyncCount',
                  icon: Icons.sync_problem,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _goToSalesScreen,
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('Ir para registro de vendas'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _goToSalesListScreen,
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Ver lista de vendas'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSyncing ? null : _syncData,
                    icon: _isSyncing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar dados'),
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

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
