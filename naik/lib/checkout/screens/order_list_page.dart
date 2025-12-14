import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../../config/app_config.dart';
import '../../widgets/left_drawer.dart'; // ⬅️ PASTIKAN INI ADA

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  Future<List<dynamic>> fetchOrders(CookieRequest request) async {
    final response = await request.get(
      "${AppConfig.baseUrl}/checkout/api/orders/",
    );

    // ✅ Kalau API balikin List → OK
    if (response is List) {
      return response;
    }

    // ❌ Kalau Unauthorized / error
    if (response is Map && response.containsKey("error")) {
      throw Exception(response["error"]);
    }

    throw Exception("Format data tidak sesuai");
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pesanan Saya"),
      ),
      drawer: const LeftDrawer(), // ✅ LEFT DRAWER TETAP ADA
      body: FutureBuilder<List<dynamic>>(
        future: fetchOrders(request),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text("Belum ada pesanan"));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text("Order #${order['id']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total: Rp ${order['total_price']}"),
                      Text("Status: ${order['status']}"),
                      Text("Tanggal: ${order['created_at']}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
