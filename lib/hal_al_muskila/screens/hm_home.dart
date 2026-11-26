import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_ui.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_bookings.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_earnings.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_instant_requests_sheet.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_job_board.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_profile.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_reviews.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_services.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// Pro Dashboard following `ChKitchenHome` visual language with Hal Al Mushkila workflow.
class HmHome extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;

  const HmHome({super.key, this.onSwitchTab});

  @override
  State<HmHome> createState() => _HmHomeState();
}

class _HmHomeState extends State<HmHome> {
  final _repo = HmRepository();
  HmDashboard? _dash;
  HmProfile? _profile;
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
        _dash = r[0] as HmDashboard;
        _profile = r[1] as HmProfile;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  bool get _isOnline => _profile?.isOnline ?? _dash?.isOnline ?? false;
  bool get _suspended => _profile?.isSuspended ?? _dash?.isSuspended ?? false;
  String get _cur => _dash?.currency ?? "OMR";

  Future<void> _toggleOnline(bool online) async {
    setState(() => _toggling = true);
    try {
      hmToast(await _repo.setOnline(online));
      await _load();
    } catch (e) {
      hmToastError(e);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _go(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _load();
  }

  void _tabOrPush(int index, Widget fallback) {
    if (widget.onSwitchTab != null) {
      widget.onSwitchTab!(index);
    } else {
      _go(fallback);
    }
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
          if ((_dash?.pendingInstantCount ?? 0) > 0) ...[
            const SizedBox(height: 16),
            _instantAlertCard(_dash!.pendingInstantCount),
          ],
          const SizedBox(height: 16),
          _onlineCard(),
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

  Widget _figure(String? value, TextStyle style) {
    final loaded = value != null && value.isNotEmpty;
    final color = style.color ?? MyTheme.navy;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        loaded ? value : "–",
        maxLines: 1,
        style: style.copyWith(
          color: loaded ? color : color.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _hero() {
    final d = _dash;
    final name = _profile?.name ?? "";

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
                  _figure(value, AppTheme.figure(30, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(
                      size: 13.5,
                      weight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
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
            onTap: () => _go(const HmEarningsScreen()),
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
                          Text(
                            "Hello, $name",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.body(
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          "Earnings today",
                          style: AppTheme.body(
                            size: 16,
                            weight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        _figure(
                          d == null ? null : d.earningsToday.toStringAsFixed(3),
                          AppTheme.figure(64, color: Colors.white),
                        ),
                        Text(
                          _cur,
                          style: AppTheme.body(
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: MyTheme.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: MyTheme.navy,
                      ),
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
                stat(
                  "Active jobs",
                  d?.activeBookings.toString(),
                  () => _tabOrPush(1, const HmBookingsScreen()),
                ),
                stat(
                  "New leads",
                  d?.jobLeadsCount.toString(),
                  () => _tabOrPush(2, const HmJobBoardScreen()),
                ),
                stat(
                  "Rating",
                  d == null
                      ? null
                      : (d.rating == null ? "0" : d.rating!.toStringAsFixed(1)),
                  () => _go(const HmReviewsScreen()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(
          text,
          style: AppTheme.body(
            size: 18,
            weight: FontWeight.w600,
            color: MyTheme.navy,
          ),
        ),
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
        child: Row(
          children: [
            Expanded(
              child: Text(
                hmErrorText(_error!),
                style: AppTheme.body(size: 14, color: MyTheme.font_grey),
              ),
            ),
            TextButton(onPressed: _load, child: const Text("Try again")),
          ],
        ),
      );

  Widget _suspendedCard() => Container(
        margin: _gutter,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MyTheme.amber_soft,
          borderRadius: BorderRadius.circular(MyTheme.radius_card),
          border: Border.all(color: MyTheme.amber.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: MyTheme.amber,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.block, color: MyTheme.ink, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your specialist profile is suspended",
                    style: AppTheme.body(
                      size: 15,
                      weight: FontWeight.w700,
                      color: MyTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "You can view everything, but changes are turned off.",
                    style: AppTheme.body(size: 13, color: MyTheme.amber_ink),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _instantAlertCard(int count) => Padding(
        padding: _gutter,
        child: HmCard(
          onTap: () => HmInstantRequestsSheet.show(context).then((_) => _load()),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: MyTheme.amber_soft,
                  borderRadius: BorderRadius.circular(MyTheme.radius_control),
                ),
                child: const Icon(Icons.bolt_rounded, color: MyTheme.amber_ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$count Urgent Instant Request${count > 1 ? 's' : ''}",
                      style: AppTheme.body(
                        size: 15,
                        weight: FontWeight.w700,
                        color: MyTheme.ink,
                      ),
                    ),
                    Text(
                      "Customer nearby needs immediate help",
                      style: AppTheme.body(size: 13, color: MyTheme.dark_grey),
                    ),
                  ],
                ),
              ),
              const HmPill(
                "View",
                bg: MyTheme.amber_soft,
                fg: MyTheme.amber_ink,
              ),
            ],
          ),
        ),
      );

  Widget _onlineCard() => Container(
        margin: _gutter,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
        decoration: _surface,
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isOnline ? MyTheme.green : MyTheme.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOnline ? "Online for jobs" : "Offline (Paused)",
                    style: AppTheme.body(
                      size: 16,
                      weight: FontWeight.w600,
                      color: MyTheme.ink,
                    ),
                  ),
                  Text(
                    _isOnline
                        ? "Customers can find & book you now."
                        : "Turn on to receive bookings & instant jobs.",
                    style: AppTheme.body(size: 13, color: MyTheme.dark_grey),
                  ),
                ],
              ),
            ),
            _toggling
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Switch(
                    value: _isOnline,
                    onChanged:
                        (_suspended || _profile == null) ? null : _toggleOnline,
                  ),
          ],
        ),
      );

  Widget _shortcuts() {
    final items = [
      (
        Icons.receipt_long_outlined,
        "Bookings",
        () => _tabOrPush(1, const HmBookingsScreen()),
      ),
      (
        Icons.explore_outlined,
        "Job Board",
        () => _tabOrPush(2, const HmJobBoardScreen()),
      ),
      (
        Icons.handyman_outlined,
        "Services",
        () => _go(const HmServicesScreen()),
      ),
      (
        Icons.account_balance_wallet_outlined,
        "Earnings",
        () => _go(const HmEarningsScreen()),
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
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: MyTheme.blue_tint,
                          borderRadius:
                              BorderRadius.circular(MyTheme.radius_control),
                        ),
                        child: Icon(it.$1, color: MyTheme.navy),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        it.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(
                          size: 13,
                          weight: FontWeight.w500,
                          color: MyTheme.ink,
                        ),
                      ),
                    ],
                  ),
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
          child: Row(
            children: [
              Icon(icon, color: MyTheme.navy, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.body(
                        size: 16,
                        weight: FontWeight.w500,
                        color: MyTheme.ink,
                      ),
                    ),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(size: 13, color: MyTheme.dark_grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: MyTheme.dark_grey),
            ],
          ),
        ),
      );

  Widget _moneyCard() {
    final d = _dash;
    return Container(
      margin: _gutter,
      decoration: _surface,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _row(
            Icons.account_balance_wallet_outlined,
            "Balance due",
            d == null ? "–" : hmMoney(d.balanceDue, _cur),
            () => _go(const HmEarningsScreen()),
          ),
          const Divider(indent: 16, endIndent: 16),
          _row(
            Icons.lock_outline_rounded,
            "Locked in escrow",
            d == null
                ? "–"
                : "${hmMoney(d.pendingEscrow, _cur)} (${d.pendingEscrowCount} jobs)",
            () => _go(const HmEarningsScreen()),
          ),
          const Divider(indent: 16, endIndent: 16),
          _row(
            Icons.task_alt_outlined,
            "Completed jobs",
            d == null ? "–" : "${d.completedJobs} jobs",
            () => _tabOrPush(1, const HmBookingsScreen(initialTab: 2)),
          ),
          const Divider(indent: 16, endIndent: 16),
          _row(
            Icons.star_outline_rounded,
            "Reviews",
            d == null ? "–" : "${d.reviewsCount} reviews",
            () => _go(const HmReviewsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard() => Container(
        margin: _gutter,
        decoration: _surface,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _row(
              Icons.badge_outlined,
              "Specialist profile & rates",
              "Photo, category, fees & bargain floor",
              () => _tabOrPush(3, const HmProfileScreen()),
            ),
            const Divider(indent: 16, endIndent: 16),
            _row(
              Icons.schedule_outlined,
              "Working hours & slots",
              "Set the days and slots you work",
              () => _go(HmScheduleScreen(profile: _profile)),
            ),
            const Divider(indent: 16, endIndent: 16),
            _row(
              Icons.place_outlined,
              "Service area & GPS",
              "Coverage areas, map pin & radius",
              () => _go(HmLocationScreen(profile: _profile)),
            ),
            const Divider(indent: 16, endIndent: 16),
            _row(
              Icons.verified_user_outlined,
              "KYC verification & media",
              "8 verification checks & intro video",
              () => _go(HmKycScreen(profile: _profile)),
            ),
          ],
        ),
      );
}

