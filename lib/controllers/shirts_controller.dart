import 'package:cangaia_de_jegue/database/app_database.dart';
import 'package:cangaia_de_jegue/models/shirt_order_model.dart';
import 'package:cangaia_de_jegue/models/shirt_size_model.dart';

class ShirtSummary {
  const ShirtSummary({
    required this.size,
    required this.stock,
    required this.sold,
  });

  final String size;
  final int stock;
  final int sold;
  int get remaining => (stock - sold).clamp(0, stock);
}

class ShirtsController {
  Future<void> saveOrders(List<ShirtOrderModel> orders) async {
    for (final order in orders) {
      await AppDatabase.instance.createShirtOrder(order);
    }
  }

  Future<List<ShirtOrderModel>> getOrders() {
    return AppDatabase.instance.listShirtOrders();
  }

  Future<void> deleteOrder(int id) {
    return AppDatabase.instance.deleteShirtOrder(id);
  }

  Future<List<ShirtSummary>> getShirtSummary() async {
    final stock = await AppDatabase.instance.getShirtStockTotals();
    final sold = await AppDatabase.instance.getShirtSoldTotals();

    return ShirtSizeModel.validSizes.map((size) {
      return ShirtSummary(
        size: size,
        stock: stock[size] ?? 0,
        sold: sold[size] ?? 0,
      );
    }).toList();
  }

  /// Calcula o estoque disponível desconsiderando as camisas já vinculadas
  /// à venda em edição (para que o editor possa redistribuir livremente).
  Future<Map<String, int>> getRemainingStockForEdit(int saleId) async {
    final stock = await AppDatabase.instance.getShirtStockTotals();
    final soldExcluding =
        await AppDatabase.instance.getShirtSoldTotalsExcludingSale(saleId);

    return {
      for (final size in ShirtSizeModel.validSizes)
        size: ((stock[size] ?? 0) - (soldExcluding[size] ?? 0)).clamp(0, 999),
    };
  }

  Map<String, int> buildTotals(List<ShirtOrderModel> orders) {
    final totals = <String, int>{};
    for (final size in ShirtSizeModel.validSizes) {
      totals[size] = 0;
    }
    for (final order in orders) {
      totals[order.size] = (totals[order.size] ?? 0) + order.quantity;
    }
    return totals;
  }
}
