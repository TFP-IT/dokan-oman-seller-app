import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

class MuskilaSellerEarningsScreen extends StatefulWidget {
  const MuskilaSellerEarningsScreen({super.key});

  @override
  State<MuskilaSellerEarningsScreen> createState() =>
      _MuskilaSellerEarningsScreenState();
}

class _MuskilaSellerEarningsScreenState
    extends State<MuskilaSellerEarningsScreen> {
  MuskilaSellerProfile? _profile;
  List<MuskilaSellerBooking> _completedBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await MuskilaSellerApi.instance.getProfile();
    final b = await MuskilaSellerApi.instance.getBookings(refresh: true);
    if (mounted) {
      setState(() {
        _profile = p;
        _completedBookings = b.where((it) => it.step == 4).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: muskilaAppBar(context, "Earnings & Escrow"),
      body: _isLoading || p == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: MyTheme.navy,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Gradient Wallet Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          MyTheme.navy_deep,
                          MyTheme.navy,
                          Color(0xFF123B7D),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(MyTheme.radius_card),
                      boxShadow: const [
                        BoxShadow(
                          color: MyTheme.app_accent_shado,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -24,
                          top: -24,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Available for payout",
                                    style: AppTheme.body(
                                      size: 13,
                                      color:
                                          Colors.white.withValues(alpha: 0.78),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: MyTheme.amber,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "WEEKLY PAYOUT",
                                      style: AppTheme.body(
                                        size: 10,
                                        weight: FontWeight.w800,
                                        color: MyTheme.navy_deep,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                muskilaMoney(p.availableBalance),
                                style: AppTheme.figure(34, color: Colors.white),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.trending_up_rounded,
                                        size: 16, color: MyTheme.amber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Lifetime earnings: ${muskilaMoney(p.totalEarnings)}",
                                        style: AppTheme.body(
                                            size: 13,
                                            weight: FontWeight.w600,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Escrow & Completed Stat Row
                  Row(
                    children: [
                      Expanded(
                        child: _box(
                          Icons.lock_outline_rounded,
                          MyTheme.amber_soft,
                          MyTheme.amber_ink,
                          "Locked in Escrow",
                          muskilaMoney(p.pendingEscrow),
                          "Released on job sign-off",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _box(
                          Icons.verified_outlined,
                          const Color(0xFFE2F3EC),
                          MyTheme.green,
                          "Completed Jobs",
                          "${p.jobsCompleted} jobs",
                          "Rating: ${p.rating} ★ (${p.reviewsCount})",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),
                  Text(
                    "Recent Releases",
                    style: AppTheme.body(
                      size: 17,
                      weight: FontWeight.w700,
                      color: MyTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_completedBookings.isEmpty)
                    MuskilaCard(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          "No releases yet.",
                          style: AppTheme.body(
                              size: 13, color: MyTheme.medium_grey),
                        ),
                      ),
                    )
                  else
                    ..._completedBookings.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MuskilaCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              const MuskilaIconBadge(
                                icon: Icons.check_rounded,
                                bg: Color(0xFFE2F3EC),
                                fg: MyTheme.green,
                                size: 38,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      b.serviceTitle,
                                      style: AppTheme.body(
                                        size: 14,
                                        weight: FontWeight.w600,
                                        color: MyTheme.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "${b.bookingNumber} • ${b.customerName}",
                                      style: AppTheme.body(
                                          size: 12, color: MyTheme.dark_grey),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "+${muskilaMoney(b.price)}",
                                style: AppTheme.figure(15, color: MyTheme.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _box(
    IconData icon,
    Color bg,
    Color fg,
    String title,
    String value,
    String sub,
  ) =>
      MuskilaCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MuskilaIconBadge(icon: icon, bg: bg, fg: fg, size: 36, iconSize: 18),
            const SizedBox(height: 10),
            Text(title,
                style: AppTheme.body(size: 12, color: MyTheme.medium_grey)),
            const SizedBox(height: 2),
            Text(value, style: AppTheme.figure(18, color: MyTheme.ink)),
            const SizedBox(height: 4),
            Text(sub,
                style: AppTheme.body(size: 11.5, color: MyTheme.dark_grey)),
          ],
        ),
      );
}
