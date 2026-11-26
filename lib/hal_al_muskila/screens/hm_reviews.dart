import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// Customer reviews & ratings screen (`GET /seller/muskila/reviews`).
class HmReviewsScreen extends StatefulWidget {
  const HmReviewsScreen({super.key});

  @override
  State<HmReviewsScreen> createState() => _HmReviewsScreenState();
}

class _HmReviewsScreenState extends State<HmReviewsScreen> {
  final _repo = HmRepository();
  final List<HmReview> _items = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _repo.reviews();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(p.items);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: hmAppBar(context, "Customer Reviews"),
      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _items.isEmpty
              ? HmErrorView(message: hmErrorText(_error!), onRetry: _load)
              : RefreshIndicator(
                  color: MyTheme.navy,
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? const HmEmptyView(
                          text: "No customer reviews yet.",
                          icon: Icons.star_outline_rounded,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final r = _items[i];
                            return HmCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          r.reviewerName,
                                          style: AppTheme.body(
                                            size: 15,
                                            weight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      HmPill(
                                        "${r.rating.toStringAsFixed(1)} ★",
                                        bg: MyTheme.amber_soft,
                                        fg: MyTheme.amber_ink,
                                      ),
                                    ],
                                  ),
                                  if (r.dateText.isNotEmpty ||
                                      r.bookingNumber.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      [r.bookingNumber, r.dateText]
                                          .where((s) => s.isNotEmpty)
                                          .join(" · "),
                                      style: AppTheme.body(
                                        size: 12,
                                        color: MyTheme.medium_grey,
                                      ),
                                    ),
                                  ],
                                  if (r.comment.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(r.comment,
                                        style: AppTheme.body(size: 13.5)),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

