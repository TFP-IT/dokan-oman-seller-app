import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/helpers/main_helper.dart';
import 'package:active_ecommerce_seller_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/refund_order_repository.dart';
import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/custom/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

class RefundRequest extends StatefulWidget {
  const RefundRequest({super.key});

  @override
  State<RefundRequest> createState() => _RefundRequestState();
}

class _RefundRequestState extends State<RefundRequest> {
  var _refundOrderList = [];
  int _page = 0;
  bool _showLoadingContainer = false;
  bool _faceData = false;
  RefundOptions? _refundOptions;

  final ScrollController _scrollController = ScrollController();
  TextEditingController rejectReasonController = TextEditingController();

  String? _rejectReason;

  getRefundOrders() async {
    var response =
        await RefundOrderRepository().getRefundOrderList(page: _page);

    if (response.data!.isEmpty && _page > 1) {
      // Only when paging past the end; the first load shows an empty state.
      ToastComponent.showDialog(
          LangText(context: context).getLocal().no_more_refund_requests_ucf,
          gravity: Toast.center,
          bgColor: MyTheme.white,
          textStyle: TextStyle(color: MyTheme.ink));
    }

    if (response.success!) {
      _refundOrderList.addAll(response.data!);
    }
    _showLoadingContainer = false;

    _faceData = true;
    print("data face$_faceData");
    setState(() {});
  }

  approveRefundReq(id) async {
    var response =
        await RefundOrderRepository().approveRefundSellerStatusRequest(id);
    refresh();
    ToastComponent.showDialog(response.message,
        gravity: Toast.bottom, duration: 2, bgColor: MyTheme.white);
  }

  rejectRefundReq(id) async {
    var sms = getDataFromTextEditingController();

    if (sms.isEmpty) {
      ToastComponent.showDialog(
          LangText(context: context).getLocal().provide_reason,
          gravity: Toast.bottom,
          duration: 2,
          bgColor: MyTheme.white);
      return;
    }
    print("true");
    var response =
        await RefundOrderRepository().rejectRefundSellerStatusRequest(id, sms);
    refresh();
    ToastComponent.showDialog(response.message,
        gravity: Toast.bottom, duration: 2, bgColor: MyTheme.white);
  }

  scrollControllerListener() {
    _scrollController.addListener(() {
      // print("position: " + _scrollController.position.pixels.toString());
      //print("max: " + _xcrollController.position.maxScrollExtent.toString());

      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setState(() {
          _page++;
        });
        _showLoadingContainer = true;
        fetchData();
      }
    });
  }

  setDataInTextEditingController(text) {
    rejectReasonController.text = text ?? "";
    setState(() {});
  }

  String getDataFromTextEditingController() {
    return rejectReasonController.text.trim();
  }

  fetchData() {
    getRefundOrders();
  }

  clearData() {
    _faceData = false;
    _refundOrderList = [];
    _page = 0;
    _showLoadingContainer = false;
    setState(() {});
  }

  Future<void> refresh() async {
    clearData();
    fetchData();
  }

  @override
  void initState() {
    // TODO: implement initState
    scrollControllerListener();
    fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l = LangText(context: context).getLocal();
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: settingsAppBar(context, l.refund_requests_ucf),
      body: RefreshIndicator(
        color: MyTheme.navy,
        backgroundColor: Colors.white,
        onRefresh: refresh,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (!_faceData)
              ...List.generate(
                  5,
                  (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(MyTheme.radius_card),
                          child:
                              ShimmerHelper().buildBasicShimmer(height: 104.0),
                        ),
                      ))
            else if (_refundOrderList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 96),
                child: Column(
                  children: [
                    Icon(Icons.assignment_return_outlined,
                        size: 40, color: MyTheme.dark_grey),
                    const SizedBox(height: 12),
                    Text(l.no_data_is_available,
                        textAlign: TextAlign.center,
                        style:
                            AppTheme.body(size: 16, color: MyTheme.dark_grey)),
                  ],
                ),
              )
            else ...[
              for (int i = 0; i < _refundOrderList.length; i++)
                refundReqItem(context, i),
              moreLoading(),
            ],
          ],
        ),
      ),
    );
  }

  /// Colour for a refund status: 1 approved, 0 pending, anything else rejected.
  (Color fg, Color bg, IconData icon) _statusLook(dynamic status) {
    if (status == 1) {
      return (MyTheme.green, MyTheme.green.withValues(alpha: 0.10),
          Icons.check_circle_rounded);
    }
    if (status == 0) {
      return (MyTheme.amber_ink, MyTheme.amber_soft, Icons.schedule_rounded);
    }
    return (MyTheme.red, MyTheme.red.withValues(alpha: 0.10),
        Icons.cancel_rounded);
  }

  Widget refundReqItem(BuildContext context, int index) {
    final item = _refundOrderList[index];
    final (fg, bg, icon) = _statusLook(item.refundStatus);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MyTheme.radius_card),
          side: const BorderSide(color: MyTheme.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            showStatusChangeDialog(item.id, item.refundStatus,
                item.seller_approval, item.refundReson, item.rejectReson);
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(getLocal(context).order_code_ucf,
                          style: AppTheme.body(
                              size: 12,
                              weight: FontWeight.w500,
                              color: MyTheme.dark_grey)),
                      Text("${item.orderCode ?? ""}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.figure(18, color: MyTheme.navy)
                              .copyWith(height: 1.3, letterSpacing: 0)),
                      if ((item.productName ?? "").toString().isNotEmpty)
                        Text("${item.productName}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppTheme.body(size: 14, color: MyTheme.ink)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(999)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 14, color: fg),
                                const SizedBox(width: 4),
                                Text("${item.refundLabel ?? ""}",
                                    style: AppTheme.body(
                                        size: 12,
                                        weight: FontWeight.w700,
                                        color: fg)),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_outlined,
                                  size: 14, color: MyTheme.dark_grey),
                              const SizedBox(width: 4),
                              Text("${item.date ?? ""}",
                                  style: AppTheme.body(
                                      size: 13, color: MyTheme.dark_grey)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(item.productPrice.toString(),
                    style: AppTheme.figure(20, color: MyTheme.navy)
                        .copyWith(height: 1.2, letterSpacing: 0)),
                Icon(Icons.chevron_right_rounded,
                    size: 22, color: MyTheme.dark_grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom sheet with the customer's reason and, while pending, the
  /// approve / reject choice.
  Future showStatusChangeDialog(
      id, refundStatus, sellerApproval, String? refundSMS, rejectReason) {
    _refundOptions =
        sellerApproval == 2 ? RefundOptions.Reject : RefundOptions.Approve;
    setDataInTextEditingController(rejectReason);
    final canDecide = sellerApproval == 0 && refundStatus != 2;
    var showFullText = false;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        final l = LangText(context: context).getLocal();
        return StatefulBuilder(builder: (context, setSheet) {
          Widget choice(RefundOptions option, String label, String doneLabel,
              IconData icon, Color color) {
            final selected = _refundOptions == option;
            final done = (option == RefundOptions.Approve && sellerApproval == 1) ||
                (option == RefundOptions.Reject && sellerApproval == 2);
            return Expanded(
              child: Material(
                color: selected ? color.withValues(alpha: 0.10) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MyTheme.radius_control),
                  side: BorderSide(
                      color: selected ? color : MyTheme.hairline, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: sellerApproval == 0
                      ? () => setSheet(() => _refundOptions = option)
                      : null,
                  child: SizedBox(
                    height: 52,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon,
                            size: 20,
                            color: selected ? color : MyTheme.dark_grey),
                        const SizedBox(width: 8),
                        Text(done ? doneLabel : label,
                            style: AppTheme.body(
                                size: 15,
                                weight: FontWeight.w600,
                                color: selected ? color : MyTheme.ink)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.refund_reason_ucf,
                        style: AppTheme.body(
                            size: 18,
                            weight: FontWeight.w600,
                            color: MyTheme.navy)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: MyTheme.paper,
                        borderRadius:
                            BorderRadius.circular(MyTheme.radius_control),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            refundSMS ?? "",
                            maxLines: showFullText ? null : 3,
                            overflow: showFullText
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: AppTheme.body(
                                size: 15, color: MyTheme.ink, height: 1.4),
                          ),
                          if ((refundSMS ?? "").length > 120)
                            TextButton(
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 36)),
                              onPressed: () => setSheet(
                                  () => showFullText = !showFullText),
                              child: Text(showFullText ? "Show less" : "Read more"),
                            ),
                        ],
                      ),
                    ),
                    if (refundStatus != 2) ...[
                      const SizedBox(height: 20),
                      Text(l.seller_approval_ucf,
                          style: AppTheme.body(
                              size: 16,
                              weight: FontWeight.w600,
                              color: MyTheme.navy)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (sellerApproval == 0 || sellerApproval == 1)
                            choice(RefundOptions.Approve, l.approve_ucf,
                                l.approved_ucf, Icons.check_rounded,
                                MyTheme.green),
                          if (sellerApproval == 0) const SizedBox(width: 12),
                          if (sellerApproval == 0 || sellerApproval == 2)
                            choice(RefundOptions.Reject, l.reject_ucf,
                                l.rejected_ucf, Icons.close_rounded,
                                MyTheme.red),
                        ],
                      ),
                      if (_refundOptions == RefundOptions.Reject) ...[
                        const SizedBox(height: 12),
                        TextField(
                          readOnly: sellerApproval != 0,
                          controller: rejectReasonController,
                          minLines: 3,
                          maxLines: 5,
                          style: AppTheme.body(size: 15, color: MyTheme.ink),
                          decoration: InputDecoration(hintText: l.type_reason),
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: MyTheme.hairline, width: 1.5),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: Text(l.close_ucf,
                                  style: AppTheme.body(
                                      size: 15,
                                      weight: FontWeight.w600,
                                      color: MyTheme.navy)),
                            ),
                          ),
                        ),
                        if (canDecide) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: FilledButton(
                                onPressed: () {
                                  if (_refundOptions == RefundOptions.Approve) {
                                    approveRefundReq(id);
                                  } else {
                                    rejectRefundReq(id);
                                  }
                                  Navigator.pop(context);
                                },
                                child: Text(l.submit_ucf,
                                    style: AppTheme.body(
                                        size: 15,
                                        weight: FontWeight.w700,
                                        color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget moreLoading() {
    if (!_showLoadingContainer) return const SizedBox(height: 4);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3)),
      ),
    );
  }
}

enum RefundOptions { Approve, Reject }
