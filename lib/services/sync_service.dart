import 'package:cangaia_de_jegue/config/neon_config.dart';
import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';

class SyncService {
  const SyncService();

  Future<List<Map<String, Object?>>> fetchVendas() async {
    return _fetchRows(
      'download de vendas',
      'SELECT * FROM vendas_ingressos ORDER BY id DESC',
    );
  }

  Future<List<Map<String, Object?>>> fetchRecibos() async {
    return _fetchRows(
      'download de recibos',
      'SELECT * FROM recibos_pagamento ORDER BY id DESC',
    );
  }

  Future<List<Map<String, Object?>>> fetchDespesas() async {
    return _fetchRows(
      'download de despesas',
      'SELECT * FROM despesas ORDER BY data_despesa DESC, id DESC',
    );
  }

  Future<void> upsertVenda(Map<String, Object?> venda) async {
    await _execute(
      'upsert de venda',
      Sql.named('''
INSERT INTO vendas_ingressos (
  id,
  nome_comprador,
  telefone_comprador,
  quantidade_ingressos,
  valor_total,
  parcelamento,
  usuario_vendedor,
  criado_em,
  valor_recebido,
  status_pagamento,
  recebido_em,
  camisa_entregue_em
) VALUES (
  @id,
  @nome_comprador,
  @telefone_comprador,
  @quantidade_ingressos,
  @valor_total,
  @parcelamento,
  @usuario_vendedor,
  @criado_em,
  @valor_recebido,
  @status_pagamento,
  @recebido_em,
  @camisa_entregue_em
)
ON CONFLICT (id) DO UPDATE SET
  nome_comprador = EXCLUDED.nome_comprador,
  telefone_comprador = EXCLUDED.telefone_comprador,
  quantidade_ingressos = EXCLUDED.quantidade_ingressos,
  valor_total = EXCLUDED.valor_total,
  parcelamento = EXCLUDED.parcelamento,
  usuario_vendedor = EXCLUDED.usuario_vendedor,
  criado_em = EXCLUDED.criado_em,
  valor_recebido = EXCLUDED.valor_recebido,
  status_pagamento = EXCLUDED.status_pagamento,
  recebido_em = EXCLUDED.recebido_em,
  camisa_entregue_em = EXCLUDED.camisa_entregue_em
'''),
      venda,
    );
  }

  Future<void> deleteVenda(int id) async {
    await _execute(
      'delete de venda',
      Sql.named('DELETE FROM vendas_ingressos WHERE id = @id'),
      {'id': id},
    );
  }

  Future<void> upsertRecibo(Map<String, Object?> recibo) async {
    await _execute(
      'upsert de recibo',
      Sql.named('''
INSERT INTO recibos_pagamento (
  id,
  venda_id,
  valor,
  recebido_em,
  forma_pagamento
) VALUES (
  @id,
  @venda_id,
  @valor,
  @recebido_em,
  @forma_pagamento
)
ON CONFLICT (id) DO UPDATE SET
  venda_id = EXCLUDED.venda_id,
  valor = EXCLUDED.valor,
  recebido_em = EXCLUDED.recebido_em,
  forma_pagamento = EXCLUDED.forma_pagamento
'''),
      recibo,
    );
  }

  Future<void> upsertDespesa(Map<String, Object?> despesa) async {
    await _execute(
      'upsert de despesa',
      Sql.named('''
INSERT INTO despesas (
  id,
  descricao,
  valor,
  data_despesa
) VALUES (
  @id,
  @descricao,
  @valor,
  @data_despesa
)
ON CONFLICT (id) DO UPDATE SET
  descricao = EXCLUDED.descricao,
  valor = EXCLUDED.valor,
  data_despesa = EXCLUDED.data_despesa
'''),
      despesa,
    );
  }

  Future<void> deleteDespesa(int id) async {
    await _execute(
      'delete de despesa',
      Sql.named('DELETE FROM despesas WHERE id = @id'),
      {'id': id},
    );
  }

  Future<List<Map<String, Object?>>> fetchTamanhosCamisa() async {
    return _fetchRows(
      'download de tamanhos de camisa',
      'SELECT * FROM tamanhos_camisa ORDER BY id ASC',
    );
  }

  /// Remove todos os tamanhos de uma venda no remoto e insere os novos.
  Future<void> replaceTamanhosCamisaBySale(
    int vendaId,
    List<Map<String, Object?>> tamanhos,
  ) async {
    await _withConnection((connection) async {
      await connection.runTx((session) async {
        await session.execute(
          Sql.named('DELETE FROM tamanhos_camisa WHERE venda_id = @venda_id'),
          parameters: {'venda_id': vendaId},
          ignoreRows: true,
        );

        for (final tamanho in tamanhos) {
          await _upsertTamanho(session, tamanho);
        }
      });
    });
    debugPrint('[SYNC] replace de tamanhos da venda $vendaId no Neon');
  }

  Future<List<Map<String, Object?>>> fetchPedidosCamisas() async {
    return _fetchRows(
      'download de pedidos de camisas',
      'SELECT * FROM pedidos_camisas ORDER BY criado_em DESC, id DESC',
    );
  }

  Future<void> upsertPedidoCamisa(Map<String, Object?> pedido) async {
    await _execute(
      'upsert de pedido de camisa',
      Sql.named('''
INSERT INTO pedidos_camisas (
  id,
  tamanho,
  quantidade,
  criado_em
) VALUES (
  @id,
  @tamanho,
  @quantidade,
  @criado_em
)
ON CONFLICT (id) DO UPDATE SET
  tamanho = EXCLUDED.tamanho,
  quantidade = EXCLUDED.quantidade,
  criado_em = EXCLUDED.criado_em
'''),
      pedido,
    );
  }

  Future<void> deletePedidoCamisa(int id) async {
    await _execute(
      'delete de pedido de camisa',
      Sql.named('DELETE FROM pedidos_camisas WHERE id = @id'),
      {'id': id},
    );
  }

  Future<List<Map<String, Object?>>> _fetchRows(
    String contexto,
    String sql,
  ) async {
    final result = await _withConnection((connection) {
      return connection.execute(sql);
    });
    debugPrint('[SYNC] $contexto no Neon -> ${result.length} registros');
    return result.map((row) => _normalizeRemoteMap(row.toColumnMap())).toList();
  }

  Future<void> _execute(
    String contexto,
    Sql sql,
    Map<String, Object?> parameters,
  ) async {
    await _withConnection((connection) {
      return connection.execute(sql, parameters: parameters, ignoreRows: true);
    });
    debugPrint('[SYNC] $contexto no Neon concluido');
  }

  Future<T> _withConnection<T>(
    Future<T> Function(Connection connection) action,
  ) async {
    final connection = await Connection.openFromUrl(
      NeonConfig.driverConnectionUrl,
    );
    try {
      return await action(connection);
    } catch (error, stackTrace) {
      debugPrint('[SYNC] Erro ao acessar Neon: $error');
      debugPrint('[SYNC] Stacktrace: $stackTrace');
      rethrow;
    } finally {
      await connection.close();
    }
  }

  Future<void> _upsertTamanho(
    Session session,
    Map<String, Object?> tamanho,
  ) async {
    await session.execute(
      Sql.named('''
INSERT INTO tamanhos_camisa (
  id,
  venda_id,
  tamanho,
  quantidade
) VALUES (
  @id,
  @venda_id,
  @tamanho,
  @quantidade
)
ON CONFLICT (id) DO UPDATE SET
  venda_id = EXCLUDED.venda_id,
  tamanho = EXCLUDED.tamanho,
  quantidade = EXCLUDED.quantidade
'''),
      parameters: tamanho,
      ignoreRows: true,
    );
  }

  Map<String, Object?> _normalizeRemoteMap(Map<String, dynamic> map) {
    final normalized = <String, Object?>{};
    for (final entry in map.entries) {
      normalized[entry.key] = _normalizeRemoteValue(entry.key, entry.value);
    }
    return normalized;
  }

  Object? _normalizeRemoteValue(String column, Object? value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (_numericColumns.contains(column) && value is String) {
      return double.parse(value);
    }

    return value;
  }

  static const _numericColumns = {'valor_total', 'valor_recebido', 'valor'};
}
