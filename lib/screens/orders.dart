import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/const/DeliveryStatus.dart';
import 'package:active_ecommerce_seller_app/const/PaymentStatus.dart';
import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/order_repository.dart';
import 'package:active_ecommerce_seller_app/screens/order_details.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Orders extends StatefulWidget {
  final bool fromBottomBar;

  const Orders({super.key, this.fromBottomBar = false});

  @override
  _OrdersState createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  final ScrollController _xcrollController = ScrollController();

  final List<PaymentStatus> _paymentStatusList =
      PaymentStatus.getPaymentStatusList();
  final List<DeliveryStatus> _deliveryStatusList =
      DeliveryStatus.getDeliveryStatusList();

  PaymentStatus? _selectedPaymentStatus;
  DeliveryStatus? _selectedDeliveryStatus;

  List<DropdownMenuItem<PaymentStatus>>? _dropdownPaymentStatusItems;
  List<DropdownMenuItem<DeliveryStatus>>? _dropdownDeliveryStatusItems;

  //------------------------------------
  final List<dynamic> _orderList = [];
  bool _isInitial = true;
  int _page = 1;
  int? _totalData = 0;
  bool _showLoadingContainer = false;
  bool _hasError = false;
  String _defaultPaymentStatusKey = '';
  String _defaultDeliveryStatusKey = '';

  @override
  void initState() {
    init();
    super.initState();

    fetchData();

    _xcrollController.addListener(() {
      final pos = _xcrollController.position;
      final hasMore = _orderList.length < (_totalData ?? 0);
      if (pos.pixels >= pos.maxScrollExtent - 200 &&
          hasMore &&
          !_showLoadingContainer &&
          !_isInitial) {
        setState(() {
          _page++;
        });
        _showLoadingContainer = true;
        fetchData();
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    //_scrollController.dispose();
    _xcrollController.dispose();
    super.dispose();
  }

  init() {
    _dropdownPaymentStatusItems =
        buildDropdownPaymentStatusItems(_paymentStatusList);

    _dropdownDeliveryStatusItems =
        buildDropdownDeliveryStatusItems(_deliveryStatusList);

    for (int x = 0; x < _dropdownPaymentStatusItems!.length; x++) {
      if (_dropdownPaymentStatusItems![x].value!.option_key ==
          _defaultPaymentStatusKey) {
        _selectedPaymentStatus = _dropdownPaymentStatusItems![x].value;
      }
    }

    for (int x = 0; x < _dropdownDeliveryStatusItems!.length; x++) {
      if (_dropdownDeliveryStatusItems![x].value!.option_key ==
          _defaultDeliveryStatusKey) {
        _selectedDeliveryStatus = _dropdownDeliveryStatusItems![x].value;
      }
    }
  }

  reset() {
    _orderList.clear();
    _isInitial = true;
    _page = 1;
    _totalData = 0;
    _showLoadingContainer = false;
    _hasError = false;
  }

  resetFilterKeys() {
    _defaultPaymentStatusKey = '';
    _defaultDeliveryStatusKey = '';

    setState(() {});
  }

  Future<void> _onRefresh() async {
    reset();
    resetFilterKeys();
    for (int x = 0; x < _dropdownPaymentStatusItems!.length; x++) {
      if (_dropdownPaymentStatusItems![x].value!.option_key ==
          _defaultPaymentStatusKey) {
        _selectedPaymentStatus = _dropdownPaymentStatusItems![x].value;
      }
    }

    for (int x = 0; x < _dropdownDeliveryStatusItems!.length; x++) {
      if (_dropdownDeliveryStatusItems![x].value!.option_key ==
          _defaultDeliveryStatusKey) {
        _selectedDeliveryStatus = _dropdownDeliveryStatusItems![x].value;
      }
    }
    setState(() {});
    fetchData();
  }

  fetchData() async {
    try {
      var orderResponse = await OrderRepository().getOrderList(
          page: _page,
          payment_status: _selectedPaymentStatus!.option_key,
          delivery_status: _selectedDeliveryStatus!.option_key);
      _orderList.addAll(orderResponse.data ?? []);
      _totalData = orderResponse.meta?.total ?? _orderList.length;
      _hasError = false;
    } catch (e) {
      debugPrint('Orders fetch failed: $e');
      _hasError = _orderList.isEmpty;
    }
    _isInitial = false;
    _showLoadingContainer = false;
    if (mounted) setState(() {});
  }

  List<DropdownMenuItem<PaymentStatus>> buildDropdownPaymentStatusItems(
      List paymentStatusList) {
    List<DropdownMenuItem<PaymentStatus>> items = [];
    for (PaymentStatus item in paymentStatusList as Iterable<PaymentStatus>) {
      items.add(
        DropdownMenuItem(
          value: item,
          child: Text(item.name),
        ),
      );
    }
    return items;
  }

  List<DropdownMenuItem<DeliveryStatus>> buildDropdownDeliveryStatusItems(
      List deliveryStatusList) {
    List<DropdownMenuItem<DeliveryStatus>> items = [];
    for (DeliveryStatus item
        in deliveryStatusList as Iterable<DeliveryStatus>) {
      items.add(
        DropdownMenuItem(
          value: item,
          child: Text(item.name),
        ),
      );
    }
    return items;
  }

  // ---------------------------------------------------------------------------
  // UI — follows the Dokan delivery-app order card: parcel-label layout,
  // hairline white panels, status as tinted pills, full-width detail action.
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final list = RefreshIndicator(
      color: MyTheme.navy,
      backgroundColor: Colors.white,
      onRefresh: _onRefresh,
      child: buildOrderListList(),
    );
    final statusSwitch = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: _StatusSwitch(
        options: _deliveryStatusList,
        selected: _selectedDeliveryStatus,
        onChanged: (s) {
          setState(() => _selectedDeliveryStatus = s);
          reset();
          fetchData();
        },
      ),
    );

    // Inside Main the navy app bar belongs to Main, so the switch sits in a
    // navy strip that continues it.
    if (widget.fromBottomBar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(color: MyTheme.navy, child: statusSwitch),
          Expanded(child: list),
        ],
      );
    }
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: AppBar(
        backgroundColor: MyTheme.navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: AppTheme.darkStatusBar,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(),
        titleSpacing: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const BackButtonIcon(),
          color: Colors.white,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(LangText(context: context).getLocal().orders_ucf,
            style: AppTheme.body(
                size: 18, weight: FontWeight.w600, color: Colors.white)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64), child: statusSwitch),
      ),
      body: list,
    );
  }

  Widget buildOrderListList() {
    final l = LangText(context: context).getLocal();
    final loading = _isInitial && _orderList.isEmpty;

    final List<Widget> content;
    if (loading) {
      content = List.generate(4, (_) => const _OrderCardPlaceholder());
    } else if (_orderList.isEmpty) {
      content = [
        _EmptyState(
          icon: _hasError ? Icons.cloud_off_outlined : Icons.inbox_outlined,
          message: _hasError ? l.network_error : l.no_data_is_available,
        ),
      ];
    } else {
      content = [
        for (final order in _orderList)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OrderCard(
              order: order,
              onOpen: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return OrderDetails(id: order.id);
                }));
              },
            ),
          ),
        if (_showLoadingContainer)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(l.loading_more_orders_ucf,
                  style: AppTheme.body(size: 13, color: MyTheme.dark_grey)),
            ),
          ),
      ];
    }

    return ListView(
      controller: _xcrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        buildFilterSection(context),
        const SizedBox(height: 12),
        if (!loading && !_hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "${_selectedDeliveryStatus?.option_key.isEmpty ?? true ? l.orders_ucf : _selectedDeliveryStatus!.name} (${_totalData ?? 0})",
              style: AppTheme.body(
                  size: 18, weight: FontWeight.w600, color: MyTheme.navy),
            ),
          ),
        ...content,
      ],
    );
  }

  Widget buildFilterSection(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MyTheme.radius_control),
        border: Border.all(color: MyTheme.hairline, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.payments_outlined, size: 18, color: MyTheme.dark_grey),
          const SizedBox(width: 8),
          Text("${LangText(context: context).getLocal().payment_status_ucf}:",
              style: AppTheme.body(
                  size: 14, weight: FontWeight.w500, color: MyTheme.dark_grey)),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButton<PaymentStatus>(
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(MyTheme.radius_control),
              icon: Icon(Icons.expand_more_rounded, color: MyTheme.dark_grey),
              style: AppTheme.body(
                  size: 14, weight: FontWeight.w600, color: MyTheme.navy),
              value: _selectedPaymentStatus,
              items: _dropdownPaymentStatusItems,
              onChanged: (PaymentStatus? selectedFilter) {
                if (selectedFilter == null ||
                    selectedFilter == _selectedPaymentStatus) return;
                setState(() => _selectedPaymentStatus = selectedFilter);
                reset();
                fetchData();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Delivery-status switch on the navy bar, same look as the delivery app's
/// pending-stage switch. Scrolls sideways because there are seven stages.
class _StatusSwitch extends StatelessWidget {
  const _StatusSwitch({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<DeliveryStatus> options;
  final DeliveryStatus? selected;
  final ValueChanged<DeliveryStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MyTheme.radius_control),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final s in options)
            Semantics(
              button: true,
              selected: s.option_key == selected?.option_key,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (s.option_key != selected?.option_key) onChanged(s);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: s.option_key == selected?.option_key
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(MyTheme.radius_control - 4),
                  ),
                  child: Text(
                    s.name,
                    maxLines: 1,
                    style: AppTheme.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: s.option_key == selected?.option_key
                          ? MyTheme.navy
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One order, laid out like a parcel label: order code and amount lead, the
/// payment line says whether the money is in, the delivery stage is a pill.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onOpen});

  final dynamic order;
  final VoidCallback onOpen;

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final l = LangText(context: context).getLocal();
    final paymentRaw = (order.paymentStatus ?? '').toString();
    final paid = paymentRaw.toLowerCase() == "paid";
    final delivery = (order.deliveryStatus ?? '').toString();

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MyTheme.radius_card),
        side: const BorderSide(color: MyTheme.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.order_code_ucf,
                            style: AppTheme.body(
                                size: 12,
                                weight: FontWeight.w500,
                                color: MyTheme.dark_grey)),
                        const SizedBox(height: 2),
                        Text(order.orderCode ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.figure(18, color: MyTheme.navy).copyWith(
                                height: 1.2,
                                letterSpacing: 0,
                                fontVariations: const [
                                  FontVariation('wght', 700),
                                  FontVariation('wdth', 88),
                                ])),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(order.orderDate ?? '',
                          style: AppTheme.body(
                              size: 12,
                              weight: FontWeight.w500,
                              color: MyTheme.dark_grey)),
                      const SizedBox(height: 2),
                      Text(order.total ?? '',
                          style: AppTheme.figure(18, color: MyTheme.navy).copyWith(
                                height: 1.2,
                                letterSpacing: 0,
                                fontVariations: const [
                                  FontVariation('wght', 700),
                                  FontVariation('wdth', 88),
                                ])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(paid ? Icons.check_circle_rounded : Icons.error_rounded,
                      size: 18, color: paid ? MyTheme.green : MyTheme.red),
                  const SizedBox(width: 6),
                  Text(paid ? l.paid_ucf : (paymentRaw.isEmpty ? l.unpaid_ucf : _cap(paymentRaw)),
                      style: AppTheme.body(
                          size: 14,
                          weight: FontWeight.w600,
                          color: paid ? MyTheme.green : MyTheme.red)),
                  const Spacer(),
                  if (delivery.isNotEmpty) _StatusPill(label: _cap(delivery)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onOpen,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    foregroundColor: MyTheme.navy,
                    side: const BorderSide(color: MyTheme.hairline, width: 1.5),
                  ),
                  icon: const Icon(Icons.assignment_outlined, size: 18),
                  label: Text(l.view_details_ucf,
                      style: AppTheme.body(
                          size: 14,
                          weight: FontWeight.w600,
                          color: MyTheme.navy)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Delivery stage as a tinted pill. Colour carries meaning: green done,
/// red cancelled, amber waiting on the seller, blue moving.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final k = label.toLowerCase();
    final Color fg;
    final Color bg;
    if (k.contains('deliver')) {
      fg = MyTheme.green;
      bg = MyTheme.green.withValues(alpha: 0.10);
    } else if (k.contains('cancel')) {
      fg = MyTheme.red;
      bg = MyTheme.red.withValues(alpha: 0.10);
    } else if (k.contains('pending')) {
      fg = MyTheme.amber_ink;
      bg = MyTheme.amber_soft;
    } else {
      fg = MyTheme.royal;
      bg = MyTheme.blue_tint;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: AppTheme.body(size: 12, weight: FontWeight.w700, color: fg)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Column(
        children: [
          Icon(icon, size: 40, color: MyTheme.dark_grey),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: AppTheme.body(size: 15, color: MyTheme.dark_grey)),
        ],
      ),
    );
  }
}

/// Stands in for a card while the first page loads.
class _OrderCardPlaceholder extends StatelessWidget {
  const _OrderCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
              color: MyTheme.paper, borderRadius: BorderRadius.circular(6)),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MyTheme.radius_card),
        border: Border.all(color: MyTheme.hairline),
      ),
      child: Shimmer.fromColors(
        baseColor: MyTheme.shimmer_base,
        highlightColor: MyTheme.shimmer_highlighted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [bar(150, 20), const Spacer(), bar(80, 20)]),
            const SizedBox(height: 12),
            bar(120, 14),
            const SizedBox(height: 16),
            bar(double.infinity, 48),
          ],
        ),
      ),
    );
  }
}
