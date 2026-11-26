import 'dart:async';

import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_ui.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_booking_detail.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// Notifies open booking screens that a push arrived (mirrors `chOrdersRefreshTick`).
final ValueNotifier<int> hmBookingsRefreshTick = ValueNotifier(0);

/// Bookings list with Active / Scheduled / Completed / Cancelled tabs (`ChOrders` pattern).
class HmBookingsScreen extends StatelessWidget {
  final int initialTab;
  final bool showBack;

  const HmBookingsScreen({
    super.key,
    this.initialTab = 0,
    this.showBack = true,
  });

  static const _tabs = [
    ("active", "Active"),
    ("scheduled", "Scheduled"),
    ("completed", "Completed"),
    ("cancelled", "Cancelled"),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      initialIndex: initialTab.clamp(0, _tabs.length - 1),
      child: Scaffold(
        backgroundColor: MyTheme.paper,
        appBar: AppBar(
          automaticallyImplyLeading: showBack,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: AppTheme.lightStatusBar,
          iconTheme: const IconThemeData(color: MyTheme.ink),
          title: Text(
            "Service Bookings",
            style: AppTheme.body(
              size: 18,
              weight: FontWeight.w600,
              color: MyTheme.ink,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: MyTheme.navy,
            unselectedLabelColor: MyTheme.medium_grey,
            indicatorColor: MyTheme.navy,
            tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
          ),
        ),
        body: TabBarView(
          children: _tabs.map((t) => _BookingList(tab: t.$1)).toList(),
        ),
      ),
    );
  }
}

class _BookingList extends StatefulWidget {
  final String tab;

  const _BookingList({required this.tab});

  @override
  State<_BookingList> createState() => _BookingListState();
}

class _BookingListState extends State<_BookingList>
    with AutomaticKeepAliveClientMixin {
  final _repo = HmRepository();
  final _scroll = ScrollController();
  final List<HmBooking> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;
  Timer? _ticker;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _refresh();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
    hmBookingsRefreshTick.addListener(_refresh);
    if (widget.tab == "active") {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _items.any((b) => b.acceptDeadline != null)) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    hmBookingsRefreshTick.removeListener(_refresh);
    _ticker?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _page = 1;
    _hasMore = true;
    _error = null;
    await _fetch(reset: true);
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _page++;
    await _fetch();
  }

  Future<void> _fetch({bool reset = false}) async {
    setState(() => _loading = true);
    try {
      final p = await _repo.bookings(tab: widget.tab, page: _page);
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(p.items);
        _hasMore = p.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return HmErrorView(message: hmErrorText(_error!), onRetry: _refresh);
    }
    return RefreshIndicator(
      color: MyTheme.navy,
      onRefresh: _refresh,
      child: _items.isEmpty
          ? HmEmptyView(
              text: "No ${widget.tab} bookings right now.",
              icon: Icons.receipt_long_outlined,
            )
          : ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _items.length + (_hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i >= _items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final b = _items[i];
                return _BookingTile(
                  booking: b,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HmBookingDetail(bookingId: b.id, initial: b),
                      ),
                    );
                    _refresh();
                  },
                );
              },
            ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final HmBooking booking;
  final VoidCallback onTap;

  const _BookingTile({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return HmCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                b.bookingNumber,
                style: AppTheme.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: MyTheme.navy,
                ),
              ),
              const SizedBox(width: 8),
              HmPill.status(b.status, b.statusTitle),
              const Spacer(),
              Text(
                hmMoney(b.price, b.currency),
                style: AppTheme.figure(16, color: MyTheme.navy),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            b.serviceTitle,
            style: AppTheme.body(
              size: 15.5,
              weight: FontWeight.w600,
              color: MyTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              b.customerName,
              b.scheduledDateText,
              b.scheduledTimeSlot,
            ].where((s) => s.isNotEmpty).join(" · "),
            style: AppTheme.body(size: 13, color: MyTheme.dark_grey),
          ),
          if (b.locationAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.place_outlined,
                    size: 14, color: MyTheme.medium_grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    b.locationAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTheme.body(size: 12, color: MyTheme.medium_grey),
                  ),
                ),
                HmPill(
                  b.escrowReleased
                      ? "Escrow released"
                      : (b.status == "cancelled" ? "Refunded" : "Escrow held"),
                  bg: b.escrowReleased
                      ? const Color(0xFFE2F3EC)
                      : MyTheme.paper,
                  fg: b.escrowReleased ? MyTheme.green : MyTheme.dark_grey,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

