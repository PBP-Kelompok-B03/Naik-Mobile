import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:naik/models/product_entry.dart';
import 'package:naik/config/app_config.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  final ProductEntry product;

  const CheckoutPage({super.key, required this.product});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  String shippingType = 'REGULER';
  bool insurance = false;

  int get shippingCost {
    switch (shippingType) {
      case 'NEXTDAY':
        return 10000;
      case 'SAMEDAY':
        return 15000;
      default:
        return 0;
    }
  }

  int get insuranceCost => insurance ? 5000 : 0;

  int get totalPrice =>
      widget.product.price.toInt() + shippingCost + insuranceCost;

  Future<void> placeOrder(CookieRequest request) async {
    if (!request.loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login terlebih dahulu")),
      );
      return;
    }

    final response = await request.post(
      "${AppConfig.baseUrl}/checkout/api/place-order/",
      {
        "product_id": widget.product.id.toString(),
        "quantity": "1",
        "address": _addressController.text,
        "payment_method": "EWALLET",
        "shipping_type": shippingType,
        "insurance": insurance.toString(),
        "note": _noteController.text,
      },
    );

    if (response["status"] == "success" && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderSuccessPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response["message"] ?? "Checkout gagal"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text("Rp ${widget.product.price.toStringAsFixed(0)}"),

            const Divider(height: 32),

            const Text("Alamat Pengiriman",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: "Masukkan alamat lengkap",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            const Text("Catatan untuk Penjual",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: "Contoh: Tolong dibungkus rapi",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            const Text("Pengiriman",
                style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: shippingType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                    value: 'REGULER', child: Text('Reguler (+0)')),
                DropdownMenuItem(
                    value: 'NEXTDAY', child: Text('Next Day (+10.000)')),
                DropdownMenuItem(
                    value: 'SAMEDAY', child: Text('Same Day (+15.000)')),
              ],
              onChanged: (v) => setState(() => shippingType = v!),
            ),

            SwitchListTile(
              value: insurance,
              onChanged: (v) => setState(() => insurance = v),
              title: const Text("Asuransi (+5.000)"),
            ),

            const Divider(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "TOTAL",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rp $totalPrice",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => placeOrder(request),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  "PLACE ORDER",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
