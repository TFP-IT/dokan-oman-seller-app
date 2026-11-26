import 'dart:async';

import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_ui.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_bookings.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_chat.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Booking detail driven by `next_actions` only (mirrors `ChOrderDetail`).
class HmBookingDetail extends StatefulWidget {
  final String bookingId;
  final HmBooking? initial;

  const HmBookingDetail({super.key, required this.bookingId, this.initial});

  @override
  State<HmBookingDetail> createState() => _HmBookingDetailState();
}

class _HmBookingDetailState extends State<HmBookingDetail> {
  final _repo = HmRepository();
  HmBooking? _booking;
  Object? _error;
  String? _busyAction;
  Timer? _ticker;
  final Map<String, String> _keys = {};

  static const _labels = {
    "accept": "Accept booking",
    "on-the-way": "Mark: On the way",
    "start-work": "Start work",
    "complete": "Mark job completed",
    "reject": "Reject booking",
    "cancel": "Cancel booking",
  };

  @override
  void initState() {
    super.initState();
    _booking = widget.initial;
    _load();
    hmBookingsRefreshTick.addListener(_load);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _booking?.step == 0 && _booking?.acceptDeadline != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    hmBookingsRefreshTick.removeListener(_load);
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final b = await _repo.booking(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = b;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _run(String action, {Map<String, dynamic>? body}) async {
    if (_busyAction != null) return;
    setState(() => _busyAction = action);
    final key = _keys.putIfAbsent(action, HmApi.newIdempotencyKey);
    try {
      final r = await _repo.bookingAction(
        widget.bookingId,
        action,
        key,
        body: body,
      );
      _keys.remove(action);
      hmToast(r.message);
      if (r.booking != null && mounted) setState(() => _booking = r.booking);
      await _load();
    } on HmApiException catch (e) {
      if (e.status != 0) _keys.remove(action);
      hmToast(e.message);
      if (e.status == 422 || e.status == 404) _load();
    } catch (e) {
      hmToastError(e);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _onAction(String action) async {
    switch (action) {
      case "reject":
      case "cancel":
        await _reasonDialog(action);
        break;
      case "on-the-way":
        await _etaDialog();
        break;
      default:
        await _run(action);
    }
  }

  Future<void> _etaDialog() async {
    int eta = 15;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text("Estimated arrival time"),
          content: Wrap(
            spacing: 8,
            children: [10, 15, 20, 30, 45].map((m) {
              return ChoiceChip(
                label: Text("$m min"),
                selected: eta == m,
                onSelected: (_) => setD(() => eta = m),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Confirm"),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await _run("on-the-way", body: {"eta_minutes": eta});
    }
  }

  Future<void> _reasonDialog(String action) async {
    final reason = TextEditingController();
    final isReject = action == "reject";
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isReject ? "Reject this booking?" : "Cancel this booking?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("The customer will receive a full escrow refund."),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              maxLength: 200,
              decoration: hmInput("Reason (optional)", hint: "e.g. Unavailable"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Back"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MyTheme.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isReject ? "Reject" : "Cancel booking"),
          ),
        ],
      ),
    );
    if (ok == true) {
      final text = reason.text.trim();
      await _run(action, body: text.isEmpty ? {} : {"reason": text});
    }
  }

  Future<void> _callCustomer(HmBooking b) async {
    try {
      final phone = await _repo.callBooking(b.id);
      final target = phone.isNotEmpty ? phone : b.customerPhone;
      if (target.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: target));
        hmToast("Customer phone copied: $target");
      }
    } catch (e) {
      if (b.customerPhone.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: b.customerPhone));
        hmToast("Phone copied: ${b.customerPhone}");
      } else {
        hmToastError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _booking;
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: hmAppBar(context, b?.bookingNumber ?? "Booking"),
      body: b == null
          ? (_error != null
              ? HmErrorView(message: hmErrorText(_error!), onRetry: _load)
              : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              color: MyTheme.navy,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  HmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            HmPill.status(b.status, b.statusTitle),
                            const SizedBox(width: 8),
                            HmPill(b.source.toUpperCase()),
                            const Spacer(),
                            if (b.step == 0 && b.acceptDeadline != null)
                              _AcceptCountdown(deadline: b.acceptDeadline!),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(b.serviceTitle, style: AppTheme.display(size: 18)),
                        if (b.categoryName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            b.categoryName,
                            style: AppTheme.body(
                                size: 13, color: MyTheme.medium_grey),
                          ),
                        ],
                        if (b.scheduledDateText.isNotEmpty ||
                            b.scheduledTimeSlot.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            "Schedule: ${[b.scheduledDateText, b.scheduledTimeSlot].where((s) => s.isNotEmpty).join(" · ")}",
                            style: AppTheme.body(size: 14),
                          ),
                        ],
                        if (b.notes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: MyTheme.amber_soft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Note: ${b.notes}",
                              style: AppTheme.body(
                                  size: 13, color: MyTheme.amber_ink),
                            ),
                          ),
                        ],
                        if (b.createdAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Placed ${hmDateTime(b.createdAt)}",
                            style: AppTheme.body(
                                size: 12, color: MyTheme.medium_grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  HmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heading("Progress"),
                        _stepRow(0, "Booking placed", b.step >= 0),
                        _stepRow(1, "Accepted & scheduled", b.step >= 1),
                        _stepRow(
                            2,
                            b.etaMinutes > 0 && b.step == 2
                                ? "On the way (ETA ${b.etaMinutes} min)"
                                : "On the way",
                            b.step >= 2),
                        _stepRow(3, "Work in progress", b.step >= 3),
                        _stepRow(
                            4,
                            b.escrowReleased
                                ? "Completed & escrow released"
                                : "Completed (awaiting customer sign-off)",
                            b.step >= 4,
                            last: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  HmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heading("Customer & Location"),
                        _line(Icons.person_outline, b.customerName),
                        if (b.customerPhone.isNotEmpty)
                          InkWell(
                            onTap: () => _callCustomer(b),
                            child: _line(Icons.phone_outlined, b.customerPhone,
                                trailing: "Copy / Call"),
                          ),
                        if (b.locationAddress.isNotEmpty)
                          InkWell(
                            onTap: () async {
                              final q = (b.lat != null && b.lng != null)
                                  ? "${b.lat},${b.lng}"
                                  : b.locationAddress;
                              await Clipboard.setData(ClipboardData(text: q));
                              hmToast("Location copied for Maps: $q");
                            },
                            child: _line(Icons.place_outlined, b.locationAddress,
                                trailing: "Copy GPS"),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  HmCard(
                    child: Column(
                      children: [
                        _amount("Service fee", b.price, b.currency),
                        _amount("Platform fee", b.platformFee, b.currency),
                        const Divider(),
                        _amount(
                          "Escrow locked",
                          b.escrowAmount,
                          b.currency,
                          bold: true,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text("Your earning", style: AppTheme.body(size: 14)),
                              const Spacer(),
                              Text(
                                b.yourEarning == null || !b.escrowReleased
                                    ? "After customer release"
                                    : hmMoney(b.yourEarning, b.currency),
                                style: AppTheme.body(
                                  size: 14,
                                  weight: FontWeight.w600,
                                  color: b.escrowReleased
                                      ? MyTheme.green
                                      : MyTheme.medium_grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            "Payment: ${b.escrowStatus}",
                            style: AppTheme.body(
                                size: 12, color: MyTheme.medium_grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (b.userRating != null) ...[
                    const SizedBox(height: 12),
                    HmCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Customer Rating: ${b.userRating!.toStringAsFixed(1)} ★",
                            style: AppTheme.body(
                                size: 14, weight: FontWeight.w700),
                          ),
                          if (b.userReview != null && b.userReview!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(b.userReview!,
                                  style: AppTheme.body(size: 13)),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (b.cancelReason != null && b.cancelReason!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    HmCard(
                      child: Text(
                        "Cancel reason: ${b.cancelReason}",
                        style: AppTheme.body(size: 14, color: MyTheme.red),
                      ),
                    ),
                  ],
                  if (b.threadId != null && b.threadId!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    HmButton(
                      label: "Chat with customer",
                      outlined: true,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HmThreadChat(
                            threadId: b.threadId!,
                            title: b.customerName,
                            subtitle: b.serviceTitle,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ..._actionButtons(b),
                ],
              ),
            ),
    );
  }

  List<Widget> _actionButtons(HmBooking b) {
    final out = <Widget>[];
    final main = b.nextActions
        .where((a) => a != "reject" && a != "cancel")
        .toList();
    for (final a in main) {
      out.add(HmButton(
        label: _labels[a] ?? a,
        busy: _busyAction == a,
        onPressed: _busyAction == null ? () => _onAction(a) : null,
      ));
      out.add(const SizedBox(height: 10));
    }
    for (final neg in ["reject", "cancel"]) {
      if (b.nextActions.contains(neg)) {
        out.add(HmButton(
          label: _labels[neg]!,
          outlined: true,
          color: MyTheme.red,
          busy: _busyAction == neg,
          onPressed: _busyAction == null ? () => _onAction(neg) : null,
        ));
        out.add(const SizedBox(height: 10));
      }
    }
    return out;
  }

  Widget _heading(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: AppTheme.body(
            size: 13,
            weight: FontWeight.w600,
            color: MyTheme.medium_grey,
          ),
        ),
      );

  Widget _line(IconData icon, String text, {String? trailing}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 18, color: MyTheme.medium_grey),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AppTheme.body(size: 14))),
            if (trailing != null)
              Text(
                trailing,
                style: AppTheme.body(
                  size: 12,
                  weight: FontWeight.w600,
                  color: MyTheme.navy,
                ),
              ),
          ],
        ),
      );

  Widget _amount(String label, double value, String cur, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              label,
              style: AppTheme.body(
                size: 14,
                weight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            Text(
              hmMoney(value, cur),
              style: AppTheme.body(
                size: 14,
                weight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _stepRow(int idx, String title, bool done, {bool last = false}) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: done ? MyTheme.navy : MyTheme.paper,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? MyTheme.navy : MyTheme.hairline,
                  ),
                ),
                child: Icon(
                  done ? Icons.check : Icons.circle,
                  size: 11,
                  color: done ? Colors.white : MyTheme.grey_153,
                ),
              ),
              if (!last)
                Container(
                  width: 2,
                  height: 24,
                  color: done
                      ? MyTheme.navy.withValues(alpha: 0.3)
                      : MyTheme.hairline,
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                title,
                style: AppTheme.body(
                  size: 13.5,
                  weight: done ? FontWeight.w600 : FontWeight.w400,
                  color: done ? MyTheme.ink : MyTheme.medium_grey,
                ),
              ),
            ),
          ),
        ],
      );
}

class _AcceptCountdown extends StatelessWidget {
  final DateTime deadline;

  const _AcceptCountdown({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final diff = deadline.difference(DateTime.now());
    final text = diff.isNegative
        ? "Expired"
        : "${diff.inMinutes}m ${(diff.inSeconds % 60).toString().padLeft(2, '0')}s";
    return Text(
      text,
      style: AppTheme.body(
        size: 12,
        weight: FontWeight.w700,
        color: diff.isNegative ? MyTheme.red : MyTheme.amber_ink,
      ),
    );
  }
}

