class ShirtOrderModel {
  const ShirtOrderModel({
    this.id,
    required this.size,
    required this.quantity,
    required this.createdAt,
  });

  final int? id;
  final String size;
  final int quantity;
  final String createdAt;

  factory ShirtOrderModel.fromMap(Map<String, Object?> map) {
    return ShirtOrderModel(
      id: map['id'] as int?,
      size: map['tamanho'] as String,
      quantity: map['quantidade'] as int,
      createdAt: map['criado_em'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'tamanho': size,
      'quantidade': quantity,
      'criado_em': createdAt,
    };
  }
}
