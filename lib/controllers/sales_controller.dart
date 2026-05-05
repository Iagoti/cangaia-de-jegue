import 'package:cangaia_de_jegue/database/app_database.dart';
import 'package:cangaia_de_jegue/models/payment_receipt_model.dart';
import 'package:cangaia_de_jegue/models/shirt_size_model.dart';
import 'package:cangaia_de_jegue/models/ticket_sale_model.dart';
import 'package:cangaia_de_jegue/services/sync_service.dart';

class SyncSummary {
  const SyncSummary({
    required this.sentEvents,
    required this.receivedSales,
    required this.receivedReceipts,
    required this.receivedExpenses,
  });

  final int sentEvents;
  final int receivedSales;
  final int receivedReceipts;
  final int receivedExpenses;
}

class SalesController {
  final _syncService = const SyncService();
  Future<int> registerSale({
    required String buyerName,
    required String buyerPhone,
    required int ticketQuantity,
    required double totalAmount,
    required int installments,
    required String sellerUsername,
    double receivedAmount = 0,
    bool markAsPaid = false,
    List<ShirtSizeModel> shirtSizes = const [],
  }) async {
    if (installments < 1 || installments > 3) {
      throw ArgumentError('Parcelamento deve ser entre 1 e 3 vezes.');
    }

    final effectiveReceived = markAsPaid ? totalAmount : receivedAmount.clamp(0.0, totalAmount);
    final paymentStatus = effectiveReceived >= totalAmount ? 'pago' : 'pendente';
    final nowIso = DateTime.now().toIso8601String();
    final receivedAt = effectiveReceived > 0 ? nowIso : null;

    final id = await AppDatabase.instance.createSale(
      TicketSaleModel(
        buyerName: buyerName,
        buyerPhone: buyerPhone,
        ticketQuantity: ticketQuantity,
        totalAmount: totalAmount,
        installments: installments,
        sellerUsername: sellerUsername,
        createdAt: nowIso,
        receivedAmount: effectiveReceived,
        paymentStatus: paymentStatus,
        receivedAt: receivedAt,
      ),
    );

    if (effectiveReceived > 0) {
      await AppDatabase.instance.addReceipt(
        PaymentReceiptModel(
          saleId: id,
          amount: effectiveReceived,
          receivedAt: nowIso,
          paymentMethod: 'nao_informado',
        ),
      );
    }

    if (shirtSizes.isNotEmpty) {
      final sizesWithSaleId = shirtSizes
          .map((s) => ShirtSizeModel(saleId: id, size: s.size, quantity: s.quantity))
          .toList();
      await AppDatabase.instance.replaceShirtSizesForSale(id, sizesWithSaleId);
    }

    return id;
  }

  Future<List<TicketSaleModel>> getSales() {
    return AppDatabase.instance.listSales();
  }

  Future<void> updateSale({
    required TicketSaleModel originalSale,
    required String buyerName,
    required String buyerPhone,
    required int ticketQuantity,
    required double totalAmount,
    required int installments,
    required double receivedNow,
  }) async {
    if (installments < 1 || installments > 3) {
      throw ArgumentError('Parcelamento deve ser entre 1 e 3 vezes.');
    }
    if (receivedNow < 0) {
      throw ArgumentError('Valor recebido nao pode ser negativo.');
    }

    if (originalSale.id == null) {
      throw ArgumentError('Venda invalida para atualizacao.');
    }

    final updatedReceived = originalSale.receivedAmount + receivedNow;
    if (updatedReceived > totalAmount) {
      throw ArgumentError('Valor recebido nao pode ultrapassar o valor total.');
    }

    final paymentStatus = updatedReceived >= totalAmount ? 'pago' : 'pendente';
    final nowIso = DateTime.now().toIso8601String();
    final receivedAt = receivedNow > 0 ? nowIso : originalSale.receivedAt;

    final updatedSale = originalSale.copyWith(
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      ticketQuantity: ticketQuantity,
      totalAmount: totalAmount,
      installments: installments,
      receivedAmount: updatedReceived,
      paymentStatus: paymentStatus,
      receivedAt: receivedAt,
    );

    await AppDatabase.instance.updateSale(updatedSale);

    if (receivedNow > 0) {
      await AppDatabase.instance.addReceipt(
        PaymentReceiptModel(
          saleId: originalSale.id!,
          amount: receivedNow,
          receivedAt: nowIso,
          paymentMethod: 'nao_informado',
        ),
      );
    }
  }

  Future<TicketSaleModel> registerPayment({
    required TicketSaleModel sale,
    required double amount,
    required DateTime receivedAt,
    required String paymentMethod,
  }) async {
    if (sale.id == null) {
      throw ArgumentError('Venda invalida para registrar pagamento.');
    }
    if (amount <= 0) {
      throw ArgumentError('Valor recebido deve ser maior que zero.');
    }

    final updatedReceived = sale.receivedAmount + amount;
    if (updatedReceived > sale.totalAmount + 0.001) {
      throw ArgumentError('Valor recebido nao pode ultrapassar o valor total.');
    }

    final normalizedReceived = updatedReceived >= sale.totalAmount
        ? sale.totalAmount
        : updatedReceived;
    final paymentStatus = normalizedReceived >= sale.totalAmount
        ? 'pago'
        : 'pendente';
    final receivedAtIso = receivedAt.toIso8601String();
    final updatedSale = sale.copyWith(
      receivedAmount: normalizedReceived,
      paymentStatus: paymentStatus,
      receivedAt: receivedAtIso,
    );

    await AppDatabase.instance.updateSale(updatedSale);
    await AppDatabase.instance.addReceipt(
      PaymentReceiptModel(
        saleId: sale.id!,
        amount: amount,
        receivedAt: receivedAtIso,
        paymentMethod: paymentMethod,
      ),
    );

    return updatedSale;
  }

  /// Grava data/hora da entrega da camisa e enfileira sincronizacao.
  Future<String> markShirtDelivered(TicketSaleModel sale) async {
    if (sale.id == null) {
      throw ArgumentError('Venda invalida.');
    }
    if (sale.shirtDeliveredAt != null) {
      throw ArgumentError('Camisa ja consta como entregue.');
    }
    final at = DateTime.now().toIso8601String();
    final updated = sale.copyWith(shirtDeliveredAt: at);
    await AppDatabase.instance.updateSale(updated);
    return at;
  }

  Future<void> deleteSale(int id) async {
    await AppDatabase.instance.deleteSale(id);
  }

  Future<List<PaymentReceiptModel>> getReceiptsBySale(int saleId) {
    return AppDatabase.instance.listReceiptsBySale(saleId);
  }

  Future<List<ShirtSizeModel>> getShirtSizesBySale(int saleId) {
    return AppDatabase.instance.listShirtSizesBySale(saleId);
  }

  Future<void> updateShirtSizes(int saleId, List<ShirtSizeModel> sizes) {
    return AppDatabase.instance.replaceShirtSizesForSale(saleId, sizes);
  }

  Future<List<Map<String, Object?>>> getAllShirtSizesWithSale() {
    return AppDatabase.instance.listAllShirtSizesWithSale();
  }

  Future<int> getPendingSyncCount() {
    return AppDatabase.instance.countPendingSyncEvents();
  }

  Future<int> syncPendingEvents() async {
    final pendingEvents = await AppDatabase.instance.listPendingSyncEvents();
    var syncedCount = 0;

    for (final event in pendingEvents) {
      final eventId = event['id'] as int;
      final entityType = event['tipo_entidade'] as String;
      final operation = event['operacao'] as String;
      final entityId = event['id_entidade'] as int?;

      if (entityId == null) {
        await AppDatabase.instance.markSyncEventAsSynced(eventId);
        continue;
      }

      if (entityType == 'vendas_ingressos' && operation == 'delete') {
        await _syncService.deleteVenda(entityId);
      } else if (entityType == 'vendas_ingressos') {
        final saleMap = await AppDatabase.instance.getSaleMapById(entityId);
        if (saleMap != null) {
          await _syncService.upsertVenda(saleMap);
        }
      } else if (entityType == 'recibos_pagamento') {
        final receiptMap = await AppDatabase.instance.getReceiptMapById(
          entityId,
        );
        if (receiptMap != null) {
          await _syncService.upsertRecibo(receiptMap);
        }
      } else if (entityType == 'despesas' && operation == 'delete') {
        await _syncService.deleteDespesa(entityId);
      } else if (entityType == 'despesas') {
        final expenseMap = await AppDatabase.instance.getExpenseMapById(
          entityId,
        );
        if (expenseMap != null) {
          await _syncService.upsertDespesa(expenseMap);
        }
      }

      await AppDatabase.instance.markSyncEventAsSynced(eventId);
      syncedCount++;
    }

    return syncedCount;
  }

  Future<SyncSummary> syncBidirectional() async {
    final sentEvents = await syncPendingEvents();
    final remoteSales = await _syncService.fetchVendas();
    final remoteReceipts = await _syncService.fetchRecibos();
    final remoteExpenses = await _syncService.fetchDespesas();

    for (final sale in remoteSales) {
      await AppDatabase.instance.upsertSaleFromRemote(sale);
    }
    for (final receipt in remoteReceipts) {
      await AppDatabase.instance.upsertReceiptFromRemote(receipt);
    }
    for (final expense in remoteExpenses) {
      await AppDatabase.instance.upsertExpenseFromRemote(expense);
    }

    return SyncSummary(
      sentEvents: sentEvents,
      receivedSales: remoteSales.length,
      receivedReceipts: remoteReceipts.length,
      receivedExpenses: remoteExpenses.length,
    );
  }
}
