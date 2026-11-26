import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_ui.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/muskila_seller_booking_detail.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

class MuskilaSellerBookingsScreen extends StatefulWidget {
  final String initialTab;
  final bool showBack;

  const MuskilaSellerBookingsScreen({
    super.key,
    this.initialTab = "active",
    this.showBack = true,
  });

  @override
  State<MuskilaSellerBookingsScreen> createState() =>
      _MuskilaSellerBookingsScreenState();
}

class _MuskilaSellerBookingsScreenState
    extends State<MuskilaSellerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<MuskilaSellerBooking> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab == "active" ? 0 : 1,
    );
    _refresh();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_items.isEmpty) setState(() => _loading = true);
    final list = await MuskilaSellerApi.instance.getBookings(refresh: true);
    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _items.where((b) => b.step < 4).length;
    final pastCount = _items.where((b) => b.step >= 4).length;

    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBack,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: AppTheme.lightStatusBar,
        shape: const Border(bottom: BorderSide(color: MyTheme.hairline)),
        iconTheme: const IconThemeData(color: MyTheme.ink),
        title: Text(
          "Service Bookings",
          style: AppTheme.body(size: 18, weight: FontWeight.w700, color: MyTheme.ink),
        ),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: MyTheme.navy,
          indicatorWeight: 3,
          labelColor: MyTheme.navy,
          unselectedLabelColor: MyTheme.medium_grey,
          labelStyle: AppTheme.body(size: 14, weight: FontWeight.w700),
          unselectedLabelStyle: AppTheme.body(size: 14, weight: FontWeight.w500),
          tabs: [
            Tab(text: "Active ($activeCount)"),
            Tab(text: "Past ($pastCount)"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _tabList(active: true),
                _tabList(active: false),
              ],
            ),
    );
  }

  Widget _tabList({required bool active}) {
    final filtered = active
        ? _items.where((b) => b.step < 4).toList()
        : _items.where((b) => b.step >= 4).toList();

    if (filtered.isEmpty) {
      return MuskilaEmptyView(
        text: active ? "No active bookings right now." : "No past bookings yet.",
        icon: Icons.receipt_long_outlined,
      );
    }

    return RefreshIndicator(
      color: MyTheme.navy,
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final b = filtered[i];
          return MuskilaCard(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MuskilaSellerBookingDetail(
                    booking: b,
                    onStatusChanged: _refresh,
                  ),
                ),
              );
              _refresh();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: MyTheme.paper,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        b.bookingNumber,
                        style: AppTheme.body(
                          size: 12,
                          weight: FontWeight.w700,
                          color: MyTheme.navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTheme.body(size: 12, color: MyTheme.medium_grey),
                      ),
                    ),
                    MuskilaPill.status(b.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  b.serviceTitle,
                  style: AppTheme.body(
                    size: 15.5,
                    weight: FontWeight.w700,
                    color: MyTheme.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    MuskilaAvatar(name: b.customerName, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.customerName,
                            style: AppTheme.body(
                              size: 13.5,
                              weight: FontWeight.w600,
                              color: MyTheme.ink,
                            ),
                          ),
                          Text(
                            "${b.scheduledDate} • ${b.scheduledTimeSlot}",
                            style: AppTheme.body(
                                size: 12, color: MyTheme.dark_grey),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      muskilaMoney(b.price),
                      style: AppTheme.figure(16, color: MyTheme.navy),
                    ),
                  ],
                ),
                const Divider(height: 20, color: MyTheme.hairline),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 15, color: MyTheme.medium_grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b.locationAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTheme.body(size: 12, color: MyTheme.medium_grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "View Details",
                      style: AppTheme.body(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: MyTheme.royal,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: MyTheme.royal),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
