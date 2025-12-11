import 'package:flutter/material.dart';

class CheckoutSuccessScreen extends StatelessWidget {
  final String orderId;
  final String total;
  final String productName;

  const CheckoutSuccessScreen({
    super.key,
    required this.orderId,
    required this.total,
    this.productName = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Sukses')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 96),
            const SizedBox(height: 16),
            Text('Order #$orderId', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Produk: $productName'),
            const SizedBox(height: 8),
            Text('Total: Rp $total', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Kembali ke Home'),
            )
          ],
        ),
      ),
    );
  }
}
