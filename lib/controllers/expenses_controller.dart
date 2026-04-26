import 'package:cangaia_de_jegue/database/app_database.dart';
import 'package:cangaia_de_jegue/models/expense_model.dart';

class ExpensesController {
  Future<int> registerExpense({
    required String description,
    required double amount,
    required DateTime expenseDate,
  }) {
    if (description.trim().isEmpty) {
      throw ArgumentError('Informe a descricao da despesa.');
    }
    if (amount <= 0) {
      throw ArgumentError('Valor da despesa deve ser maior que zero.');
    }

    return AppDatabase.instance.createExpense(
      ExpenseModel(
        description: description.trim(),
        amount: amount,
        expenseDate: expenseDate.toIso8601String(),
      ),
    );
  }

  Future<void> updateExpense({
    required ExpenseModel originalExpense,
    required String description,
    required double amount,
    required DateTime expenseDate,
  }) async {
    if (originalExpense.id == null) {
      throw ArgumentError('Despesa invalida.');
    }
    if (description.trim().isEmpty) {
      throw ArgumentError('Informe a descricao da despesa.');
    }
    if (amount <= 0) {
      throw ArgumentError('Valor da despesa deve ser maior que zero.');
    }

    await AppDatabase.instance.updateExpense(
      originalExpense.copyWith(
        description: description.trim(),
        amount: amount,
        expenseDate: expenseDate.toIso8601String(),
      ),
    );
  }

  Future<void> deleteExpense(int id) async {
    await AppDatabase.instance.deleteExpense(id);
  }

  Future<List<ExpenseModel>> getExpenses() {
    return AppDatabase.instance.listExpenses();
  }

  Future<double> getTotalExpenses() {
    return AppDatabase.instance.sumExpenses();
  }
}
