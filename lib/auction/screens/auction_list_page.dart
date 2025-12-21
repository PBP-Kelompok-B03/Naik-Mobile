// lib/auction/screens/auction_list_page.dart
// Screen untuk menampilkan daftar auction.

import 'package:flutter/material.dart';
import 'package:naik/auction/models/auction_entry.dart';
import 'package:naik/auction/services/auction_service.dart';
import 'package:naik/auction/widgets/auction_card.dart';
import 'package:naik/auction/screens/auction_detail_page.dart';
import 'package:naik/config/app_config.dart';
import 'package:naik/widgets/left_drawer.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';

class AuctionListPage extends StatefulWidget {
  const AuctionListPage({super.key});

  @override
  State<AuctionListPage> createState() => _AuctionListPageState();
}

class _AuctionListPageState extends State<AuctionListPage> {
  final AuctionService _auctionService = AuctionService(AppConfig.baseUrl);

  Future<List<AuctionEntry>> _fetchAuctions(CookieRequest request) async {
    return await _auctionService.fetchAuctions(request);
  }

  @override
  Widget build(BuildContext context) {
    final request = context.read<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auctions'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      drawer: const LeftDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {}); // Trigger rebuild to refresh data
        },
        child: FutureBuilder<List<AuctionEntry>>(
          future: _fetchAuctions(request),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else {
              final auctions = snapshot.data ?? [];
              if (auctions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.gavel,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No auctions available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Check back later for new auctions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 2;
                      if (constraints.maxWidth > 1200) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth > 800) {
                        crossAxisCount = 2;
                      }

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: auctions.length,
                        itemBuilder: (context, index) {
                          final auction = auctions[index];
                          return AuctionCard(
                            auction: auction,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AuctionDetailPage(
                                    auctionId: auction.id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
}