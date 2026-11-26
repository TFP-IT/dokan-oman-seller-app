import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// In-app seller notifications list (`GET /seller/muskila/notifications`).
class HmNotificationsScreen extends StatefulWidget {
  const HmNotificationsScreen({super.key});

  @override
  State<HmNotificationsScreen> createState() => _HmNotificationsScreenState();
}

class _HmNotificationsScreenState extends State<HmNotificationsScreen> {
  final _repo = HmRepository();
  final List<HmNotification> _items = [];
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
      final p = await _repo.notifications();
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

  Future<void> _markAllRead() async {
    try {
      await _repo.markAllNotificationsRead();
      hmToast("All notifications marked as read.");
      _load();
    } catch (e) {
      hmToastError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: hmAppBar(
        context,
        "Notifications",
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text("Mark all read"),
          ),
        ],
      ),
      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _items.isEmpty
              ? HmErrorView(message: hmErrorText(_error!), onRetry: _load)
              : RefreshIndicator(
                  color: MyTheme.navy,
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? const HmEmptyView(
                          text: "No notifications yet.",
                          icon: Icons.notifications_none_rounded,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final n = _items[i];
                            return HmCard(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: BoxDecoration(
                                      color: n.unread
                                          ? MyTheme.navy
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                n.title,
                                                style: AppTheme.body(
                                                  size: 14.5,
                                                  weight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              n.timeText,
                                              style: AppTheme.body(
                                                size: 11,
                                                color: MyTheme.medium_grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          n.body,
                                          style: AppTheme.body(
                                            size: 13,
                                            color: MyTheme.dark_grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

