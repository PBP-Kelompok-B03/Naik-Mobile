import 'package:flutter/material.dart';
import '../services/checkout_service.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  String html = '';
  bool loading = false;

  Future<void> _loadOrders() async {
    setState(() => loading = true);
    final res = await CheckoutService.fetchOrdersHtml();
    setState(() {
      html = res;
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    // Since your Django currently returns an HTML template for orders,
    // we show the raw HTML as text. Preferably add a JSON endpoint in Django for mobile.
    return Scaffold(
      appBar: AppBar(title: const Text('Order List')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: SelectableText(html.isNotEmpty ? html : 'No orders or failed to load.'),
      ),
    );
  }
}
