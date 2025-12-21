// lib/auction/screens/auction_detail_page.dart
// Screen untuk menampilkan detail auction.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naik/auction/models/auction_entry.dart';
import 'package:naik/auction/services/auction_service.dart';
import 'package:naik/config/app_config.dart';
import 'package:naik/widgets/left_drawer.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class AuctionDetailPage extends StatefulWidget {
  final String auctionId;

  const AuctionDetailPage({
    super.key,
    required this.auctionId,
  });

  @override
  State<AuctionDetailPage> createState() => _AuctionDetailPageState();
}

class _AuctionDetailPageState extends State<AuctionDetailPage> {
  final AuctionService _auctionService = AuctionService(AppConfig.baseUrl);
  final TextEditingController _bidController = TextEditingController();
  bool _isPlacingBid = false;

  Future<AuctionDetail>? _auctionDetailFuture;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadAuctionDetail();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bidController.dispose();
    super.dispose();
  }

  void _loadAuctionDetail() {
    final request = context.read<CookieRequest>();
    setState(() {
      _auctionDetailFuture = _auctionService.fetchAuctionDetail(request, widget.auctionId);
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Trigger rebuild to update countdown
      });
    });
  }

  Future<void> _placeBid(AuctionDetail auctionDetail) async {
    final bidAmount = double.tryParse(_bidController.text.trim());
    if (bidAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bid amount')),
      );
      return;
    }

    if (bidAmount < auctionDetail.minBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Minimum bid is Rp ${auctionDetail.minBid.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}')),
      );
      return;
    }

    setState(() => _isPlacingBid = true);

    try {
      final request = context.read<CookieRequest>();
      final response = await _auctionService.placeBid(request, widget.auctionId, bidAmount);

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Bid placed successfully!')),
        );
        _bidController.clear();
        _loadAuctionDetail(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Failed to place bid')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while placing bid')),
      );
    } finally {
      setState(() => _isPlacingBid = false);
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'No end time';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  String _getCountdownText(String? endTimeString) {
    if (endTimeString == null) return 'No end time';

    try {
      final endTime = DateTime.parse(endTimeString);
      final now = DateTime.now();
      final difference = endTime.difference(now);

      if (difference.isNegative) {
        // Auction has ended, reload the page to show ended state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadAuctionDetail();
          }
        });
        return 'Ended';
      }

      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;

      final parts = <String>[];
      if (days > 0) parts.add('${days}d');
      if (hours > 0 || days > 0) parts.add('${hours}h');
      if (minutes > 0 || hours > 0 || days > 0) parts.add('${minutes}m');
      parts.add('${seconds}s');

      return parts.join(' ');
    } catch (e) {
      return 'Invalid time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Detail'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      drawer: const LeftDrawer(),
      body: FutureBuilder<AuctionDetail>(
        future: _auctionDetailFuture,
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
                    onPressed: _loadAuctionDetail,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final auctionDetail = snapshot.data!;
            final auction = auctionDetail.product;

            // Start countdown timer if auction is active
            if (auctionDetail.auctionActive && auction.auctionEndTime != null) {
              _startCountdownTimer();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auction Image
                  if (auction.thumbnail != null && auction.thumbnail!.isNotEmpty)
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(
                            auction.thumbnail!.startsWith('http')
                                ? auction.thumbnail!
                                : '${AppConfig.baseUrl}${auction.thumbnail}',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Auction Title
                  Text(
                    auction.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Category and Seller
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          auction.category,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      if (auction.sellerUsername != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          auction.sellerUsername!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Auction Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: auctionDetail.auctionActive ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          auctionDetail.auctionActive ? Icons.access_time : Icons.check_circle,
                          color: auctionDetail.auctionActive ? Colors.green[800] : Colors.red[800],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          auctionDetail.auctionActive ? 'Auction Active' : 'Auction Ended',
                          style: TextStyle(
                            color: auctionDetail.auctionActive ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Time Remaining / End Time
                  if (auction.auctionEndTime != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: auctionDetail.auctionActive ? Colors.blue[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: auctionDetail.auctionActive ? Colors.blue[200]! : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            auctionDetail.auctionActive ? Icons.timer : Icons.schedule,
                            size: 16,
                            color: auctionDetail.auctionActive ? Colors.blue[700] : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auctionDetail.auctionActive ? 'Time Remaining:' : 'Ended:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: auctionDetail.auctionActive ? Colors.blue[700] : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  auctionDetail.auctionActive
                                    ? _getCountdownText(auction.auctionEndTime!)
                                    : _formatDateTime(auction.auctionEndTime),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: auctionDetail.auctionActive ? Colors.blue[800] : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Current Bid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Highest Bid',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(auctionDetail.currentHighestBid),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (auctionDetail.auctionActive) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Minimum next bid: ${_formatCurrency(auctionDetail.minBid)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Winner Status
                  if (auctionDetail.isWinner)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.emoji_events, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Congratulations! You won this auction!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Checkout Button for Winner
                  if (auctionDetail.isWinner) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to checkout page for this auction
                          Navigator.pushNamed(
                            context,
                            '/checkout',
                            arguments: {
                              'productId': auction.id,
                              'isAuction': true,
                              'auctionWinner': true,
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Place Bid Section
                  if (auctionDetail.auctionActive && !auctionDetail.isWinner) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Place Your Bid',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bidController,
                            decoration: InputDecoration(
                              labelText: 'Bid Amount',
                              hintText: 'Enter amount in Rupiah',
                              prefixText: 'Rp ',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _isPlacingBid
                              ? null
                              : () => _placeBid(auctionDetail),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          child: _isPlacingBid
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Place Bid'),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Bid History
                  const Text(
                    'Bid History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (auctionDetail.bids.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No bids yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: auctionDetail.bids.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final bid = auctionDetail.bids[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.black,
                            child: Text(
                              bid.userUsername.isNotEmpty ? bid.userUsername[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(bid.userUsername),
                          subtitle: Text(_formatDateTime(bid.createdAt)),
                          trailing: Text(
                            _formatCurrency(bid.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}