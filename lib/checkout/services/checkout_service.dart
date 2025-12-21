import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/checkout_response.dart';

class CheckoutService {
  static Future<CheckoutResponse> checkout({
    required CookieRequest request,
    required int productId,
    required int quantity,
    required String address,
    required String paymentMethod,
    required String shippingType,
    required bool insurance,
    required String note,
  }) async {
    final response = await request.postJson(
      "http://127.0.0.1:8000/checkout/api/checkout/",
      {
        "product_id": productId,
        "quantity": quantity,
        "address": address,
        "payment_method": paymentMethod,
        "shipping_type": shippingType,
        "insurance": insurance,
        "note": note,
      },
    );

    if (response["status"] == "success") {
      return CheckoutResponse.fromJson(response);
    } else {
      throw Exception(response["message"] ?? "Checkout gagal");
    }
  }
}
