import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/custom/device_info.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

class MyTextStyle {
  static TextStyle smallFontSize() {
    return AppTheme.body(size: 12, color: MyTheme.dark_grey);
  }

  static TextStyle normalStyle() {
    return AppTheme.body(size: 14, color: MyTheme.ink);
  }

  static TextStyle bigFontSize() {
    return AppTheme.display(size: 18, weight: FontWeight.w500, color: MyTheme.ink);
  }

  TextStyle dashboardBoxNumber(context) {
    final w = DeviceInfo(context).getWidth() / 100;
    // Used inside fixed-height boxes (products, withdraw, auction): keep tight.
    return AppTheme.display(
        size: (w * 5).clamp(16.0, 22.0),
        weight: FontWeight.w700,
        color: MyTheme.white,
        height: 1.15);
  }

  TextStyle dashboardBoxText(context) {
    final w = DeviceInfo(context).getWidth() / 100;
    return AppTheme.body(
        size: (w * 3.3).clamp(11.0, 13.0),
        weight: FontWeight.w500,
        color: MyTheme.white.withValues(alpha: 0.78),
        height: 1.2);
  }

  TextStyle appbarText() {
    return AppTheme.display(size: 17, weight: FontWeight.w600, color: MyTheme.ink);
  }
}
