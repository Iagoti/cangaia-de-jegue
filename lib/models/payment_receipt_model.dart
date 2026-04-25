class PaymentReceiptModel {
  const PaymentReceiptModel({
    this.id,
    required this.saleId,
    required this.amount,
    required this.receivedAt,
    required this.paymentMethod,
  });

  final int? id;
  final int saleId;
  final double amount;
  final String receivedAt;
  final String paymentMethod;

  factory PaymentReceiptModel.fromMap(Map<String, Object?> map) {
    return PaymentReceiptModel(
      id: map['id'] as int,
      saleId: map['venda_id'] as int,
      amount: (map['valor'] as num).toDouble(),
      receivedAt: map['recebido_em'] as String,
      paymentMethod: (map['forma_pagamento'] as String?) ?? 'nao_informado',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'venda_id': saleId,
      'valor': amount,
      'recebido_em': receivedAt,
      'forma_pagamento': paymentMethod,
    };
  }
}
