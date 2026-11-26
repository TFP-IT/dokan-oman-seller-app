import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_ui.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/muskila_seller_booking_detail.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/muskila_seller_bookings.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/muskila_seller_chat.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/muskila_seller_earnings.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/muskila_seller_job_board.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/muskila_seller_profile.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

class MuskilaSellerDashboard extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;

  const MuskilaSellerDashboard({super.key, this.onSwitchTab});

  @override
  State<MuskilaSellerDashboard> createState() => _MuskilaSellerDashboardState();
}

class _MuskilaSellerDashboardState extends State<MuskilaSellerDashboard> {
  MuskilaSellerProfile? _profile;
  List<MuskilaSellerBooking> _activeBookings = [];
  List<MuskilaJobLead> _recentLeads = [];
  bool _isLoading = true;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_profile == null) setState(() => _isLoading = true);
    final p = await MuskilaSellerApi.instance.getProfile();
    final bookings = await MuskilaSellerApi.instance.getBookings(refresh: true);
    final leads = await MuskilaSellerApi.instance.getJobLeads(refresh: true);

    if (mounted) {
      setState(() {
        _profile = p;
        _activeBookings = bookings.where((b) => b.step < 4).toList();
        _recentLeads = leads.take(2).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleOnline(bool online) async {
    setState(() => _toggling = true);
    await MuskilaSellerApi.instance.setOnlineStatus(online);
    final p = await MuskilaSellerApi.instance.getProfile();
    if (mounted) {
      setState(() {
        _profile = p;
        _toggling = false;
      });
      muskilaToast(online
          ? "You are now online & visible to customers"
          : "Availability paused");
    }
  }

  Future<void> _go(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _load();
  }

  void _goTabOrPush(int tabIndex, Widget fallback) {
    if (widget.onSwitchTab != null) {
      widget.onSwitchTab!(tabIndex);
    } else {
      _go(fallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final p = _profile!;
    final isOnline = p.isOnline;

    return RefreshIndicator(
      color: MyTheme.navy,
      backgroundColor: Colors.white,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _hero(p),
          const SizedBox(height: 16),
          _availabilityCard(isOnline),
          const MuskilaSectionHeader(title: "Quick Actions"),
          _shortcuts(),
          if (_activeBookings.isNotEmpty) ...[
            MuskilaSectionHeader(
              title: "Active Bookings",
              actionLabel: "See all",
              onAction: () =>
                  _goTabOrPush(1, const MuskilaSellerBookingsScreen()),
            ),
            ..._activeBookings.take(3).map(_bookingCard),
          ],
          if (_recentLeads.isNotEmpty) ...[
            MuskilaSectionHeader(
              title: "New Job Leads",
              actionLabel: "Browse all",
              onAction: () =>
                  _goTabOrPush(2, const MuskilaSellerJobBoardScreen()),
            ),
            ..._recentLeads.map(_leadCard),
          ],
          const MuskilaSectionHeader(title: "Money & Escrow"),
          _moneyCard(p),
          const MuskilaSectionHeader(title: "Specialist Profile"),
          _settingsCard(p),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // ---- Premium Gradient Hero Banner ----------------------------------------

  Widget _hero(MuskilaSellerProfile p) {
    Widget stat(String label, String value, IconData icon, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 13, color: MyTheme.amber),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.body(
                          size: 11,
                          weight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: AppTheme.figure(18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [MyTheme.navy_deep, MyTheme.navy, Color(0xFF123B7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -28,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: 10,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyTheme.amber.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Greeting & Specialist badge
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : "S",
                        style: AppTheme.body(
                          size: 17,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  "Hello, ${p.name}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.body(
                                    size: 16,
                                    weight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (p.isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified,
                                    size: 16, color: MyTheme.amber),
                              ],
                            ],
                          ),
                          Text(
                            p.professionTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.body(
                              size: 12.5,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Main Balance Row
                InkWell(
                  onTap: () => _go(const MuskilaSellerEarningsScreen()),
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Available Balance",
                              style: AppTheme.body(
                                size: 12.5,
                                weight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      p.availableBalance.toStringAsFixed(3),
                                      style: AppTheme.figure(40,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "OMR",
                                  style: AppTheme.body(
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: MyTheme.amber,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: MyTheme.amber,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Wallet",
                              style: AppTheme.body(
                                size: 13,
                                weight: FontWeight.w700,
                                color: MyTheme.navy_deep,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: MyTheme.navy_deep,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Translucent Stats Strip
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      stat(
                        "Active Jobs",
                        _activeBookings.length.toString(),
                        Icons.handyman_rounded,
                        () => _goTabOrPush(
                            1, const MuskilaSellerBookingsScreen()),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      stat(
                        "In Escrow",
                        muskilaMoney(p.pendingEscrow),
                        Icons.lock_outline_rounded,
                        () => _go(const MuskilaSellerEarningsScreen()),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      stat(
                        "Rating",
                        "${p.rating} ★",
                        Icons.star_rounded,
                        () => _goTabOrPush(
                            3, const MuskilaSellerProfileScreen()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Availability Card ---------------------------------------------------

  Widget _availabilityCard(bool isOnline) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: MuskilaCard(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
          borderColor:
              isOnline ? MyTheme.green.withValues(alpha: 0.35) : MyTheme.hairline,
          child: Row(
            children: [
              MuskilaIconBadge(
                icon: isOnline
                    ? Icons.wifi_tethering_rounded
                    : Icons.pause_circle_outline_rounded,
                bg: isOnline
                    ? const Color(0xFFE2F3EC)
                    : const Color(0xFFFBE7E4),
                fg: isOnline ? MyTheme.green : MyTheme.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isOnline ? "Online & Available" : "Service Paused",
                          style: AppTheme.body(
                            size: 15,
                            weight: FontWeight.w700,
                            color: MyTheme.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOnline ? MyTheme.green : MyTheme.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOnline
                          ? "Receiving direct bookings & instant job matches."
                          : "Switch on to accept new customer requests.",
                      style: AppTheme.body(size: 12, color: MyTheme.dark_grey),
                    ),
                  ],
                ),
              ),
              _toggling
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Switch(
                      value: isOnline,
                      activeThumbColor: MyTheme.green,
                      onChanged: _toggleOnline,
                    ),
            ],
          ),
        ),
      );

  // ---- Quick Actions Grid --------------------------------------------------

  Widget _shortcuts() {
    final items = [
      (
        Icons.receipt_long_rounded,
        "Bookings",
        MyTheme.blue_tint,
        MyTheme.royal,
        () => _goTabOrPush(1, const MuskilaSellerBookingsScreen()),
      ),
      (
        Icons.travel_explore_rounded,
        "Job Leads",
        MyTheme.amber_soft,
        MyTheme.amber_ink,
        () => _goTabOrPush(2, const MuskilaSellerJobBoardScreen()),
      ),
      (
        Icons.chat_bubble_rounded,
        "Messages",
        const Color(0xFFE2F3EC),
        MyTheme.green,
        () => _go(const MuskilaSellerChatScreen()),
      ),
      (
        Icons.account_balance_wallet_rounded,
        "Earnings",
        const Color(0xFFEDE9FE),
        const Color(0xFF5B21B6),
        () => _go(const MuskilaSellerEarningsScreen()),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MuskilaCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Row(
          children: [
            for (final it in items)
              Expanded(
                child: InkWell(
                  onTap: it.$5,
                  borderRadius: BorderRadius.circular(MyTheme.radius_control),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        MuskilaIconBadge(
                          icon: it.$1,
                          bg: it.$3,
                          fg: it.$4,
                          size: 46,
                          iconSize: 22,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          it.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                            size: 12.5,
                            weight: FontWeight.w600,
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
      ),
    );
  }

  // ---- Active Booking Card -------------------------------------------------

  Widget _bookingCard(MuskilaSellerBooking b) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: MuskilaCard(
        onTap: () => _go(
            MuskilaSellerBookingDetail(booking: b, onStatusChanged: _load)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                const Spacer(),
                MuskilaPill.status(b.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              b.serviceTitle,
              style: AppTheme.body(
                size: 15,
                weight: FontWeight.w700,
                color: MyTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                MuskilaAvatar(name: b.customerName, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${b.customerName} • ${b.scheduledDate}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(size: 12.5, color: MyTheme.dark_grey),
                  ),
                ),
                Text(
                  muskilaMoney(b.price),
                  style: AppTheme.figure(15, color: MyTheme.navy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Recent Lead Card ----------------------------------------------------

  Widget _leadCard(MuskilaJobLead lead) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: MuskilaCard(
        onTap: () => _goTabOrPush(2, const MuskilaSellerJobBoardScreen()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lead.categoryName,
                    style: AppTheme.body(
                      size: 12,
                      weight: FontWeight.w600,
                      color: MyTheme.royal,
                    ),
                  ),
                ),
                MuskilaPill(
                  lead.isUrgent ? "URGENT" : "${lead.proposalCount} Quotes",
                  bg: lead.isUrgent ? const Color(0xFFFBE7E4) : MyTheme.paper,
                  fg: lead.isUrgent ? MyTheme.red : MyTheme.dark_grey,
                  icon: lead.isUrgent ? Icons.bolt_rounded : null,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              lead.title,
              style: AppTheme.body(
                size: 15,
                weight: FontWeight.w700,
                color: MyTheme.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              lead.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.body(size: 13, color: MyTheme.dark_grey),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 15, color: MyTheme.medium_grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lead.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(size: 12, color: MyTheme.medium_grey),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MyTheme.blue_tint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Est. ${muskilaMoney(lead.budget)}",
                    style: AppTheme.body(
                      size: 12.5,
                      weight: FontWeight.w700,
                      color: MyTheme.navy,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- Money & Settings Cards ----------------------------------------------

  Widget _moneyCard(MuskilaSellerProfile p) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: MuskilaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _row(
                Icons.account_balance_wallet_outlined,
                MyTheme.blue_tint,
                MyTheme.navy,
                "Available balance",
                "${muskilaMoney(p.availableBalance)} ready for payout",
                () => _go(const MuskilaSellerEarningsScreen()),
              ),
              const Divider(height: 1, indent: 68, color: MyTheme.hairline),
              _row(
                Icons.lock_clock_outlined,
                MyTheme.amber_soft,
                MyTheme.amber_ink,
                "Locked in escrow",
                "${muskilaMoney(p.pendingEscrow)} across active jobs",
                () => _go(const MuskilaSellerEarningsScreen()),
              ),
              const Divider(height: 1, indent: 68, color: MyTheme.hairline),
              _row(
                Icons.trending_up_rounded,
                const Color(0xFFE2F3EC),
                MyTheme.green,
                "Lifetime earnings",
                "${muskilaMoney(p.totalEarnings)} across ${p.jobsCompleted} jobs",
                () => _go(const MuskilaSellerEarningsScreen()),
              ),
            ],
          ),
        ),
      );

  Widget _settingsCard(MuskilaSellerProfile p) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: MuskilaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _row(
                Icons.badge_outlined,
                MyTheme.blue_tint,
                MyTheme.royal,
                "Specialist Profile & Rates",
                "${p.professionTitle} • Base ${muskilaMoney(p.visitPrice)}",
                () => _goTabOrPush(3, const MuskilaSellerProfileScreen()),
              ),
              const Divider(height: 1, indent: 68, color: MyTheme.hairline),
              _row(
                Icons.construction_outlined,
                MyTheme.paper,
                MyTheme.ink,
                "Skills & Category",
                "${p.categoryName} (${p.skills.length} skills)",
                () => _goTabOrPush(3, const MuskilaSellerProfileScreen()),
              ),
            ],
          ),
        ),
      );

  Widget _row(
    IconData icon,
    Color bg,
    Color fg,
    String title,
    String sub,
    VoidCallback onTap,
  ) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
          child: Row(
            children: [
              MuskilaIconBadge(icon: icon, bg: bg, fg: fg, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.body(
                        size: 14.5,
                        weight: FontWeight.w600,
                        color: MyTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: AppTheme.body(size: 12.5, color: MyTheme.dark_grey),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: MyTheme.medium_grey),
            ],
          ),
        ),
      );
}
