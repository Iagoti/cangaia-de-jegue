import 'package:cangaia_de_jegue/database/app_database.dart';
import 'package:cangaia_de_jegue/models/payment_receipt_model.dart';
import 'package:cangaia_de_jegue/models/ticket_sale_model.dart';
import 'package:cangaia_de_jegue/services/sync_service.dart';

class SyncSummary {
  const SyncSummary({
    required this.sentEvents,
    required this.receivedSales,
    required this.receivedReceipts,
  });

  final int sentEvents;
  final int receivedSales;
  final int receivedReceipts;
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
  }) {
    if (installments < 1 || installments > 3) {
      throw ArgumentError('Parcelamento deve ser entre 1 e 3 vezes.');
    }

    return AppDatabase.instance.createSale(
      TicketSaleModel(
        buyerName: buyerName,
        buyerPhone: buyerPhone,
        ticketQuantity: ticketQuantity,
        totalAmount: totalAmount,
        installments: installments,
        sellerUsername: sellerUsername,
        createdAt: DateTime.now().toIso8601String(),
        receivedAmount: 0,
        paymentStatus: 'pendente',
      ),
    );
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
        ),
      );
    }
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
        final receiptMap = await AppDatabase.instance.getReceiptMapById(entityId);
        if (receiptMap != null) {
          await _syncService.upsertRecibo(receiptMap);
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

    for (final sale in remoteSales) {
      await AppDatabase.instance.upsertSaleFromRemote(sale);
    }
    for (final receipt in remoteReceipts) {
      await AppDatabase.instance.upsertReceiptFromRemote(receipt);
    }

    return SyncSummary(
      sentEvents: sentEvents,
      receivedSales: remoteSales.length,
      receivedReceipts: remoteReceipts.length,
    );
  }
}
