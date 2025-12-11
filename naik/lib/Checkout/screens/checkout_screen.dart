import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/order_request.dart';
import '../services/checkout_service.dart';
import 'checkout_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String productId;
  final String productTitle;
  final double productPrice;
  final int initialQuantity;

  const CheckoutScreen({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.productPrice,
    this.initialQuantity = 1,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();
  int qty = 1;
  String payment = 'EWALLET';
  String shipping = 'BIASA';
  bool insurance = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    qty = widget.initialQuantity;
  }

  Future<void> _placeOrder() async {
    setState(() => loading = true);

    final req = OrderRequest(
      productId: widget.productId,
      quantity: qty,
      address: addressCtrl.text.isNotEmpty ? addressCtrl.text : 'Alamat default',
      paymentMethod: payment,
      shippingType: shipping,
      insurance: insurance,
      note: noteCtrl.text,
    );

    final res = await CheckoutService.submitOrder(req);

    setState(() => loading = false);

    if (res.success) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CheckoutSuccessScreen(
            orderId: res.orderId ?? '-',
            total: res.total ?? '0',
            productName: res.productName ?? widget.productTitle,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout gagal: ${res.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.productPrice * qty;
    double shippingCost = 0;
    if (shipping == 'CEPAT') shippingCost = 10000;
    if (shipping == 'SAME_DAY') shippingCost = 20000;
    final insuranceCost = insurance ? 5000 : 0;
    final total = subtotal + shippingCost + insuranceCost;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            Text(widget.productTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Harga: Rp ${widget.productPrice.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(onPressed: () => setState(() { if (qty>1) qty--; }), icon: const Icon(Icons.remove)),
                Text(qty.toString(), style: const TextStyle(fontSize: 18)),
                IconButton(onPressed: () => setState(() { qty++; }), icon: const Icon(Icons.add)),
                const Spacer(),
                Text('Subtotal: Rp ${subtotal.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Alamat pengiriman'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: payment,
              items: const [
                DropdownMenuItem(value: 'EWALLET', child: Text('E-Wallet')),
                DropdownMenuItem(value: 'COD', child: Text('Cash on Delivery')),
                DropdownMenuItem(value: 'TRANSFER', child: Text('Transfer Bank')),
                DropdownMenuItem(value: 'CREDIT', child: Text('Kartu Kredit')),
              ],
              onChanged: (v) => setState(() => payment = v ?? payment),
              decoration: const InputDecoration(labelText: 'Metode pembayaran'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: shipping,
              items: const [
                DropdownMenuItem(value: 'BIASA', child: Text('Biasa (2-4 hari)')),
                DropdownMenuItem(value: 'CEPAT', child: Text('Cepat (1-2 hari)')),
                DropdownMenuItem(value: 'SAME_DAY', child: Text('Same Day')),
              ],
              onChanged: (v) => setState(() => shipping = v ?? shipping),
              decoration: const InputDecoration(labelText: 'Tipe pengiriman'),
            ),
            CheckboxListTile(
              title: const Text('Asuransi (+Rp5.000)'),
              value: insurance,
              onChanged: (v) => setState(() => insurance = v ?? false),
            ),
            const SizedBox(height: 12),
            Text('Total: Rp ${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading ? null : _placeOrder,
              child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}
