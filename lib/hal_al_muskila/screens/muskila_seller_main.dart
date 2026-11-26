import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/custom/customDateTimes.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/muskila_seller_bookings.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/muskila_seller_chat.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/muskila_seller_dashboard.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/muskila_seller_job_board.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/muskila_seller_profile.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/screens/service_chooser.dart';
import 'package:flutter/material.dart';

/// Hal Al Mushkila Specialist / Pro seller main shell with persistent bottom navigation.
class MuskilaSellerMain extends StatefulWidget {
  const MuskilaSellerMain({super.key});

  @override
  State<MuskilaSellerMain> createState() => _MuskilaSellerMainState();
}

class _MuskilaSellerMainState extends State<MuskilaSellerMain> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardTab(onSwitchTab: (i) => setState(() => _index = i)),
      const MuskilaSellerBookingsScreen(showBack: false),
      const MuskilaSellerJobBoardScreen(showBack: false),
      const MuskilaSellerProfileScreen(showBack: false),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_index != 0) {
            setState(() => _index = 0);
          } else {
            ServiceChooser.open(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: MyTheme.paper,
        body: IndexedStack(
          index: _index,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: MyTheme.hairline)),
            boxShadow: [
              BoxShadow(
                color: MyTheme.app_accent_shado,
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: Colors.white,
              elevation: 0,
              height: 64,
              indicatorColor: MyTheme.blue_tint,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return AppTheme.body(
                  size: 11.5,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? MyTheme.navy : MyTheme.medium_grey,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: 22,
                  color: selected ? MyTheme.navy : MyTheme.medium_grey,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: "Home",
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment_rounded),
                  label: "Bookings",
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: "Job Leads",
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final ValueChanged<int> onSwitchTab;

  const _DashboardTab({required this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final dateStyle =
        AppTheme.body(size: 11, color: Colors.white.withValues(alpha: 0.72));

    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: MyTheme.navy_deep,
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
        title: Row(
          children: [
            Flexible(
              child: Text(
                "Hal Al Mushkila",
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body(
                  size: 17,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: MyTheme.amber,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "PRO",
                style: AppTheme.body(
                  size: 10,
                  weight: FontWeight.w800,
                  color: MyTheme.navy_deep,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Messages",
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.white, size: 21),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MuskilaSellerChatScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  CustomDateTime.getDayName,
                  style: dateStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(CustomDateTime.getDate, style: dateStyle),
              ],
            ),
          ),
        ],
      ),
      body: MuskilaSellerDashboard(onSwitchTab: onSwitchTab),
    );
  }
}
