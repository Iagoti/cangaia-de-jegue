import 'package:cangaia_de_jegue/controllers/expenses_controller.dart';
import 'package:cangaia_de_jegue/controllers/sales_controller.dart';
import 'package:cangaia_de_jegue/models/ticket_sale_model.dart';
import 'package:cangaia_de_jegue/views/expense_form_view.dart';
import 'package:cangaia_de_jegue/views/expenses_list_view.dart';
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
  final _expensesController = ExpensesController();
  bool _isSyncing = false;

  Future<void> _goToSalesScreen() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HomeView(loggedUser: widget.loggedUser),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Venda salva com sucesso.')));
    }
    setState(() {});
  }

  Future<void> _goToSalesListScreen() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SalesListView()));
    if (mounted) setState(() {});
  }

  Future<void> _goToExpenseForm() async {
    final saved = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const ExpenseFormView()));
    if (!mounted) return;
    if (saved == 'created') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Despesa salva com sucesso.')),
      );
    }
    setState(() {});
  }

  Future<void> _goToExpensesListScreen() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ExpensesListView()));
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
            'Recibos recebidos: ${result.receivedReceipts} | '
            'Despesas recebidas: ${result.receivedExpenses}',
          ),
        ),
      );
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha na sincronizacao: $error')));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _closeDrawerAndRun(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.dashboard, size: 32),
                    const SizedBox(height: 10),
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text('Usuario: ${widget.loggedUser}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _DrawerSectionTitle(title: 'Vendas'),
              _DrawerMenuItem(
                icon: const Icon(Icons.point_of_sale),
                title: const Text('Registrar venda'),
                onTap: () => _closeDrawerAndRun(_goToSalesScreen),
              ),
              _DrawerMenuItem(
                icon: const Icon(Icons.list_alt),
                title: const Text('Lista de vendas'),
                onTap: () => _closeDrawerAndRun(_goToSalesListScreen),
              ),
              const SizedBox(height: 12),
              const _DrawerSectionTitle(title: 'Despesas'),
              _DrawerMenuItem(
                icon: const Icon(Icons.add_card),
                title: const Text('Adicionar despesa'),
                onTap: () => _closeDrawerAndRun(_goToExpenseForm),
              ),
              _DrawerMenuItem(
                icon: const Icon(Icons.receipt),
                title: const Text('Lista de despesas'),
                onTap: () => _closeDrawerAndRun(_goToExpensesListScreen),
              ),
              const SizedBox(height: 12),
              const _DrawerSectionTitle(title: 'Sistema'),
              _DrawerMenuItem(
                icon: _isSyncing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                title: Text(
                  _isSyncing ? 'Sincronizando...' : 'Sincronizar dados',
                ),
                onTap: _isSyncing ? null : () => _closeDrawerAndRun(_syncData),
              ),
              const SizedBox(height: 20),
              const Divider(),
              _DrawerMenuItem(
                icon: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () => _closeDrawerAndRun(_logout),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _goToSalesScreen,
                      icon: const Icon(Icons.point_of_sale),
                      label: const Text('Venda'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _goToExpenseForm,
                      icon: const Icon(Icons.add_card),
                      label: const Text('Despesa'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FutureBuilder<int>(
        future: _salesController.getPendingSyncCount(),
        builder: (context, snapshot) {
          final pendingSyncCount = snapshot.data ?? 0;
          if (pendingSyncCount <= 0) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: _isSyncing ? null : _syncData,
            icon: _isSyncing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar'),
          );
        },
      ),
      body: FutureBuilder<List<Object>>(
        future: Future.wait<Object>([
          _salesController.getSales(),
          _salesController.getPendingSyncCount(),
          _expensesController.getTotalExpenses(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final sales = data[0] as List<TicketSaleModel>;
          final pendingSyncCount = data[1] as int;
          final totalExpenses = data[2] as double;
          final totalSales = sales.length;
          final totalValue = sales.fold<double>(
            0,
            (sum, sale) => sum + sale.totalAmount,
          );
          final totalReceived = sales.fold<double>(
            0,
            (sum, sale) => sum + sale.receivedAmount,
          );

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SingleChildScrollView(
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
                    title: 'Valor total',
                    value: 'R\$ ${totalValue.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                  ),
                  const SizedBox(height: 10),
                  _DashboardCard(
                    title: 'Total recebido',
                    value: 'R\$ ${totalReceived.toStringAsFixed(2)}',
                    icon: Icons.payments,
                  ),
                  const SizedBox(height: 10),
                  _DashboardCard(
                    title: 'Despesas',
                    value: 'R\$ ${totalExpenses.toStringAsFixed(2)}',
                    icon: Icons.money_off,
                  ),
                  const SizedBox(height: 10),
                  _DashboardCard(
                    title: 'Pendentes de sincronizacao',
                    value: '$pendingSyncCount',
                    icon: Icons.sync_problem,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DrawerSectionTitle extends StatelessWidget {
  const _DrawerSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final Widget icon;
  final Widget title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: icon,
        title: DefaultTextStyle.merge(
          style: const TextStyle(fontWeight: FontWeight.w600),
          child: title,
        ),
        onTap: onTap,
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
