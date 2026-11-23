import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_models.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_repository.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_ui.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/screens/ch_dishes.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/screens/ch_earnings.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/screens/ch_kitchen_profile.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/screens/ch_orders.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/screens/ch_stories.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// Cook Habibi dashboard, laid out like the main seller dashboard (navy hero,
/// big figure, shortcuts and settings cards). Guide §5, §9.
class ChKitchenHome extends StatefulWidget {
  const ChKitchenHome({super.key});

  @override
  State<ChKitchenHome> createState() => _ChKitchenHomeState();
}

class _ChKitchenHomeState extends State<ChKitchenHome> {
  final _repo = ChRepository();
  ChDashboard? _dash;
  ChProfile? _profile;
  Object? _error;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([_repo.dashboard(), _repo.profile()]);
      if (!mounted) return;
      setState(() {
        _dash = r[0] as ChDashboard;
        _profile = r[1] as ChProfile;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  bool get _isOpen => _profile?.isAcceptingOrders ?? _dash?.isOpen ?? false;
  bool get _suspended => _profile?.isSuspended ?? false;
  String get _cur => _dash?.currency ?? "OMR";

  Future<void> _toggleOpen(bool open) async {
    setState(() => _toggling = true);
    try {
      chToast(await _repo.setOpen(open));
      await _load();
    } catch (e) {
      chToastError(e);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _go(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: MyTheme.navy,
      backgroundColor: Colors.white,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _hero(),
          if (_error != null && _dash == null) ...[
            const SizedBox(height: 16),
            _errorCard(),
          ],
          if (_suspended) ...[
            const SizedBox(height: 16),
            _suspendedCard(),
          ],
          const SizedBox(height: 16),
          _openCard(),
          _sectionTitle("Shortcuts"),
          _shortcuts(),
          _sectionTitle("Money"),
          _moneyCard(),
          _sectionTitle("Settings"),
          _settingsCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---- header: same navy hero as the main dashboard ------------------------

  Widget _figure(String? value, TextStyle style) {
    final loaded = value != null && value.isNotEmpty;
    final color = style.color ?? MyTheme.navy;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(loaded ? value : "–",
          maxLines: 1,
          style: style.copyWith(
              color: loaded ? color : color.withValues(alpha: 0.35))),
    );
  }

  Widget _hero() {
    final d = _dash;
    final name = _profile?.kitchenName ?? "";

    Widget stat(String label, String? value, VoidCallback? onTap) => Expanded(
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white24,
            borderRadius: BorderRadius.circular(MyTheme.radius_control),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _figure(value, AppTheme.figure(32, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(
                          size: 14,
                          weight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
          ),
        );

    return Container(
      color: MyTheme.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _go(const ChOrders()),
            splashColor: Colors.white24,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (name.isNotEmpty) ...[
                          Text("Hello, $name",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body(
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.65))),
                          const SizedBox(height: 8),
                        ],
                        Text("Sales today",
                            style: AppTheme.body(
                                size: 16,
                                weight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.8))),
                        _figure(
                            d == null ? null : d.salesToday.toStringAsFixed(3),
                            AppTheme.figure(72, color: Colors.white)),
                        Text(_cur,
                            style: AppTheme.body(
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.65))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                          color: MyTheme.amber, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: MyTheme.navy),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                stat("Orders today", d?.ordersToday.toString(),
                    () => _go(const ChOrders())),
                stat("Active", d?.activeOrders.toString(),
                    () => _go(const ChOrders())),
                stat(
                    "Rating",
                    d == null
                        ? null
                        : (d.rating == null ? "0" : d.rating!.toStringAsFixed(1)),
                    null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- cards -----------------------------------------------------------------

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(text,
            style: AppTheme.body(
                size: 18, weight: FontWeight.w600, color: MyTheme.navy)),
      );

  BoxDecoration get _surface => BoxDecoration(
        color: MyTheme.white,
        borderRadius: BorderRadius.circular(MyTheme.radius_card),
        border: Border.all(color: MyTheme.hairline),
      );

  EdgeInsets get _gutter => const EdgeInsets.symmetric(horizontal: 16);

  Widget _errorCard() => Container(
        margin: _gutter,
        padding: const EdgeInsets.all(16),
        decoration: _surface,
        child: Row(children: [
          Expanded(
              child: Text(chErrorText(_error!),
                  style: AppTheme.body(size: 14, color: MyTheme.font_grey))),
          TextButton(onPressed: _load, child: const Text("Try again")),
        ]),
      );

  Widget _suspendedCard() => Container(
        margin: _gutter,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MyTheme.amber_soft,
          borderRadius: BorderRadius.circular(MyTheme.radius_card),
          border: Border.all(color: MyTheme.amber.withValues(alpha: 0.45)),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: MyTheme.amber, shape: BoxShape.circle),
            child: const Icon(Icons.block, color: MyTheme.ink, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Your kitchen is suspended",
                  style: AppTheme.body(
                      size: 15, weight: FontWeight.w700, color: MyTheme.ink)),
              const SizedBox(height: 2),
              Text("You can view everything, but changes are turned off.",
                  style: AppTheme.body(size: 13, color: MyTheme.amber_ink)),
            ]),
          ),
        ]),
      );

  Widget _openCard() => Container(
        margin: _gutter,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
        decoration: _surface,
        child: Row(children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: _isOpen ? MyTheme.green : MyTheme.red,
                shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_isOpen ? "Open for orders" : "Closed for orders",
                  style: AppTheme.body(
                      size: 16, weight: FontWeight.w600, color: MyTheme.ink)),
              Text(
                  _isOpen
                      ? "Customers can order from your kitchen now."
                      : "Turn on to start getting orders.",
                  style: AppTheme.body(size: 13, color: MyTheme.dark_grey)),
            ]),
          ),
          _toggling
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : Switch(
                  value: _isOpen,
                  onChanged:
                      (_suspended || _profile == null) ? null : _toggleOpen),
        ]),
      );

  Widget _shortcuts() {
    final d = _dash;
    final items = [
      (Icons.receipt_long_outlined, "Orders", () => _go(const ChOrders())),
      (Icons.restaurant_menu_outlined, "Dishes", () => _go(const ChDishes())),
      (
        Icons.auto_stories_outlined,
        "Stories",
        () => _go(ChStories(liveCount: d?.liveStories))
      ),
      (
        Icons.account_balance_wallet_outlined,
        "Earnings",
        () => _go(const ChEarningsScreen())
      ),
    ];
    return Container(
      margin: _gutter,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: _surface,
      child: Row(
        children: [
          for (final it in items)
            Expanded(
              child: InkWell(
                onTap: it.$3,
                borderRadius: BorderRadius.circular(MyTheme.radius_control),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          color: MyTheme.blue_tint,
                          borderRadius:
                              BorderRadius.circular(MyTheme.radius_control)),
                      child: Icon(it.$1, color: MyTheme.navy),
                    ),
                    const SizedBox(height: 6),
                    Text(it.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(
                            size: 13,
                            weight: FontWeight.w500,
                            color: MyTheme.ink)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String title, String sub, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
          child: Row(children: [
            Icon(icon, color: MyTheme.navy, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: AppTheme.body(
                        size: 16, weight: FontWeight.w500, color: MyTheme.ink)),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(size: 13, color: MyTheme.dark_grey)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: MyTheme.dark_grey),
          ]),
        ),
      );

  Widget _moneyCard() {
    final d = _dash;
    return Container(
      margin: _gutter,
      decoration: _surface,
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        _row(
            Icons.account_balance_wallet_outlined,
            "Balance due",
            d == null ? "–" : chMoney(d.balanceDue, _cur),
            () => _go(const ChEarningsScreen())),
        const Divider(indent: 16, endIndent: 16),
        _row(
            Icons.task_alt_outlined,
            "Completed orders",
            d == null ? "–" : "${d.completedOrders} orders",
            () => _go(const ChOrders())),
        const Divider(indent: 16, endIndent: 16),
        _row(
            Icons.star_outline_rounded,
            "Reviews",
            d == null ? "–" : "${d.reviewsCount} reviews",
            () {}),
      ]),
    );
  }

  Widget _settingsCard() => Container(
        margin: _gutter,
        decoration: _surface,
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          _row(Icons.storefront_outlined, "Kitchen profile",
              "Details, photos, delivery and offers",
              () => _go(const ChKitchenProfile())),
          const Divider(indent: 16, endIndent: 16),
          _row(Icons.schedule_outlined, "Working hours",
              "Set the days and times you cook", () {
            final p = _profile;
            if (p == null) return;
            _go(ChScheduleScreen(profile: p, locked: _suspended));
          }),
        ]),
      );
}
