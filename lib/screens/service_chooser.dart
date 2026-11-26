import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_api.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_session.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_session.dart';
import 'package:active_ecommerce_seller_app/custom/CommonFunctoins.dart';
import 'package:active_ecommerce_seller_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_seller_app/helpers/shop_info_helper.dart';
import 'package:active_ecommerce_seller_app/helpers/system_config.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/screens/main.dart';
import 'package:flutter/material.dart';

/// A short live line under a service ("Open, 3 active orders").
class ServiceStatus {
  final String text;
  final Color color;

  const ServiceStatus(this.text, this.color);
}

/// One service the seller can open. Add new services to [SellerServices.all].
class SellerService {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;

  /// The service's own colour: the stripe and icon tile on its card.
  final Color accent;
  final Color tint;

  /// Builds the service's dashboard (may check access first).
  final Future<Widget> Function() open;

  /// Optional live status; return null to show nothing.
  final Future<ServiceStatus?> Function()? status;

  const SellerService({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.tint,
    required this.open,
    this.status,
  });
}

class SellerServices {
  static const Color _saffron = Color(0xFFB86E00);
  static const Color _saffronTint = Color(0xFFFFF2DE);

  static final List<SellerService> all = [
    SellerService(
      id: "ecommerce",
      title: "E-commerce",
      subtitle: "Products, orders, coupons and shop settings",
      icon: Icons.storefront_outlined,
      accent: MyTheme.royal,
      tint: MyTheme.blue_tint,
      open: () async => const Main(),
      status: _ecommerceStatus,
    ),
    SellerService(
      id: "cook_habibi",
      title: "Cook Habibi",
      subtitle: "Home kitchen dishes, food orders, stories and earnings",
      icon: Icons.soup_kitchen_outlined,
      accent: _saffron,
      tint: _saffronTint,
      open: ChSession.startScreen,
      status: _cookStatus,
    ),
    SellerService(
      id: "hal_al_muskila",
      title: "Hal Al Mushkila",
      subtitle: "On-demand services, bookings, job board, quotes and earnings",
      icon: Icons.handyman_outlined,
      accent: MyTheme.navy,
      tint: MyTheme.blue_tint,
      open: HmSession.startScreen,
      status: HmSession.getStatus,
    ),
  ];

  static Future<ServiceStatus?> _ecommerceStatus() async {
    final rating = double.tryParse(shop_rating.$);
    final verified = shop_verify.$;
    final parts = [
      verified ? "Verified shop" : "Shop not verified yet",
      if (rating != null && rating > 0) "${rating.toStringAsFixed(1)} rating",
    ];
    return ServiceStatus(
        parts.join(", "), verified ? MyTheme.green : MyTheme.amber_ink);
  }

  /// Silent checks: a seller without a kitchen just sees no status.
  static Future<ServiceStatus?> _cookStatus() async {
    try {
      final app = chMap(chMap(await ChApi.get(ChApi.seller("application"),
          signOutOnAuthError: false))["data"]);
      final appStatus = chStr(app["status"]);
      if (appStatus == "pending") {
        return const ServiceStatus(
            "Application under review", MyTheme.amber_ink);
      }
      if (appStatus == "rejected") {
        return const ServiceStatus(
            "Application needs changes", MyTheme.red);
      }
      final d = chMap(chMap(await ChApi.get(ChApi.seller("dashboard"),
          signOutOnAuthError: false))["data"]);
      final open = chBool(d["is_open"]);
      final active = chInt(d["active_orders"]) ?? 0;
      final orders = active == 1 ? "1 active order" : "$active active orders";
      return open
          ? ServiceStatus("Open, $orders", MyTheme.green)
          : ServiceStatus(
              active > 0 ? "Closed, $orders" : "Closed for orders",
              MyTheme.dark_grey);
    } catch (_) {
      return null;
    }
  }
}

/// Shown after splash and sign-in: the seller picks which dashboard to open.
class ServiceChooser extends StatefulWidget {
  const ServiceChooser({super.key});

  /// Goes back to the chooser from any dashboard.
  static void open(BuildContext context) {
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const ServiceChooser()), (r) => false);
  }

  @override
  State<ServiceChooser> createState() => _ServiceChooserState();
}

class _ServiceChooserState extends State<ServiceChooser> {
  String? _opening;
  final Map<String, Future<ServiceStatus?>> _status = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await ShopInfoHelper.loadShopInfo();
    if (mounted) _loadStatuses();
    try {
      await ShopInfoHelper().setShopInfo();
    } catch (_) {
      // shop info is optional here (a kitchen-only seller has no shop)
    }
    if (mounted) _loadStatuses();
  }

  void _loadStatuses() {
    setState(() {
      for (final s in SellerServices.all) {
        if (s.status != null) _status[s.id] = s.status!();
      }
    });
  }

  Future<void> _choose(SellerService s) async {
    if (_opening != null) return;
    setState(() => _opening = s.id);
    try {
      final page = await s.open();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => page), (r) => false);
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  /// The signed-in person's name (falls back to the shop name).
  String get _name {
    final user = SystemConfig.systemUser?.name?.trim() ?? "";
    return user.isNotEmpty ? user : shop_name.$;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) CommonFunctions(context).appExitDialog();
      },
      child: Scaffold(
        backgroundColor: MyTheme.paper,
        body: RefreshIndicator(
          color: MyTheme.navy,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                sliver: SliverList.separated(
                  itemCount: SellerServices.all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ServiceCard(
                    service: SellerServices.all[i],
                    status: _status[SellerServices.all[i].id],
                    busy: _opening == SellerServices.all[i].id,
                    disabled: _opening != null,
                    onTap: () => _choose(SellerServices.all[i]),
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text.rich(
                          TextSpan(children: [
                            const TextSpan(text: "Switch any time with "),
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(Icons.apps_rounded,
                                  size: 16, color: MyTheme.grey_153),
                            ),
                            const TextSpan(text: " on each dashboard."),
                          ]),
                          textAlign: TextAlign.center,
                          style: AppTheme.body(
                              size: 13, color: MyTheme.medium_grey),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _opening == null
                              ? () => ChSession.signOut(context)
                              : null,
                          style: TextButton.styleFrom(
                              foregroundColor: MyTheme.dark_grey),
                          child: const Text("Sign out"),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final name = _name;
    return Container(
      color: MyTheme.navy,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset("assets/logo/app_logo_small.png",
                      fit: BoxFit.contain,
                      semanticLabel: "Dokan"),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name.isEmpty ? "Welcome back" : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(
                          size: 16,
                          weight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 24),
              Text("Which business are you running now?",
                  style: AppTheme.display(
                      size: 26, color: Colors.white, height: 1.15)),
              const SizedBox(height: 8),
              Text("Each one has its own dashboard, orders and money.",
                  style: AppTheme.body(
                      size: 14, color: Colors.white.withValues(alpha: 0.72))),
            ],
          ),
        ),
      ),
    );
  }

}

class _ServiceCard extends StatelessWidget {
  final SellerService service;
  final Future<ServiceStatus?>? status;
  final bool busy;
  final bool disabled;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.status,
    required this.busy,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = service;
    return Semantics(
      button: true,
      label: "Open ${s.title} dashboard",
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MyTheme.radius_card),
            side: const BorderSide(color: MyTheme.hairline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onTap,
          splashColor: s.tint,
          highlightColor: s.tint.withValues(alpha: 0.5),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // the service's colour, so the two cards never read alike
                Container(width: 6, color: s.accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 12, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                              color: s.tint,
                              borderRadius: BorderRadius.circular(
                                  MyTheme.radius_control)),
                          child: Icon(s.icon, color: s.accent, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.title,
                                  style: AppTheme.display(
                                      size: 20, color: MyTheme.ink)),
                              const SizedBox(height: 2),
                              Text(s.subtitle,
                                  style: AppTheme.body(
                                      size: 13,
                                      color: MyTheme.dark_grey,
                                      height: 1.35)),
                              _statusLine(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: busy
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: s.accent))
                              : const Icon(Icons.chevron_right_rounded,
                                  color: MyTheme.grey_153),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusLine() {
    if (status == null) return const SizedBox.shrink();
    return FutureBuilder<ServiceStatus?>(
      future: status,
      builder: (context, snap) {
        final st = snap.data;
        final loading = snap.connectionState != ConnectionState.done;
        if (!loading && st == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: loading ? MyTheme.hairline : st!.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: loading
                  ? Container(
                      width: 120,
                      height: 10,
                      decoration: BoxDecoration(
                          color: MyTheme.shimmer_base,
                          borderRadius: BorderRadius.circular(4)),
                    )
                  : Text(st!.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(
                          size: 13,
                          weight: FontWeight.w600,
                          color: st.color)),
            ),
          ]),
        );
      },
    );
  }
}
