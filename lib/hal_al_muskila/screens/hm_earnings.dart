import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// Wallet-style earnings matching `ChEarningsScreen` 1-to-1.
class HmEarningsScreen extends StatefulWidget {
  const HmEarningsScreen({super.key});

  @override
  State<HmEarningsScreen> createState() => _HmEarningsScreenState();
}

class _HmEarningsScreenState extends State<HmEarningsScreen> {
  final _repo = HmRepository();
  HmEarnings? _e;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final e = await _repo.earnings();
      if (mounted) {
        setState(() {
          _e = e;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _e;
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: hmAppBar(context, "Earnings"),
      body: e == null
          ? (_error != null
              ? HmErrorView(message: hmErrorText(_error!), onRetry: _load)
              : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              color: MyTheme.navy,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: MyTheme.navy,
                      borderRadius: BorderRadius.circular(MyTheme.radius_card),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Balance due to you",
                          style: AppTheme.body(
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hmMoney(e.balanceDue, e.currency),
                          style: AppTheme.figure(34, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Paid out so far: ${hmMoney(e.paidOut, e.currency)}",
                          style: AppTheme.body(size: 13, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Payouts are made by the admin office.",
                          style: AppTheme.body(
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _box(
                          "Pending",
                          "${e.pendingBookings} jobs",
                          "Customers paid ${hmMoney(e.pendingCustomerTotal, e.currency)}. Released after customer sign-off.",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _box(
                          "Released",
                          hmMoney(e.releasedEarning, e.currency),
                          "${e.releasedBookings} jobs · commission ${hmMoney(e.releasedCommission, e.currency)}",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _title("Recent releases"),
                  if (e.recentReleases.isEmpty) _none("No releases yet."),
                  ...e.recentReleases.map(
                    (r) => _row(
                      "${r.code} ${r.serviceTitle}".trim(),
                      hmDateTime(r.releasedAt),
                      "+${hmMoney(r.yourEarning, e.currency)}",
                      "fee ${hmMoney(r.commission, e.currency)}",
                    ),
                  ),
                  const SizedBox(height: 20),
                  _title("Recent payments"),
                  if (e.recentPayments.isEmpty) _none("No payments yet."),
                  ...e.recentPayments.map(
                    (p) => _row(
                      p.method.isEmpty ? "Payment" : p.method,
                      [p.reference, hmDateTime(p.paidAt)]
                          .where((s) => s.isNotEmpty)
                          .join(" · "),
                      hmMoney(p.amount, e.currency),
                      null,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _box(String label, String value, String sub) => HmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTheme.body(size: 12, color: MyTheme.medium_grey)),
            const SizedBox(height: 6),
            FittedBox(child: Text(value, style: AppTheme.display(size: 18))),
            const SizedBox(height: 4),
            Text(sub,
                style: AppTheme.body(size: 11, color: MyTheme.medium_grey)),
          ],
        ),
      );

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: AppTheme.body(
            size: 15,
            weight: FontWeight.w600,
            color: MyTheme.ink,
          ),
        ),
      );

  Widget _none(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(t,
            style: AppTheme.body(size: 13, color: MyTheme.medium_grey)),
      );

  Widget _row(String title, String sub, String amount, String? amountSub) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: HmCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: MyTheme.ink,
                      ),
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        style: AppTheme.body(
                          size: 12,
                          color: MyTheme.medium_grey,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: AppTheme.body(
                      size: 14,
                      weight: FontWeight.w700,
                      color: MyTheme.green,
                    ),
                  ),
                  if (amountSub != null)
                    Text(
                      amountSub,
                      style: AppTheme.body(
                        size: 11,
                        color: MyTheme.medium_grey,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}

