class PaymentReceiptModel {
  const PaymentReceiptModel({
    this.id,
    required this.saleId,
    required this.amount,
    required this.receivedAt,
  });

  final int? id;
  final int saleId;
  final double amount;
  final String receivedAt;

  factory PaymentReceiptModel.fromMap(Map<String, Object?> map) {
    return PaymentReceiptModel(
      id: map['id'] as int,
      saleId: map['venda_id'] as int,
      amount: (map['valor'] as num).toDouble(),
      receivedAt: map['recebido_em'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'venda_id': saleId,
      'valor': amount,
      'recebido_em': receivedAt,
    };
  }
}
