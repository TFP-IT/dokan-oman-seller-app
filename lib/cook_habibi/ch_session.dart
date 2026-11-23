import 'package:active_ecommerce_seller_app/cook_habibi/ch_api.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_models.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_repository.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/screens/ch_application_status.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/screens/ch_main.dart';
import 'package:active_ecommerce_seller_app/helpers/auth_helper.dart';
import 'package:active_ecommerce_seller_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_seller_app/repositories/auth_repository.dart';
import 'package:active_ecommerce_seller_app/screens/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Sign-in routing, push device and sign-out for Cook Habibi (guide §3, §4).
class ChSession {
  static bool _tokenListener = false;

  /// Opening Cook Habibi: the application status while pending or rejected,
  /// otherwise the Cook Habibi dashboard.
  static Future<Widget> startScreen() async {
    try {
      final res = await ChApi.get(ChApi.seller("application"),
          signOutOnAuthError: false);
      final app = ChApplication.fromJson(chMap(chMap(res)["data"]));
      if (app.id != null && !app.isApproved) {
        return ChApplicationStatus(initial: app);
      }
    } catch (e) {
      debugPrint("cook-habibi application check: $e");
    }
    return const ChMain();
  }

  /// Registers this phone for pushes. Safe to call many times; it also
  /// re-registers when the FCM token refreshes.
  static Future<void> registerPush() async {
    if (is_logged_in.$ != true || (access_token.$ ?? "").isEmpty) return;
    if (Firebase.apps.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await ChRepository().registerDevice(token);
      if (!_tokenListener) {
        _tokenListener = true;
        FirebaseMessaging.instance.onTokenRefresh.listen((t) {
          if (is_logged_in.$ == true) {
            ChRepository().registerDevice(t).catchError((_) {});
          }
        });
      }
    } catch (e) {
      debugPrint("cook-habibi push register: $e");
    }
  }

  /// Removes the push device first, then signs out and clears the token.
  static Future<void> signOut(BuildContext context) async {
    try {
      await ChRepository().removeDevice();
    } catch (_) {}
    try {
      await AuthRepository().getLogoutResponse();
    } catch (_) {}
    AuthHelper().clearUserData();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => Login()), (r) => false);
  }
}
