import 'package:cangaia_de_jegue/controllers/expenses_controller.dart';
import 'package:cangaia_de_jegue/models/expense_model.dart';
import 'package:cangaia_de_jegue/views/expense_form_view.dart';
import 'package:flutter/material.dart';

class ExpensesListView extends StatefulWidget {
  const ExpensesListView({super.key});

  @override
  State<ExpensesListView> createState() => _ExpensesListViewState();
}

class _ExpensesListViewState extends State<ExpensesListView> {
  final _expensesController = ExpensesController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExpenseModel> _applyFilter(List<ExpenseModel> expenses, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return expenses;

    return expenses
        .where(
          (expense) =>
              expense.description.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  Future<void> _goToExpenseForm() async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ExpenseFormView()));
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Despesa salva com sucesso.')),
      );
      setState(() {});
    }
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
      appBar: AppBar(title: const Text('Lista de despesas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToExpenseForm,
        icon: const Icon(Icons.add),
        label: const Text('Despesa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Filtrar por descricao',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<ExpenseModel>>(
                future: _expensesController.getExpenses(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredExpenses = _applyFilter(
                    snapshot.data!,
                    _searchController.text,
                  );

                  if (filteredExpenses.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma despesa encontrada.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.money_off),
                          title: Text(expense.description),
                          subtitle: Text(
                            'Data: ${_formatDate(expense.expenseDate)}',
                          ),
                          trailing: Text(
                            'R\$ ${expense.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
