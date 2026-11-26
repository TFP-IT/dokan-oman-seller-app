import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/muskila_seller_main.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/screens/service_chooser.dart';
import 'package:flutter/material.dart';

class MuskilaSellerSession {
  /// Opens the Hal Al Mushkila Specialist / Pro dashboard
  static Future<Widget> startScreen() async {
    return const MuskilaSellerMain();
  }

  /// Live status on the Service Chooser card
  static Future<ServiceStatus?> getStatus() async {
    try {
      final profile = await MuskilaSellerApi.instance.getProfile();
      final bookings = await MuskilaSellerApi.instance.getBookings();
      final activeCount = bookings.where((b) => b.step < 4).length;

      if (!profile.isOnline) {
        return ServiceStatus("Unavailable (Paused)", MyTheme.medium_grey);
      }

      if (activeCount > 0) {
        return ServiceStatus("$activeCount active booking${activeCount > 1 ? 's' : ''}", MyTheme.green);
      }

      return const ServiceStatus("Available for service", MyTheme.navy);
    } catch (_) {
      return ServiceStatus("Specialist active", MyTheme.green);
    }
  }
}
