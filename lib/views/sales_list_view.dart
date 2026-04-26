import 'package:cangaia_de_jegue/controllers/sales_controller.dart';
import 'package:cangaia_de_jegue/models/ticket_sale_model.dart';
import 'package:cangaia_de_jegue/views/sale_detail_view.dart';
import 'package:flutter/material.dart';

class SalesListView extends StatefulWidget {
  const SalesListView({super.key});

  @override
  State<SalesListView> createState() => _SalesListViewState();
}

class _SalesListViewState extends State<SalesListView> {
  final _salesController = SalesController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TicketSaleModel> _applyFilter(
    List<TicketSaleModel> sales,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return sales;

    return sales
        .where(
          (sale) => sale.buyerName.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de vendas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Filtrar por nome do comprador',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<TicketSaleModel>>(
                future: _salesController.getSales(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredSales = _applyFilter(
                    snapshot.data!,
                    _searchController.text,
                  );

                  if (filteredSales.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma venda encontrada para o filtro.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredSales.length,
                    itemBuilder: (context, index) {
                      final sale = filteredSales[index];
                      return Card(
                        child: ListTile(
                          onTap: () async {
                            final result = await Navigator.of(context).push<String>(
                              MaterialPageRoute(
                                builder: (_) => SaleDetailView(sale: sale),
                              ),
                            );
                            if (result != null && mounted) {
                              final message = result == 'updated'
                                  ? 'Venda atualizada com sucesso.'
                                  : 'Venda excluida com sucesso.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                              setState(() {});
                            }
                          },
                          title: Text(sale.buyerName),
                          subtitle: Text(
                            'Vendido por: ${sale.sellerUsername}\n'
                            'Quantidade de ingressos: ${sale.ticketQuantity}\n'
                            'Status: ${sale.paymentStatus}',
                          ),
                          trailing: Text(
                            'R\$ ${sale.totalAmount.toStringAsFixed(2)}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
