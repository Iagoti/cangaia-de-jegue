class ExpenseModel {
  const ExpenseModel({
    this.id,
    required this.description,
    required this.amount,
    required this.expenseDate,
  });

  final int? id;
  final String description;
  final double amount;
  final String expenseDate;

  factory ExpenseModel.fromMap(Map<String, Object?> map) {
    return ExpenseModel(
      id: map['id'] as int,
      description: map['descricao'] as String,
      amount: (map['valor'] as num).toDouble(),
      expenseDate: map['data_despesa'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'descricao': description,
      'valor': amount,
      'data_despesa': expenseDate,
    };
  }
}
