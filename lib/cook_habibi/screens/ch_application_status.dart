import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_api.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_models.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_repository.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_session.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_ui.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/screens/ch_kitchen_profile.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/screens/ch_main.dart';
import 'package:active_ecommerce_seller_app/screens/service_chooser.dart';
import 'package:flutter/material.dart';

/// Application progress while pending or rejected (guide §4).
class ChApplicationStatus extends StatefulWidget {
  final ChApplication? initial;

  const ChApplicationStatus({super.key, this.initial});

  @override
  State<ChApplicationStatus> createState() => _ChApplicationStatusState();
}

class _ChApplicationStatusState extends State<ChApplicationStatus> {
  final _repo = ChRepository();
  ChApplication? _app;
  Object? _error;
  bool _busy = false;
  String? _resubmitKey;

  static const _checkNames = {
    "civil_id": "Civil ID check",
    "kitchen_visit": "Kitchen visit",
    "health_certificate": "Health certificate",
    "documents": "Documents",
  };

  @override
  void initState() {
    super.initState();
    _app = widget.initial;
    _load();
  }

  Future<void> _load() async {
    try {
      final a = await _repo.application();
      if (!mounted) return;
      if (a.isApproved) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const ChMain()), (r) => false);
        return;
      }
      setState(() {
        _app = a;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _resubmit() async {
    setState(() => _busy = true);
    _resubmitKey ??= ChApi.newIdempotencyKey();
    try {
      final a = await _repo.resubmit(_resubmitKey!);
      _resubmitKey = null;
      chToast("Application sent again. We'll review it soon.");
      if (mounted) setState(() => _app = a.id == null ? _app : a);
      await _load();
    } on ChApiException catch (e) {
      if (e.status != 0) _resubmitKey = null;
      chToast(e.message);
    } catch (e) {
      chToastError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _app;
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: "Switch dashboard",
          icon: const Icon(Icons.apps_rounded, color: MyTheme.ink),
          onPressed: () => ServiceChooser.open(context),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text("Your application",
            style: AppTheme.body(
                size: 18, weight: FontWeight.w600, color: MyTheme.ink)),
        actions: [
          TextButton(
              onPressed: () => ChSession.signOut(context),
              child: const Text("Sign out")),
        ],
      ),
      body: a == null
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
                        Text(a.kitchenName, style: AppTheme.display(size: 20)),
                        const SizedBox(height: 8),
                        a.isRejected
                            ? ChPill("Not approved",
                                bg: const Color(0xFFFBE7E4), fg: MyTheme.red)
                            : const ChPill("Under review",
                                bg: MyTheme.amber_soft,
                                fg: MyTheme.amber_ink),
                        if (a.appliedAt != null) ...[
                          const SizedBox(height: 8),
                          Text("Applied ${chDateTime(a.appliedAt)}",
                              style: AppTheme.body(
                                  size: 12, color: MyTheme.medium_grey)),
                        ],
                      ]),
                ),
                const SizedBox(height: 12),
                if (a.isPending)
                  ChCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "Our team is reviewing your kitchen. You'll get the kitchen tools once it's approved.",
                              style: AppTheme.body(size: 14)),
                          if (a.missingChecks.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                                "Waiting for: ${a.missingChecks.map((c) => _checkNames[c] ?? c.replaceAll("_", " ")).join(", ")}",
                                style: AppTheme.body(
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: MyTheme.amber_ink)),
                          ],
                        ]),
                  ),
                if (a.isRejected) ...[
                  ChCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Reason",
                              style: AppTheme.body(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: MyTheme.medium_grey)),
                          const SizedBox(height: 4),
                          Text(a.rejectionReason ?? "No reason given.",
                              style: AppTheme.body(size: 14)),
                        ]),
                  ),
                  const SizedBox(height: 16),
                  ChButton(
                      label: "Fix my kitchen details",
                      outlined: true,
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChKitchenProfile()))),
                  const SizedBox(height: 10),
                  ChButton(
                      label: "Send for review again",
                      busy: _busy,
                      onPressed: a.canResubmit ? _resubmit : null),
                  if (!a.canResubmit)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("You can't resubmit right now.",
                          style: AppTheme.body(
                              size: 12, color: MyTheme.medium_grey)),
                    ),
                ],
              ]),
            ),
    );
  }
}
