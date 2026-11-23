import 'dart:async';

import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_models.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_repository.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_ui.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/screens/ch_order_detail.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// Notifies open order screens that a push arrived (guide §6.3, §10).
final ValueNotifier<int> chOrdersRefreshTick = ValueNotifier(0);

/// Orders with Active / Past tabs (guide §6.1).
class ChOrders extends StatelessWidget {
  const ChOrders({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: MyTheme.paper,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: MyTheme.ink),
          title: Text("Orders",
              style: AppTheme.body(
                  size: 18, weight: FontWeight.w600, color: MyTheme.ink)),
          bottom: const TabBar(
            labelColor: MyTheme.navy,
            indicatorColor: MyTheme.navy,
            tabs: [Tab(text: "Active"), Tab(text: "Past")],
          ),
        ),
        body: const TabBarView(children: [
          _OrderList(tab: "active"),
          _OrderList(tab: "past"),
        ]),
      ),
    );
  }
}

class _OrderList extends StatefulWidget {
  final String tab;

  const _OrderList({required this.tab});

  @override
  State<_OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<_OrderList>
    with AutomaticKeepAliveClientMixin {
  final _repo = ChRepository();
  final _scroll = ScrollController();
  final List<ChOrder> _items = [];
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
    chOrdersRefreshTick.addListener(_refresh);
    if (widget.tab == "active") {
      // keeps the accept countdown moving
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _items.any((o) => o.acceptDeadline != null)) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    chOrdersRefreshTick.removeListener(_refresh);
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
      final p = await _repo.orders(tab: widget.tab, page: _page);
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
      return ChErrorView(message: chErrorText(_error!), onRetry: _refresh);
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _items.isEmpty
          ? ChEmptyView(
              text: widget.tab == "active"
                  ? "No active orders right now."
                  : "No past orders yet.",
              icon: Icons.receipt_long_outlined)
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
                      child: Center(child: CircularProgressIndicator()));
                }
                return _OrderTile(
                  order: _items[i],
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ChOrderDetail(orderId: _items[i].id)));
                    _refresh();
                  },
                );
              },
            ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final ChOrder order;
  final VoidCallback onTap;

  const _OrderTile({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final o = order;
    return ChCard(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(o.code,
              style: AppTheme.body(
                  size: 15, weight: FontWeight.w700, color: MyTheme.ink)),
          const SizedBox(width: 8),
          Icon(o.isPickup ? Icons.storefront : Icons.delivery_dining,
              size: 16, color: MyTheme.medium_grey),
          const Spacer(),
          ChPill.status(o.status, o.statusTitle),
        ]),
        const SizedBox(height: 8),
        Text("${o.dishEmoji} ${o.dishName} × ${o.qty}",
            style: AppTheme.body(size: 14, color: MyTheme.font_grey)),
        const SizedBox(height: 4),
        Row(children: [
          Text(chMoney(o.amounts.customerPaid, o.currency),
              style: AppTheme.body(
                  size: 13, weight: FontWeight.w600, color: MyTheme.ink)),
          const Spacer(),
          if (o.status == "placed" && o.acceptDeadline != null)
            ChAcceptCountdown(deadline: o.acceptDeadline!)
          else
            Text(chDateTime(o.createdAt),
                style: AppTheme.body(size: 12, color: MyTheme.medium_grey)),
        ]),
      ]),
    );
  }
}

/// "Accept in 04:32" countdown (guide §6.3).
class ChAcceptCountdown extends StatelessWidget {
  final DateTime deadline;

  const ChAcceptCountdown({super.key, required this.deadline});

  @override
  Widget build(BuildContext context) {
    final left = deadline.difference(DateTime.now());
    if (left.isNegative) {
      return Text("Accept time passed",
          style: AppTheme.body(size: 12, color: MyTheme.red));
    }
    final m = left.inMinutes.toString().padLeft(2, '0');
    final s = (left.inSeconds % 60).toString().padLeft(2, '0');
    return Text("Accept in $m:$s",
        style: AppTheme.body(
            size: 12, weight: FontWeight.w600, color: MyTheme.amber_ink));
  }
}
