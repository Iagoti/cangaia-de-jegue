class TicketSaleModel {
  const TicketSaleModel({
    this.id,
    required this.buyerName,
    required this.ticketQuantity,
    required this.totalAmount,
    required this.installments,
    required this.sellerUsername,
    required this.createdAt,
    required this.receivedAmount,
    required this.paymentStatus,
    this.receivedAt,
  });

  final int? id;
  final String buyerName;
  final int ticketQuantity;
  final double totalAmount;
  final int installments;
  final String sellerUsername;
  final String createdAt;
  final double receivedAmount;
  final String paymentStatus;
  final String? receivedAt;

  double get remainingAmount {
    final remaining = totalAmount - receivedAmount;
    return remaining < 0 ? 0 : remaining;
  }

  factory TicketSaleModel.fromMap(Map<String, Object?> map) {
    return TicketSaleModel(
      id: map['id'] as int,
      buyerName: map['nome_comprador'] as String,
      ticketQuantity: map['quantidade_ingressos'] as int,
      totalAmount: (map['valor_total'] as num).toDouble(),
      installments: map['parcelamento'] as int,
      sellerUsername: map['usuario_vendedor'] as String,
      createdAt: map['criado_em'] as String,
      receivedAmount: (map['valor_recebido'] as num?)?.toDouble() ?? 0,
      paymentStatus: (map['status_pagamento'] as String?) ?? 'pendente',
      receivedAt: map['recebido_em'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nome_comprador': buyerName,
      'quantidade_ingressos': ticketQuantity,
      'valor_total': totalAmount,
      'parcelamento': installments,
      'usuario_vendedor': sellerUsername,
      'criado_em': createdAt,
      'valor_recebido': receivedAmount,
      'status_pagamento': paymentStatus,
      'recebido_em': receivedAt,
    };
  }

  TicketSaleModel copyWith({
    int? id,
    String? buyerName,
    int? ticketQuantity,
    double? totalAmount,
    int? installments,
    String? sellerUsername,
    String? createdAt,
    double? receivedAmount,
    String? paymentStatus,
    String? receivedAt,
  }) {
    return TicketSaleModel(
      id: id ?? this.id,
      buyerName: buyerName ?? this.buyerName,
      ticketQuantity: ticketQuantity ?? this.ticketQuantity,
      totalAmount: totalAmount ?? this.totalAmount,
      installments: installments ?? this.installments,
      sellerUsername: sellerUsername ?? this.sellerUsername,
      createdAt: createdAt ?? this.createdAt,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }
}
