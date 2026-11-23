import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/screens/ch_kitchen_home.dart';
import 'package:active_ecommerce_seller_app/custom/customDateTimes.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/screens/service_chooser.dart';
import 'package:flutter/material.dart';

/// Cook Habibi's own dashboard screen (opened from the service chooser).
class ChMain extends StatelessWidget {
  const ChMain({super.key});

  @override
  Widget build(BuildContext context) {
    final dateStyle =
        AppTheme.body(size: 12, color: Colors.white.withValues(alpha: 0.72));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ServiceChooser.open(context);
      },
      child: Scaffold(
        backgroundColor: MyTheme.paper,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: MyTheme.navy,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: AppTheme.darkStatusBar,
          titleSpacing: 4,
          leading: IconButton(
            tooltip: "Switch dashboard",
            icon: const Icon(Icons.apps_rounded, color: Colors.white),
            onPressed: () => ServiceChooser.open(context),
          ),
          title: Text("Cook Habibi",
              style: AppTheme.body(
                  size: 18, weight: FontWeight.w600, color: Colors.white)),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(CustomDateTime.getDayName,
                    style: dateStyle.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(CustomDateTime.getDate, style: dateStyle),
              ],
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: const ChKitchenHome(),
      ),
    );
  }
}
