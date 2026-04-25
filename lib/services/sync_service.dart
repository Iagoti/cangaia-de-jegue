import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SyncService {
  static const String _urlProjeto = 'https://baqpfticrbesvnjgrlpb.supabase.co';
  static const String _chavePublica =
      'sb_publishable_Dgg38kqXSo2tjanu92rsnA_UsZlh8Ef';

  const SyncService();

  Future<List<Map<String, Object?>>> fetchVendas() async {
    final response = await http.get(
      Uri.parse('$_urlProjeto/rest/v1/vendas_ingressos?select=*'),
      headers: _headers(),
    );
    _checkResponse(
      response,
      contexto: 'download de vendas',
      endpoint: '/rest/v1/vendas_ingressos?select=*',
    );
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Map<String, Object?>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, Object?>>> fetchRecibos() async {
    final response = await http.get(
      Uri.parse('$_urlProjeto/rest/v1/recibos_pagamento?select=*'),
      headers: _headers(),
    );
    _checkResponse(
      response,
      contexto: 'download de recibos',
      endpoint: '/rest/v1/recibos_pagamento?select=*',
    );
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Map<String, Object?>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, Object?>>> fetchDespesas() async {
    final response = await http.get(
      Uri.parse('$_urlProjeto/rest/v1/despesas?select=*'),
      headers: _headers(),
    );
    _checkResponse(
      response,
      contexto: 'download de despesas',
      endpoint: '/rest/v1/despesas?select=*',
    );
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((item) => Map<String, Object?>.from(item as Map))
        .toList();
  }

  Future<void> upsertVenda(Map<String, Object?> venda) async {
    final endpoint = '/rest/v1/vendas_ingressos?on_conflict=id';
    final uri = Uri.parse('$_urlProjeto$endpoint');
    final response = await http.post(
      uri,
      headers: _headers(extra: {'Prefer': 'resolution=merge-duplicates'}),
      body: jsonEncode([venda]),
    );
    _checkResponse(response, contexto: 'upsert de venda', endpoint: endpoint);
  }

  Future<void> deleteVenda(int id) async {
    final response = await http.delete(
      Uri.parse('$_urlProjeto/rest/v1/vendas_ingressos?id=eq.$id'),
      headers: _headers(),
    );
    _checkResponse(
      response,
      contexto: 'delete de venda',
      endpoint: '/rest/v1/vendas_ingressos?id=eq.$id',
    );
  }

  Future<void> upsertRecibo(Map<String, Object?> recibo) async {
    final response = await http.post(
      Uri.parse('$_urlProjeto/rest/v1/recibos_pagamento?on_conflict=id'),
      headers: _headers(extra: {'Prefer': 'resolution=merge-duplicates'}),
      body: jsonEncode([recibo]),
    );
    _checkResponse(
      response,
      contexto: 'upsert de recibo',
      endpoint: '/rest/v1/recibos_pagamento?on_conflict=id',
    );
  }

  Future<void> upsertDespesa(Map<String, Object?> despesa) async {
    final response = await http.post(
      Uri.parse('$_urlProjeto/rest/v1/despesas?on_conflict=id'),
      headers: _headers(extra: {'Prefer': 'resolution=merge-duplicates'}),
      body: jsonEncode([despesa]),
    );
    _checkResponse(
      response,
      contexto: 'upsert de despesa',
      endpoint: '/rest/v1/despesas?on_conflict=id',
    );
  }

  Map<String, String> _headers({Map<String, String>? extra}) {
    return {
      'apikey': _chavePublica,
      'Authorization': 'Bearer $_chavePublica',
      'Content-Type': 'application/json',
      ...?extra,
    };
  }

  void _checkResponse(
    http.Response response, {
    required String contexto,
    required String endpoint,
  }) {
    debugPrint('[SYNC] $contexto -> ${response.statusCode} ($endpoint)');
    debugPrint('[SYNC] Resposta: ${response.body}');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception(
      'Erro na sincronizacao ($contexto). Status ${response.statusCode}: ${response.body}',
    );
  }
}
