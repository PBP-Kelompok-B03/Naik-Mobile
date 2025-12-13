// To parse this JSON data, do
//
//     final productEntry = productEntryFromJson(jsonString);

import 'dart:convert';
import 'package:naik/config/app_config.dart';

List<ProductEntry> productEntryFromJson(String str) => List<ProductEntry>.from(json.decode(str).map((x) => ProductEntry.fromJson(x)));

String productEntryToJson(List<ProductEntry> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ProductEntry {
    String id;
    String title;
    int price;
    String category;
    String thumbnail;
    int countSold;
    int stock;
    bool isAuction;
    int? auctionIncrement;
    DateTime? auctionEndTime;
    int? userId;

    ProductEntry({
        required this.id,
        required this.title,
        required this.price,
        required this.category,
        required this.thumbnail,
        required this.countSold,
        required this.stock,
        required this.isAuction,
        this.auctionIncrement,
        this.auctionEndTime,
        this.userId,
    });

    factory ProductEntry.fromJson(Map<String, dynamic> json) {
        // Django serializer wraps data in "model", "pk", and "fields"
        var fields = json["fields"] ?? json;
        var pk = json["pk"] ?? json["id"] ?? '';

        return ProductEntry(
            id: pk.toString(),
            title: fields["title"] ?? '',
            price: fields["price"] is String
                ? int.tryParse(fields["price"]) ?? 0
                : (fields["price"] ?? 0),
            category: fields["category"] ?? '',
            thumbnail: fields["thumbnail"] ?? '',
            countSold: fields["count_sold"] ?? 0,
            stock: fields["stock"] ?? 0,
            isAuction: fields["is_auction"] ?? false,
            auctionIncrement: fields["auction_increment"] is String
                ? int.tryParse(fields["auction_increment"])
                : fields["auction_increment"],
            auctionEndTime: fields["auction_end_time"] != null
                ? DateTime.tryParse(fields["auction_end_time"])
                : null,
            userId: fields["user"],
        );
    }

    Map<String, dynamic> toJson() => {
        "pk": id,
        "fields": {
            "title": title,
            "price": price,
            "category": category,
            "thumbnail": thumbnail,
            "count_sold": countSold,
            "stock": stock,
            "is_auction": isAuction,
            "auction_increment": auctionIncrement,
            "auction_end_time": auctionEndTime?.toIso8601String(),
            "user": userId,
        }
    };

    // Helper method to get the full image URL
    String getImageUrl() {
        if (thumbnail.isEmpty) return '';

        // If thumbnail is already a full URL, return it
        if (thumbnail.startsWith('http://') || thumbnail.startsWith('https://')) {
            return thumbnail;
        }

        // Remove 'image/products/temp/' prefix if it exists (from Django ImageField upload_to)
        String cleanPath = thumbnail;
        if (cleanPath.startsWith('image/products/temp/')) {
            cleanPath = cleanPath.replaceFirst('image/products/temp/', 'image/products/');
        }

        // Construct the static URL (images are in static/, not media/)
        return '${AppConfig.baseUrl}/static/$cleanPath';
    }

    // Helper method for web platform to use proxy (avoids CORS issues)
    String getProxiedImageUrl() {
        final staticUrl = getImageUrl();
        if (staticUrl.isEmpty) return '';

        // Use proxy endpoint to bypass CORS on web
        return '${AppConfig.proxyImageEndpoint}?url=${Uri.encodeComponent(staticUrl)}';
    }
}
