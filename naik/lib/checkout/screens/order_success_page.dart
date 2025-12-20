import 'package:flutter/material.dart';
import 'order_list_page.dart';

class OrderSuccessPage extends StatelessWidget {
  final String orderId;
  final String productName;
  final String totalPrice;

  const OrderSuccessPage({
    super.key,
    required this.orderId,
    required this.productName,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 80),
                const SizedBox(height: 16),
                const Text(
                  "Pembayaran Berhasil!",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _row("ID Pesanan", "#$orderId"),
                _row("Produk", productName),
                _row("Total", "Rp$totalPrice",
                    valueColor: Colors.greenAccent),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OrderListPage()),
                            (route) => false,
                      );
                    },
                    child: const Text("LIHAT PESANAN"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  color: valueColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
