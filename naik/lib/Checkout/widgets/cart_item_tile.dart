import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onRemove;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const CartItemTile({
    super.key,
    required this.item,
    this.onRemove,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        title: Text(item.title),
        subtitle: Text('Harga: Rp ${item.price.toStringAsFixed(0)}'),
        leading: CircleAvatar(child: Text('${item.quantity}x')),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Rp ${item.subtotal.toStringAsFixed(0)}'),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onDecrement,
                  icon: const Icon(Icons.remove, size: 18),
                ),
                IconButton(
                  onPressed: onIncrement,
                  icon: const Icon(Icons.add, size: 18),
                ),
              ],
            )
          ],
        ),
        onLongPress: onRemove,
      ),
    );
  }
}
