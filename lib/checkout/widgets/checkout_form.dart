import 'package:flutter/material.dart';

class CheckoutForm extends StatelessWidget {
  final TextEditingController addressController;
  final bool insurance;
  final Function(bool) onInsuranceChanged;

  const CheckoutForm({
    super.key,
    required this.addressController,
    required this.insurance,
    required this.onInsuranceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: addressController,
          decoration: const InputDecoration(
            labelText: "Alamat Pengiriman",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text("Tambahkan Asuransi (+Rp5.000)"),
          value: insurance,
          onChanged: onInsuranceChanged,
        ),
      ],
    );
  }
}
