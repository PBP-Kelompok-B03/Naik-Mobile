import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../widgets/cart_item_tile.dart';
import 'checkout_screen.dart';
import '../widgets/checkout_summary.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> initialItems;

  const CartScreen({super.key, required this.initialItems});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> items;

  @override
  void initState() {
    super.initState();
    items = List.from(widget.initialItems);
  }

  void _removeItem(CartItem item) {
    setState(() {
      items.removeWhere((i) => i.id == item.id);
    });
  }

  void _increment(CartItem item) {
    setState(() {
      item.quantity += 1;
    });
  }

  void _decrement(CartItem item) {
    setState(() {
      if (item.quantity > 1) item.quantity -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shipping = 0.0;
    final insurance = items.any((i) => false) ? 5000.0 : 0.0; // placeholder
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Keranjang kosong'))
                : ListView(
              children: items.map((it) {
                return CartItemTile(
                  item: it,
                  onRemove: () => _removeItem(it),
                  onIncrement: () => _increment(it),
                  onDecrement: () => _decrement(it),
                );
              }).toList(),
            ),
          ),
          CheckoutSummary(items: items, shipping: shipping, insurance: insurance),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              onPressed: items.isEmpty
                  ? null
                  : () {
                // For simplicity only checkout first item (your Django view accepts single product flow)
                final first = items.first;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(
                      productId: first.id,
                      productTitle: first.title,
                      productPrice: first.price,
                      initialQuantity: first.quantity,
                    ),
                  ),
                );
              },
              child: const Text('Checkout'),
            ),
          )
        ],
      ),
    );
  }
}
