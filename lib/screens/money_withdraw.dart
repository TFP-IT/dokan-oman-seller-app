import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/route_transaction.dart';
import 'package:active_ecommerce_seller_app/data_model/shop_info_response.dart';
import 'package:active_ecommerce_seller_app/data_model/withdraw_list_response.dart';
import 'package:active_ecommerce_seller_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_seller_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/shop_repository.dart';
import 'package:active_ecommerce_seller_app/repositories/withdraw_repository.dart';
import 'package:active_ecommerce_seller_app/screens/withdraw_req.dart';
import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/custom/settings_ui.dart';
import 'package:flutter/material.dart';

class MoneyWithdraw extends StatefulWidget {
  const MoneyWithdraw({super.key});

  @override
  State<MoneyWithdraw> createState() => _MoneyWithdrawState();
}

class _MoneyWithdrawState extends State<MoneyWithdraw> {
  List<Withdraw> _withdraws = [];

  ShopInfo? _shop;

  bool _isLoadData = false;
  bool _isLoadShop = false;
  final int _page = 1;

  Future<bool> getReviews() async {
    var response = await WithdrawRepository().getList(_page);
    _withdraws.addAll(response.data!);
    _isLoadData = true;

    setState(() {});
    return true;
  }

  Future<bool> getShop() async {
    var response = await ShopRepository().getShopInfo();
    _shop = response.shopInfo;
    _isLoadShop = true;
    setState(() {});
    return true;
  }

  fetchData() async {
    await getReviews();
    await getShop();
  }

  clearData() async {
    _withdraws = [];
    _isLoadData = false;
    _shop = null;
    _isLoadShop = false;
    setState(() {});
  }

  Future<void> reFresh() async {
    clearData();
    await fetchData();
    return Future.delayed(const Duration(microseconds: 100));
  }

  @override
  void initState() {
    fetchData();

    super.initState();
  }

  void _openRequest() {
    MyTransaction(context: context)
        .push(SendAWithdrwRequest())
        .then((value) => reFresh());
  }

  @override
  Widget build(BuildContext context) {
    final l = LangText(context: context).getLocal();
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.paper,
        appBar: settingsAppBar(context, l.money_withdraw_ucf.trim()),
        body: RefreshIndicator(
          color: MyTheme.navy,
          backgroundColor: Colors.white,
          onRefresh: reFresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              buildTop2BoxContainer(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: withdrawListContainer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Navy hero: pending balance as the big number, gold "send request".
  Widget buildTop2BoxContainer(BuildContext context) {
    final l = LangText(context: context).getLocal();
    final balance = _isLoadShop ? _shop?.adminToPay?.toString() : null;
    return Container(
      color: MyTheme.navy,
      child: InkWell(
        onTap: _openRequest,
        splashColor: Colors.white24,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 16, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.pending_balance_ucf,
                        style: AppTheme.body(
                            size: 16,
                            weight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8))),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(balance ?? "–",
                          maxLines: 1,
                          style: AppTheme.figure(64,
                              color: balance == null
                                  ? Colors.white.withValues(alpha: 0.35)
                                  : Colors.white)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 12),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                          color: MyTheme.amber, shape: BoxShape.circle),
                      child: const Icon(Icons.north_east_rounded,
                          color: MyTheme.navy),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 96,
                      child: Text(l.send_withdraw_request_ucf,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: AppTheme.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget withdrawListContainer() {
    final l = LangText(context: context).getLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(l.withdraw_ucf,
              style: AppTheme.body(
                  size: 18, weight: FontWeight.w600, color: MyTheme.navy)),
        ),
        if (!_isLoadData)
          ...List.generate(
              4,
              (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(MyTheme.radius_card),
                      child: ShimmerHelper().buildBasicShimmer(height: 76.0),
                    ),
                  ))
        else if (_withdraws.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 64),
            child: Column(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 40, color: MyTheme.dark_grey),
                const SizedBox(height: 12),
                Text(l.no_history_is_available,
                    textAlign: TextAlign.center,
                    style: AppTheme.body(size: 16, color: MyTheme.dark_grey)),
              ],
            ),
          )
        else
          for (int i = 0; i < _withdraws.length; i++)
            withdrawItem(i, _withdraws[i].status ?? "",
                _withdraws[i].createdAt, _withdraws[i].amount ?? ""),
      ],
    );
  }

  Widget withdrawItem(
      int id, String withdrawStatus, withdrawCreatedAt, String withdrawPrice) {
    final pending = withdrawStatus.toLowerCase().contains("pend");
    final color = pending ? MyTheme.amber_ink : MyTheme.green;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MyTheme.radius_card),
        border: Border.all(color: MyTheme.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: pending ? MyTheme.amber_soft : MyTheme.green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(MyTheme.radius_control),
            ),
            child: Icon(
                pending ? Icons.schedule_rounded : Icons.check_rounded,
                size: 22,
                color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: pending
                        ? MyTheme.amber_soft
                        : MyTheme.green.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(withdrawStatus,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(
                          size: 12, weight: FontWeight.w700, color: color)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.event_outlined,
                        size: 14, color: MyTheme.dark_grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text("${withdrawCreatedAt ?? ""}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                              size: 13, color: MyTheme.dark_grey)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(withdrawPrice,
              style: AppTheme.figure(22, color: MyTheme.navy)
                  .copyWith(height: 1.2, letterSpacing: 0)),
        ],
      ),
    );
  }
}
