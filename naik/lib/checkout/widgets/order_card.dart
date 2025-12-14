import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  Color getStatusColor() {
    switch (order.status) {
      case "PAID":
        return Colors.green;
      case "PENDING":
        return Colors.orange;
      case "SHIPPED":
        return Colors.blue;
      case "COMPLETED":
        return Colors.teal;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order #${order.id}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            ...order.items.map((item) => Text(
                "${item.productName} x${item.quantity} — Rp${item.price}")),

            const Divider(),

            Text("Total: Rp${order.totalPrice}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("Pembayaran: ${order.paymentMethod}"),
            Text("Pengiriman: ${order.shippingType}"),
            Text("Asuransi: ${order.insurance ? 'Ya' : 'Tidak'}"),
            Text("Tanggal: ${order.createdAt}"),

            const SizedBox(height: 8),
            Chip(
              label: Text(order.status),
              backgroundColor: getStatusColor().withOpacity(0.2),
              labelStyle: TextStyle(color: getStatusColor()),
            ),
          ],
        ),
      ),
    );
  }
}
