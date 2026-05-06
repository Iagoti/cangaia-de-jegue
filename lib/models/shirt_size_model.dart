class ShirtSizeModel {
  const ShirtSizeModel({
    this.id,
    required this.saleId,
    required this.size,
    required this.quantity,
  });

  final int? id;
  final int saleId;
  final String size;
  final int quantity;

  static const List<String> validSizes = ['PP', 'P', 'M', 'G', 'GG'];

  factory ShirtSizeModel.fromMap(Map<String, Object?> map) {
    return ShirtSizeModel(
      id: map['id'] as int?,
      saleId: map['venda_id'] as int,
      size: map['tamanho'] as String,
      quantity: map['quantidade'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'venda_id': saleId,
      'tamanho': size,
      'quantidade': quantity,
    };
  }
}
