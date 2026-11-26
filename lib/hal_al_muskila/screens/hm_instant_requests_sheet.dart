import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_ui.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_booking_detail.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// Urgent incoming match receiver pairing with `POST /muskila/instant-requests`.
class HmInstantRequestsSheet extends StatefulWidget {
  const HmInstantRequestsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(MyTheme.radius_sheet)),
      ),
      builder: (_) => const HmInstantRequestsSheet(),
    );
  }

  @override
  State<HmInstantRequestsSheet> createState() => _HmInstantRequestsSheetState();
}

class _HmInstantRequestsSheetState extends State<HmInstantRequestsSheet> {
  final _repo = HmRepository();
  List<HmInstantRequest>? _items;
  Object? _error;
  String? _busyId;
  final Map<String, String> _keys = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _repo.instantRequests();
      if (mounted) {
        setState(() {
          _items = list;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _accept(HmInstantRequest req) async {
    setState(() => _busyId = req.id);
    final key = _keys.putIfAbsent(req.id, HmApi.newIdempotencyKey);
    try {
      final booking = await _repo.acceptInstant(req.id, key);
      _keys.remove(req.id);
      if (!mounted) return;
      Navigator.pop(context);
      hmToast("Instant job accepted!");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HmBookingDetail(bookingId: booking.id, initial: booking),
        ),
      );
    } on HmApiException catch (e) {
      if (e.status != 0) _keys.remove(req.id);
      hmToast(e.message);
      _load();
    } catch (e) {
      hmToastError(e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _decline(HmInstantRequest req) async {
    setState(() => _busyId = req.id);
    try {
      hmToast(await _repo.declineInstant(req.id));
      await _load();
    } catch (e) {
      hmToastError(e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MyTheme.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const HmPill("INSTANT REQUESTS",
                      bg: MyTheme.amber_soft, fg: MyTheme.amber_ink),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: MyTheme.navy),
                    onPressed: _load,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: MyTheme.ink),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (items == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: _error != null
                      ? HmErrorView(message: hmErrorText(_error!), onRetry: _load)
                      : const Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      "No urgent requests right now.",
                      style: AppTheme.body(size: 14, color: MyTheme.medium_grey),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final r = items[i];
                      final busy = _busyId == r.id;
                      return HmCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                HmPill(r.categoryName),
                                const Spacer(),
                                Text(
                                  "${r.distanceKm.toStringAsFixed(1)} km away",
                                  style: AppTheme.body(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: MyTheme.medium_grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              r.customerName,
                              style: AppTheme.body(
                                  size: 16, weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(r.notes, style: AppTheme.body(size: 13.5)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.place_outlined,
                                    size: 16, color: MyTheme.medium_grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    r.locationText,
                                    style: AppTheme.body(
                                        size: 12.5, color: MyTheme.dark_grey),
                                  ),
                                ),
                                Text(
                                  hmMoney(r.offeredPrice),
                                  style:
                                      AppTheme.figure(20, color: MyTheme.navy),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: HmButton(
                                    label: "Decline",
                                    outlined: true,
                                    color: MyTheme.red,
                                    busy: busy,
                                    onPressed: _busyId == null
                                        ? () => _decline(r)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: HmButton(
                                    label: "Accept Job",
                                    busy: busy,
                                    onPressed: _busyId == null
                                        ? () => _accept(r)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

