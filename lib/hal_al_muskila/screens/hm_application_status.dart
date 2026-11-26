import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_session.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_ui.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_main.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_profile.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/screens/service_chooser.dart';
import 'package:flutter/material.dart';

/// Application gate while pending or rejected (mirrors `ChApplicationStatus`).
class HmApplicationStatus extends StatefulWidget {
  final HmApplication? initial;

  const HmApplicationStatus({super.key, this.initial});

  @override
  State<HmApplicationStatus> createState() => _HmApplicationStatusState();
}

class _HmApplicationStatusState extends State<HmApplicationStatus> {
  final _repo = HmRepository();
  HmApplication? _app;
  Object? _error;
  bool _busy = false;
  String? _resubmitKey;

  static const _checkNames = {
    "national_id": "National ID",
    "selfie": "Selfie check",
    "phone": "Phone",
    "address": "Address",
    "work_permit": "Work permit",
    "trade_licence": "Trade licence",
    "police_clearance": "Police clearance",
    "skill_test": "Skill test",
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
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HmMain()),
          (r) => false,
        );
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
    _resubmitKey ??= HmApi.newIdempotencyKey();
    try {
      final a = await _repo.resubmit(_resubmitKey!);
      _resubmitKey = null;
      hmToast("Application sent again. We'll review it soon.");
      if (mounted) setState(() => _app = a.id == null ? _app : a);
      await _load();
    } on HmApiException catch (e) {
      if (e.status != 0) _resubmitKey = null;
      hmToast(e.message);
    } catch (e) {
      hmToastError(e);
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
        title: Text(
          "Your application",
          style: AppTheme.body(size: 18, weight: FontWeight.w600, color: MyTheme.ink),
        ),
        actions: [
          TextButton(
            onPressed: () => HmSession.signOut(context),
            child: const Text("Sign out"),
          ),
        ],
      ),
      body: a == null
          ? (_error != null
              ? HmErrorView(message: hmErrorText(_error!), onRetry: _load)
              : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  HmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.proName, style: AppTheme.display(size: 20)),
                        const SizedBox(height: 8),
                        a.isRejected
                            ? const HmPill(
                                "Not approved",
                                bg: Color(0xFFFBE7E4),
                                fg: MyTheme.red,
                              )
                            : const HmPill(
                                "Under review",
                                bg: MyTheme.amber_soft,
                                fg: MyTheme.amber_ink,
                              ),
                        if (a.appliedAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Applied ${hmDateTime(a.appliedAt)}",
                            style: AppTheme.body(size: 12, color: MyTheme.medium_grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (a.isPending)
                    HmCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Our team is reviewing your specialist profile. You'll get the Hal Al Mushkila tools once it's approved.",
                            style: AppTheme.body(size: 14),
                          ),
                          if (a.missingChecks.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              "Waiting for: ${a.missingChecks.map((c) => _checkNames[c] ?? c.replaceAll("_", " ")).join(", ")}",
                              style: AppTheme.body(
                                size: 14,
                                weight: FontWeight.w600,
                                color: MyTheme.amber_ink,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (a.isRejected) ...[
                    HmCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Reason",
                            style: AppTheme.body(
                              size: 13,
                              weight: FontWeight.w600,
                              color: MyTheme.medium_grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a.rejectionReason ?? "No reason given.",
                            style: AppTheme.body(size: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    HmButton(
                      label: "Fix my profile details",
                      outlined: true,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HmProfileScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    HmButton(
                      label: "Send for review again",
                      busy: _busy,
                      onPressed: a.canResubmit ? _resubmit : null,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

