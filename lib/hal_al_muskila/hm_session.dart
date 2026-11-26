import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_application_status.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_main.dart';
import 'package:active_ecommerce_seller_app/helpers/auth_helper.dart';
import 'package:active_ecommerce_seller_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/auth_repository.dart';
import 'package:active_ecommerce_seller_app/screens/login.dart';
import 'package:active_ecommerce_seller_app/screens/service_chooser.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Sign-in gate, push registration, sign-out and ServiceChooser status (mirrors `ChSession`).
class HmSession {
  static bool _tokenListener = false;

  /// Checks dashboard-created application status; pending/rejected -> gate, else dashboard.
  static Future<Widget> startScreen() async {
    try {
      final app = await HmRepository().application(signOutOnAuthError: false);
      if (app.id != null && !app.isApproved) {
        return HmApplicationStatus(initial: app);
      }
    } catch (e) {
      debugPrint("hal-al-muskila application check: $e");
    }
    return const HmMain();
  }

  /// Live status line for `ServiceChooser` card. Returns null silently if not a Pro.
  static Future<ServiceStatus?> getStatus() async {
    try {
      final repo = HmRepository();
      final app = await repo.application(signOutOnAuthError: false);
      if (app.isPending) {
        return const ServiceStatus(
            "Application under review", MyTheme.amber_ink);
      }
      if (app.isRejected) {
        return const ServiceStatus("Application needs changes", MyTheme.red);
      }
      final d = await repo.dashboard(signOutOnAuthError: false);
      final jobs = d.activeBookings == 1
          ? "1 active job"
          : "${d.activeBookings} active jobs";
      return d.isOnline
          ? ServiceStatus("Online, $jobs", MyTheme.green)
          : ServiceStatus(
              d.activeBookings > 0 ? "Offline, $jobs" : "Offline (Paused)",
              MyTheme.dark_grey,
            );
    } catch (_) {
      return null;
    }
  }

  static Future<void> registerPush() async {
    if (is_logged_in.$ != true || (access_token.$ ?? "").isEmpty) return;
    if (Firebase.apps.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await HmRepository().registerDevice(token);
      if (!_tokenListener) {
        _tokenListener = true;
        FirebaseMessaging.instance.onTokenRefresh.listen((t) {
          if (is_logged_in.$ == true) {
            HmRepository().registerDevice(t).catchError((_) {});
          }
        });
      }
    } catch (e) {
      debugPrint("hal-al-muskila push register: $e");
    }
  }

  static Future<void> signOut(BuildContext context) async {
    try {
      await HmRepository().removeDevice();
    } catch (_) {}
    try {
      await AuthRepository().getLogoutResponse();
    } catch (_) {}
    AuthHelper().clearUserData();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => Login()),
      (r) => false,
    );
  }
}

