import 'dart:async';

import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_api.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_models.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_repository.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_ui.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/screens/ch_orders.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Order detail with buttons from `next_actions` only (guide §6.1, §6.2).
class ChOrderDetail extends StatefulWidget {
  final int orderId;

  const ChOrderDetail({super.key, required this.orderId});

  @override
  State<ChOrderDetail> createState() => _ChOrderDetailState();
}

class _ChOrderDetailState extends State<ChOrderDetail> {
  final _repo = ChRepository();
  ChOrder? _order;
  Object? _error;
  String? _busyAction;
  Timer? _ticker;

  /// One key per pending user action, kept for retries after a network error
  /// (guide §11).
  final Map<String, String> _keys = {};

  static const _labels = {
    "accept": "Accept order",
    "preparing": "Start preparing",
    "ready": "Mark ready",
    "out-for-delivery": "Out for delivery",
    "handover": "Hand over (enter code)",
    "reject": "Reject",
  };

  @override
  void initState() {
    super.initState();
    _load();
    chOrdersRefreshTick.addListener(_load);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _order?.status == "placed") setState(() {});
    });
  }

  @override
  void dispose() {
    chOrdersRefreshTick.removeListener(_load);
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final o = await _repo.order(widget.orderId);
      if (mounted) setState(() {
        _order = o;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// Runs one step. Returns the error for the handover sheet to show.
  Future<ChApiException?> _run(String action,
      {Map<String, dynamic>? body}) async {
    if (_busyAction != null) return null;
    setState(() => _busyAction = action);
    final key = _keys.putIfAbsent(action, ChApi.newIdempotencyKey);
    try {
      final r = await _repo.orderAction(widget.orderId, action, key,
          body: body);
      _keys.remove(action);
      chToast(r.message);
      if (r.order != null && mounted) setState(() => _order = r.order);
      await _load();
      return null;
    } on ChApiException catch (e) {
      // server answered: the request is not remembered, start fresh next time
      if (e.status != 0) _keys.remove(action);
      if (action != "handover") chToast(e.message);
      if (e.status == 422 || e.status == 404) _load();
      return e;
    } catch (e) {
      chToastError(e);
      return null;
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _onAction(String action) async {
    switch (action) {
      case "handover":
        await _handover();
        break;
      case "reject":
        await _reject();
        break;
      default:
        await _run(action);
    }
  }

  Future<void> _reject() async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject this order?"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("The customer will get a full refund."),
          const SizedBox(height: 12),
          TextField(
              controller: reason,
              maxLength: 200,
              decoration: chInput("Reason (optional)",
                  hint: "e.g. Kitchen is full")),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: MyTheme.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Reject")),
        ],
      ),
    );
    if (ok == true) {
      final text = reason.text.trim();
      await _run("reject", body: text.isEmpty ? {} : {"reason": text});
    }
  }

  Future<void> _handover() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(MyTheme.radius_sheet))),
      builder: (ctx) => _HandoverSheet(
        onSubmit: (otp) => _run("handover", body: {"otp": otp}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = _order;
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: chAppBar(context, o?.code ?? "Order"),
      body: o == null
          ? (_error != null
              ? ChErrorView(message: chErrorText(_error!), onRetry: _load)
              : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                ChCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          ChPill.status(o.status, o.statusTitle),
                          const SizedBox(width: 8),
                          ChPill(o.isPickup ? "Pickup" : "Delivery"),
                          const Spacer(),
                          if (o.status == "placed" && o.acceptDeadline != null)
                            ChAcceptCountdown(deadline: o.acceptDeadline!),
                        ]),
                        const SizedBox(height: 14),
                        Text("${o.dishEmoji} ${o.dishName}",
                            style: AppTheme.display(size: 18)),
                        const SizedBox(height: 4),
                        Text("Quantity: ${o.qty}",
                            style: AppTheme.body(size: 14)),
                        if (o.slot != null && o.slot!.isNotEmpty)
                          Text("Time: ${o.slot}",
                              style: AppTheme.body(size: 14)),
                        if (o.note != null && o.note!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: MyTheme.amber_soft,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text("Note: ${o.note}",
                                style: AppTheme.body(
                                    size: 13, color: MyTheme.amber_ink)),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text("Placed ${chDateTime(o.createdAt)}",
                            style: AppTheme.body(
                                size: 12, color: MyTheme.medium_grey)),
                      ]),
                ),
                if (o.customerName != null ||
                    o.customerPhone != null ||
                    o.customerAddress != null) ...[
                  const SizedBox(height: 12),
                  ChCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _heading("Customer"),
                          if (o.customerName != null) _line(Icons.person_outline, o.customerName!),
                          if (o.customerPhone != null)
                            _line(Icons.phone_outlined, o.customerPhone!,
                                copy: true),
                          if (!o.isPickup && o.customerAddress != null)
                            _line(Icons.place_outlined, o.customerAddress!),
                        ]),
                  ),
                ],
                const SizedBox(height: 12),
                ChCard(
                  child: Column(children: [
                    _amount("Food", o.amounts.food, o.currency),
                    _amount("Delivery fee", o.amounts.deliveryFee, o.currency),
                    const Divider(),
                    _amount("Customer paid", o.amounts.customerPaid, o.currency,
                        bold: true),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Text("Your earning", style: AppTheme.body(size: 14)),
                        const Spacer(),
                        Text(
                            o.amounts.yourEarning == null
                                ? "After release"
                                : chMoney(o.amounts.yourEarning, o.currency),
                            style: AppTheme.body(
                                size: 14,
                                weight: FontWeight.w600,
                                color: o.amounts.yourEarning == null
                                    ? MyTheme.medium_grey
                                    : MyTheme.green)),
                      ]),
                    ),
                    if (o.amounts.escrowStatus != null)
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text("Payment: ${o.amounts.escrowStatus}",
                            style: AppTheme.body(
                                size: 12, color: MyTheme.medium_grey)),
                      ),
                  ]),
                ),
                if (o.cancelReason != null && o.cancelReason!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ChCard(
                      child: Text("Cancel reason: ${o.cancelReason}",
                          style: AppTheme.body(size: 14, color: MyTheme.red))),
                ],
                if (o.status == "out_for_delivery") ...[
                  const SizedBox(height: 12),
                  Text(
                      "The rider confirms the customer's code. You don't need to do anything.",
                      style: AppTheme.body(size: 13, color: MyTheme.medium_grey)),
                ],
                const SizedBox(height: 20),
                ..._actionButtons(o),
              ]),
            ),
    );
  }

  List<Widget> _actionButtons(ChOrder o) {
    final out = <Widget>[];
    final main = o.nextActions.where((a) => a != "reject").toList();
    for (final a in main) {
      out.add(ChButton(
        label: _labels[a] ?? a,
        busy: _busyAction == a,
        onPressed: _busyAction == null ? () => _onAction(a) : null,
      ));
      out.add(const SizedBox(height: 10));
    }
    if (o.nextActions.contains("reject")) {
      out.add(ChButton(
        label: _labels["reject"]!,
        outlined: true,
        color: MyTheme.red,
        busy: _busyAction == "reject",
        onPressed: _busyAction == null ? () => _onAction("reject") : null,
      ));
    }
    return out;
  }

  Widget _heading(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t,
          style: AppTheme.body(
              size: 13, weight: FontWeight.w600, color: MyTheme.medium_grey)));

  Widget _line(IconData icon, String text, {bool copy = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(icon, size: 18, color: MyTheme.navy),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTheme.body(size: 14))),
          if (copy)
            IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  chToast("Copied");
                }),
        ]),
      );

  Widget _amount(String label, double v, String cur, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(label, style: AppTheme.body(size: 14)),
          const Spacer(),
          Text(chMoney(v, cur),
              style: AppTheme.body(
                  size: 14,
                  weight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: MyTheme.ink)),
        ]),
      );
}

/// 4-digit pickup code keypad (guide §6.2 pickup orders).
class _HandoverSheet extends StatefulWidget {
  final Future<ChApiException?> Function(String otp) onSubmit;

  const _HandoverSheet({required this.onSubmit});

  @override
  State<_HandoverSheet> createState() => _HandoverSheetState();
}

class _HandoverSheetState extends State<_HandoverSheet> {
  String _code = "";
  String? _error;
  bool _busy = false;

  void _tap(String d) {
    if (_busy) return;
    setState(() {
      _error = null;
      if (d == "<") {
        if (_code.isNotEmpty) _code = _code.substring(0, _code.length - 1);
      } else if (_code.length < 4) {
        _code += d;
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final err = await widget.onSubmit(_code);
    if (!mounted) return;
    if (err == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _busy = false;
      _code = "";
      if (err.status == 429 ||
          err.message.toLowerCase().contains("too many")) {
        _error = "Too many wrong codes. Please try again in 15 minutes.";
      } else {
        _error = err.fieldError("otp") ?? err.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "<"];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("Enter the customer's pickup code",
              style: AppTheme.display(size: 18)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < _code.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 52,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(MyTheme.radius_control),
                  border: Border.all(
                      color: _error != null
                          ? MyTheme.red
                          : (filled ? MyTheme.navy : MyTheme.hairline),
                      width: 1.5),
                ),
                child: Text(filled ? _code[i] : "",
                    style: AppTheme.display(size: 26)),
              );
            }),
          ),
          SizedBox(
            height: 36,
            child: _error == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: AppTheme.body(size: 13, color: MyTheme.red)),
                  ),
          ),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2,
            children: keys
                .map((k) => k.isEmpty
                    ? const SizedBox()
                    : InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _tap(k),
                        child: Center(
                          child: k == "<"
                              ? const Icon(Icons.backspace_outlined)
                              : Text(k, style: AppTheme.display(size: 24)),
                        ),
                      ))
                .toList(),
          ),
          const SizedBox(height: 12),
          ChButton(
              label: "Confirm handover",
              busy: _busy,
              onPressed: _code.length == 4 ? _submit : null),
        ]),
      ),
    );
  }
}
