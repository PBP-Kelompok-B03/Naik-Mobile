import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CheckoutSummary extends StatelessWidget {
  final List<CartItem> items;
  final double shipping;
  final double insurance;
  final double discount;

  const CheckoutSummary({
    super.key,
    required this.items,
    this.shipping = 0.0,
    this.insurance = 0.0,
    this.discount = 0.0,
  });

  double get subtotal => items.fold(0.0, (s, it) => s + it.subtotal);
  double get total => subtotal + shipping + insurance - discount;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subtotal: Rp ${subtotal.toStringAsFixed(0)}'),
            const SizedBox(height: 6),
            Text('Ongkir: Rp ${shipping.toStringAsFixed(0)}'),
            const SizedBox(height: 6),
            Text('Asuransi: Rp ${insurance.toStringAsFixed(0)}'),
            const Divider(),
            Text('Total: Rp ${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
