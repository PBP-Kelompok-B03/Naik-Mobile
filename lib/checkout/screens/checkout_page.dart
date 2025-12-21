import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:naik/models/product_entry.dart';
import 'package:naik/config/app_config.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  final ProductEntry product;
  final int quantity;

  const CheckoutPage({
    super.key,
    required this.product,
    required this.quantity,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  String paymentMethod = 'EWALLET';
  String shippingType = 'REGULER';
  bool insurance = false;

  int get shippingCost {
    switch (shippingType) {
      case 'NEXTDAY':
        return 10000;
      case 'SAMEDAY':
        return 20000;
      default:
        return 0;
    }
  }

  int get insuranceCost => insurance ? 5000 : 0;

  int get baseTotal =>
      widget.product.price.toInt() * widget.quantity;

  int get totalPrice =>
      baseTotal + shippingCost + insuranceCost;

  String rupiah(int value) =>
      value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
      );

  Future<void> placeOrder(CookieRequest request) async {
    if (!request.loggedIn) return;

    final response = await request.post(
      "${AppConfig.baseUrl}/checkout/api/place-order/",
      {
        "product_id": widget.product.id.toString(),
        "quantity": widget.quantity.toString(),
        "address": _addressController.text,
        "payment_method": paymentMethod,
        "shipping_type": shippingType,
        "insurance": insurance.toString(),
        "note": _noteController.text,
      },
    );

    if (response["status"] == "success" && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessPage(
            orderId: response["order_id"].toString(),
            productName: widget.product.title,
            totalPrice: rupiah(totalPrice),
          ),
        ),
      );
    }
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget card({required Widget child}) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text("Checkout"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// ================= RINGKASAN =================
            card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle("Ringkasan Pesanan"),
                  Text(
                    widget.product.title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _row("Harga", "Rp ${rupiah(widget.product.price.toInt())}"),
                  _row("Jumlah", "x ${widget.quantity}"),
                  const Divider(color: Colors.white24),
                  _row(
                    "Subtotal",
                    "Rp ${rupiah(baseTotal)}",
                    bold: true,
                  ),
                ],
              ),
            ),

            /// ================= ALAMAT =================
            card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle("Alamat Pengiriman"),
                  TextField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Masukkan alamat lengkap"),
                  ),
                ],
              ),
            ),

            /// ================= PENGIRIMAN =================
            card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle("Pengiriman & Pembayaran"),

                  DropdownButtonFormField<String>(
                    value: shippingType,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Jenis Pengiriman"),
                    items: const [
                      DropdownMenuItem(value: 'REGULER', child: Text('Biasa (Gratis)')),
                      DropdownMenuItem(value: 'NEXTDAY', child: Text('Cepat (+10.000)')),
                      DropdownMenuItem(value: 'SAMEDAY', child: Text('Same Day (+20.000)')),
                    ],
                    onChanged: (v) => setState(() => shippingType = v!),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Metode Pembayaran"),
                    items: const [
                      DropdownMenuItem(value: 'COD', child: Text('Cash on Delivery')),
                      DropdownMenuItem(value: 'TRANSFER', child: Text('Transfer Bank')),
                      DropdownMenuItem(value: 'EWALLET', child: Text('E-Wallet')),
                    ],
                    onChanged: (v) => setState(() => paymentMethod = v!),
                  ),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      "Asuransi (+5.000)",
                      style: TextStyle(color: Colors.white70),
                    ),
                    value: insurance,
                    onChanged: (v) => setState(() => insurance = v),
                  ),
                ],
              ),
            ),

            /// ================= CATATAN =================
            card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionTitle("Catatan"),
                  TextField(
                    controller: _noteController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: _inputDecoration("Contoh: tolong dibungkus rapi"),
                  ),
                ],
              ),
            ),

            /// ================= TOTAL =================
            card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "TOTAL BAYAR",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Rp ${rupiah(totalPrice)}",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// ================= BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => placeOrder(request),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                child: const Text("BAYAR SEKARANG"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String left, String right, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            right,
            style: TextStyle(
              color: Colors.white,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
