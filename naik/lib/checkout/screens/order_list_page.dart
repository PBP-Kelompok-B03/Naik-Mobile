import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../../config/app_config.dart';
import '../../widgets/left_drawer.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  Future<List<dynamic>> fetchOrders(CookieRequest request) async {
    final response =
    await request.get("${AppConfig.baseUrl}/checkout/api/orders/");
    return response is List ? response : [];
  }

  Color statusColor(String status) {
    switch (status) {
      case "PAID":
        return Colors.greenAccent;
      case "PENDING":
        return Colors.orangeAccent;
      case "SHIPPED":
        return Colors.blueAccent;
      case "COMPLETED":
        return Colors.tealAccent;
      default:
        return Colors.redAccent;
    }
  }

  String safe(dynamic v, [String fallback = "-"]) {
    if (v == null) return fallback;
    return v.toString().isEmpty ? fallback : v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Pesanan Saya"),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: const LeftDrawer(),
      body: FutureBuilder<List<dynamic>>(
        future: fetchOrders(request),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada pesanan",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index] as Map<String, dynamic>;

              /// ✅ FIX UTAMA ADA DI SINI
              final items = order['items'] as List<dynamic>? ?? [];
              final item = items.isNotEmpty ? items.first : null;

              final productName = safe(item?['product_name']);
              final quantity = safe(item?['quantity'], "0");

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "#${safe(order['id'])}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor(order['status'])
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            safe(order['status']),
                            style: TextStyle(
                              color: statusColor(order['status']),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24),

                    /// PRODUK
                    _row("Produk", productName, bold: true),
                    _row("Jumlah", "x $quantity"),

                    const SizedBox(height: 12),

                    /// KOMENTAR PLACEHOLDER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF232323),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: const Text(
                        "💬 Komentar & ulasan akan ditampilkan di sini",
                        style: TextStyle(
                            color: Colors.white38,
                            fontStyle: FontStyle.italic),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),

                    /// META
                    _row("Pembayaran", safe(order['payment_method'])),
                    _row("Pengiriman", safe(order['shipping_type'])),
                    _row("Asuransi",
                        order['insurance'] == true ? "Ya" : "Tidak"),

                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),

                    /// FOOTER
                    _row("TOTAL", "Rp ${safe(order['total_price'])}",
                        bold: true,
                        valueColor: Colors.greenAccent),
                    const SizedBox(height: 6),
                    Text(
                      safe(order['created_at']),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54)),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontWeight:
                  bold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
