import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

class MuskilaSellerBookingDetail extends StatefulWidget {
  final MuskilaSellerBooking booking;
  final VoidCallback? onStatusChanged;

  const MuskilaSellerBookingDetail({
    super.key,
    required this.booking,
    this.onStatusChanged,
  });

  @override
  State<MuskilaSellerBookingDetail> createState() => _MuskilaSellerBookingDetailState();
}

class _MuskilaSellerBookingDetailState extends State<MuskilaSellerBookingDetail> {
  late MuskilaSellerBooking _booking;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  Future<void> _advanceStep(int newStep) async {
    setState(() => _isUpdating = true);
    try {
      final updated = await MuskilaSellerApi.instance.updateBookingStep(_booking.id, newStep);
      if (!mounted) return;
      setState(() => _booking = updated);
      widget.onStatusChanged?.call();
      muskilaToast("Status updated: ${_stepName(newStep)}");
    } catch (e) {
      muskilaToast("Failed to update status");
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  String _stepName(int step) {
    switch (step) {
      case 0:
        return "Pending";
      case 1:
        return "Scheduled";
      case 2:
        return "On The Way";
      case 3:
        return "In Progress";
      case 4:
        return "Completed";
      default:
        return "Updated";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: muskilaAppBar(context, _booking.bookingNumber),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          MuskilaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _booking.serviceTitle,
                        style: AppTheme.body(
                          size: 16,
                          weight: FontWeight.w700,
                          color: MyTheme.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MuskilaPill.status(_booking.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _booking.categoryName,
                  style: AppTheme.body(size: 13, color: MyTheme.dark_grey),
                ),
                const Divider(height: 24, color: MyTheme.hairline),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _priceCol("Service Fee", muskilaMoney(_booking.price)),
                    _priceCol("Escrow Locked", muskilaMoney(_booking.escrowAmount)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Progress Step Timeline
          MuskilaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Service Progress",
                  style: AppTheme.body(
                    size: 15,
                    weight: FontWeight.w600,
                    color: MyTheme.ink,
                  ),
                ),
                const SizedBox(height: 16),
                _timelineStep(0, "Booking Placed", "Customer requested service", _booking.step >= 0),
                _timelineStep(1, "Accepted & Scheduled", "Confirmed for ${_booking.scheduledTimeSlot}", _booking.step >= 1),
                _timelineStep(2, "On The Way", "Travelling to customer location", _booking.step >= 2),
                _timelineStep(3, "Work In Progress", "Service currently underway", _booking.step >= 3),
                _timelineStep(4, "Completed & Signed Off", "Job verified by customer", _booking.step >= 4, isLast: true),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Customer and Location
          MuskilaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Customer & Location",
                  style: AppTheme.body(
                    size: 15,
                    weight: FontWeight.w600,
                    color: MyTheme.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    MuskilaAvatar(name: _booking.customerName, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _booking.customerName,
                            style: AppTheme.body(
                              size: 15,
                              weight: FontWeight.w600,
                              color: MyTheme.ink,
                            ),
                          ),
                          Text(
                            _booking.customerPhone,
                            style: AppTheme.body(size: 13, color: MyTheme.dark_grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone, color: MyTheme.green),
                      onPressed: () => muskilaToast("Calling ${_booking.customerPhone}..."),
                    ),
                  ],
                ),
                const Divider(height: 20, color: MyTheme.hairline),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: MyTheme.medium_grey),
                    const SizedBox(width: 8),
                    Text(
                      "${_booking.scheduledDate} • ${_booking.scheduledTimeSlot}",
                      style: AppTheme.body(size: 13, color: MyTheme.ink),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: MyTheme.medium_grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _booking.locationAddress,
                        style: AppTheme.body(size: 13, color: MyTheme.ink),
                      ),
                    ),
                  ],
                ),
                if (_booking.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MyTheme.paper,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _booking.notes,
                      style: AppTheme.body(size: 12, color: MyTheme.font_grey),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Next Step Action Button matching ChButton
          if (_booking.step < 4) ...[
            MuskilaButton(
              label: _buttonLabel(_booking.step),
              busy: _isUpdating,
              onPressed: () => _advanceStep(_booking.step + 1),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _buttonLabel(int step) {
    switch (step) {
      case 0:
        return "Accept Booking";
      case 1:
        return "Mark: On The Way";
      case 2:
        return "Start Work";
      case 3:
        return "Complete Job & Request Release";
      default:
        return "Done";
    }
  }

  Widget _priceCol(String title, String val) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.body(size: 11, color: MyTheme.medium_grey)),
          const SizedBox(height: 2),
          Text(val, style: AppTheme.figure(17, color: MyTheme.ink)),
        ],
      );

  Widget _timelineStep(int idx, String title, String sub, bool done, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? MyTheme.navy : MyTheme.grey_153.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check : Icons.circle,
                size: 12,
                color: done ? Colors.white : MyTheme.grey_153,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: done ? MyTheme.navy.withValues(alpha: 0.3) : MyTheme.hairline,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.body(
                  size: 14,
                  weight: done ? FontWeight.w600 : FontWeight.w400,
                  color: done ? MyTheme.ink : MyTheme.medium_grey,
                ),
              ),
              Text(sub, style: AppTheme.body(size: 12, color: MyTheme.medium_grey)),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
