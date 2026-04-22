import 'package:cangaia_de_jegue/models/payment_receipt_model.dart';
import 'package:cangaia_de_jegue/models/ticket_sale_model.dart';
import 'package:cangaia_de_jegue/models/user_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const String _databaseName = 'cangaia_de_jegue.db';
  static const String _pendingSyncTable = 'eventos_sincronizacao_pendentes';
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario TEXT UNIQUE NOT NULL,
            senha TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE vendas_ingressos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome_comprador TEXT NOT NULL,
            quantidade_ingressos INTEGER NOT NULL,
            valor_total REAL NOT NULL,
            parcelamento INTEGER NOT NULL,
            usuario_vendedor TEXT NOT NULL,
            criado_em TEXT NOT NULL,
            valor_recebido REAL NOT NULL DEFAULT 0,
            status_pagamento TEXT NOT NULL DEFAULT 'pendente',
            recebido_em TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE recibos_pagamento(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            venda_id INTEGER NOT NULL,
            valor REAL NOT NULL,
            recebido_em TEXT NOT NULL,
            FOREIGN KEY(venda_id) REFERENCES vendas_ingressos(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE eventos_sincronizacao_pendentes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tipo_entidade TEXT NOT NULL,
            id_entidade INTEGER,
            operacao TEXT NOT NULL,
            carga TEXT,
            criado_em TEXT NOT NULL,
            sincronizado_em TEXT
          )
        ''');

        await db.insert('usuarios', const UserModel(id: 1, username: 'Elana', password: 'cangaiadejegue').toMap());
        await db.insert('usuarios', const UserModel(id: 2, username: 'William', password: 'cangaiadejegue').toMap());
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE pending_sync_events(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              entity_type TEXT NOT NULL,
              entity_id INTEGER,
              operation TEXT NOT NULL,
              payload TEXT,
              created_at TEXT NOT NULL,
              synced_at TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          await _migrateTableNamesToPortuguese(db);
        }
      },
    );
  }

  Future<UserModel?> authenticate(String username, String password) async {
    final db = await database;
    final rows = await db.query(
      'usuarios',
      where: 'usuario = ? AND senha = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<int> createSale(TicketSaleModel sale) async {
    final db = await database;
    final saleId = await db.insert('vendas_ingressos', sale.toMap());
    await _enqueueSyncEvent(
      entityType: 'vendas_ingressos',
      entityId: saleId,
      operation: 'create',
    );
    return saleId;
  }

  Future<List<TicketSaleModel>> listSales() async {
    final db = await database;
    final rows = await db.query('vendas_ingressos', orderBy: 'id DESC');
    return rows.map(TicketSaleModel.fromMap).toList();
  }

  Future<int> updateSale(TicketSaleModel sale) async {
    final db = await database;
    final updatedRows = await db.update(
      'vendas_ingressos',
      sale.toMap(),
      where: 'id = ?',
      whereArgs: [sale.id],
    );
    if (sale.id != null && updatedRows > 0) {
      await _enqueueSyncEvent(
        entityType: 'vendas_ingressos',
        entityId: sale.id,
        operation: 'update',
      );
    }
    return updatedRows;
  }

  Future<int> deleteSale(int id) async {
    final db = await database;
    await db.delete(
      'recibos_pagamento',
      where: 'venda_id = ?',
      whereArgs: [id],
    );
    final deletedRows = await db.delete(
      'vendas_ingressos',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deletedRows > 0) {
      await _enqueueSyncEvent(
        entityType: 'vendas_ingressos',
        entityId: id,
        operation: 'delete',
      );
    }
    return deletedRows;
  }

  Future<int> addReceipt(PaymentReceiptModel receipt) async {
    final db = await database;
    final receiptId = await db.insert('recibos_pagamento', receipt.toMap());
    await _enqueueSyncEvent(
      entityType: 'recibos_pagamento',
      entityId: receiptId,
      operation: 'create',
    );
    return receiptId;
  }

  Future<List<PaymentReceiptModel>> listReceiptsBySale(int saleId) async {
    final db = await database;
    final rows = await db.query(
      'recibos_pagamento',
      where: 'venda_id = ?',
      whereArgs: [saleId],
      orderBy: 'id DESC',
    );
    return rows.map(PaymentReceiptModel.fromMap).toList();
  }

  Future<int> countPendingSyncEvents() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $_pendingSyncTable WHERE sincronizado_em IS NULL',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<List<Map<String, Object?>>> listPendingSyncEvents() async {
    final db = await database;
    return db.query(
      _pendingSyncTable,
      where: 'sincronizado_em IS NULL',
      orderBy: 'id ASC',
    );
  }

  Future<Map<String, Object?>?> getSaleMapById(int id) async {
    final db = await database;
    final rows = await db.query(
      'vendas_ingressos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, Object?>?> getReceiptMapById(int id) async {
    final db = await database;
    final rows = await db.query(
      'recibos_pagamento',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> markSyncEventAsSynced(int id) async {
    final db = await database;
    await db.update(
      _pendingSyncTable,
      {'sincronizado_em': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> upsertSaleFromRemote(Map<String, Object?> saleMap) async {
    final db = await database;
    return db.insert(
      'vendas_ingressos',
      saleMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> upsertReceiptFromRemote(Map<String, Object?> receiptMap) async {
    final db = await database;
    return db.insert(
      'recibos_pagamento',
      receiptMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _enqueueSyncEvent({
    required String entityType,
    required int? entityId,
    required String operation,
    String? payload,
  }) async {
    final db = await database;
    await db.insert(_pendingSyncTable, {
      'tipo_entidade': entityType,
      'id_entidade': entityId,
      'operacao': operation,
      'carga': payload,
      'criado_em': DateTime.now().toIso8601String(),
      'sincronizado_em': null,
    });
  }

  Future<void> _migrateTableNamesToPortuguese(Database db) async {
    if (await _tableExists(db, 'users')) {
      await db.execute('ALTER TABLE users RENAME TO usuarios');
      await db.execute('ALTER TABLE usuarios RENAME COLUMN username TO usuario');
      await db.execute('ALTER TABLE usuarios RENAME COLUMN password TO senha');
    }

    if (await _tableExists(db, 'ticket_sales')) {
      await db.execute('ALTER TABLE ticket_sales RENAME TO vendas_ingressos');
      await db.execute(
        'ALTER TABLE vendas_ingressos RENAME COLUMN buyer_name TO nome_comprador',
      );
      await db.execute(
        'ALTER TABLE vendas_ingressos RENAME COLUMN ticket_quantity TO quantidade_ingressos',
      );
      await db.execute(
        'ALTER TABLE vendas_ingressos RENAME COLUMN total_amount TO valor_total',
      );
      await db.execute(
        'ALTER TABLE vendas_ingressos RENAME COLUMN installments TO parcelamento',
      );
      await db.execute(
        'ALTER TABLE vendas_ingressos RENAME COLUMN seller_username TO usuario_vendedor',
      );
      await db.execute(
        'ALTER TABLE vendas_ingressos RENAME COLUMN created_at TO criado_em',
      );
      await db.execute(
        'ALTER TABLE vendas_ingressos RENAME COLUMN received_amount TO valor_recebido',
      );
      await db.execute(
        'ALTER TABLE vendas_ingressos RENAME COLUMN payment_status TO status_pagamento',
      );
      await db.execute(
        'ALTER TABLE vendas_ingressos RENAME COLUMN received_at TO recebido_em',
      );
    }

    if (await _tableExists(db, 'payment_receipts')) {
      await db.execute('ALTER TABLE payment_receipts RENAME TO recibos_pagamento');
      await db.execute(
        'ALTER TABLE recibos_pagamento RENAME COLUMN sale_id TO venda_id',
      );
      await db.execute(
        'ALTER TABLE recibos_pagamento RENAME COLUMN received_at TO recebido_em',
      );
      await db.execute(
        'ALTER TABLE recibos_pagamento RENAME COLUMN amount TO valor',
      );
    }

    if (await _tableExists(db, 'pending_sync_events')) {
      await db.execute(
        'ALTER TABLE pending_sync_events RENAME TO eventos_sincronizacao_pendentes',
      );
      await db.execute(
        'ALTER TABLE eventos_sincronizacao_pendentes RENAME COLUMN entity_type TO tipo_entidade',
      );
      await db.execute(
        'ALTER TABLE eventos_sincronizacao_pendentes RENAME COLUMN entity_id TO id_entidade',
      );
      await db.execute(
        'ALTER TABLE eventos_sincronizacao_pendentes RENAME COLUMN operation TO operacao',
      );
      await db.execute(
        'ALTER TABLE eventos_sincronizacao_pendentes RENAME COLUMN payload TO carga',
      );
      await db.execute(
        'ALTER TABLE eventos_sincronizacao_pendentes RENAME COLUMN created_at TO criado_em',
      );
      await db.execute(
        'ALTER TABLE eventos_sincronizacao_pendentes RENAME COLUMN synced_at TO sincronizado_em',
      );
    }
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', tableName],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
