import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/custom/CommonFunctoins.dart';
import 'package:active_ecommerce_seller_app/custom/my_app_bar.dart';
import 'package:active_ecommerce_seller_app/custom/common_style.dart';
import 'package:active_ecommerce_seller_app/custom/customDateTimes.dart';
import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/route_transaction.dart';
import 'package:active_ecommerce_seller_app/helpers/shop_info_helper.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/screens/account.dart';
import 'package:active_ecommerce_seller_app/screens/conversation.dart';
import 'package:active_ecommerce_seller_app/screens/home.dart';
import 'package:active_ecommerce_seller_app/screens/orders.dart';
import 'package:active_ecommerce_seller_app/screens/product/products.dart';
import 'package:active_ecommerce_seller_app/screens/profile.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:active_ecommerce_seller_app/l10n/app_localizations.dart';
import 'package:route_transitions/route_transitions.dart';

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  int _currentIndex = 0;
  String title = "";
  late final _children = [
    Home(
      fromBottombar: true,
      onOpenTab: onTapped,
    ),
    Products(
      fromBottomBar: true,
    ),
    Orders(fromBottomBar: true),
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void onTapped(int i) {
    if (i == 3) {
      // setState(() {
      //   _scaffoldKey.currentState.openEndDrawer();
      // });
      //
      slideRightWidget(newPage: Account(), context: context, opaque: false);
    } else {
      setState(() {
        _currentIndex = i;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    ShopInfoHelper().setShopInfo();
    //re appear statusbar in case it was not there in the previous page
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    super.initState();
  }

  onPop(value) {}

  _onBackPressed() {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
    } else {
      CommonFunctions(context).appExitDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onBackPressed(),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: buildAppBar(),
        // drawer: MainDrawer(index: _currentIndex,),
        extendBody: false,
        body: _children[_currentIndex],
        //specify the location of the FAB
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: MyTheme.hairline)),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: onTapped,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            height: 68,
            indicatorColor: MyTheme.blue_tint,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              _navItem(0, "assets/icon/dashboard.png",
                  LangText(context: context).getLocal().dashboard_ucf),
              _navItem(1, "assets/icon/products.png",
                  LangText(context: context).getLocal().products_ucf),
              _navItem(2, "assets/icon/orders.png",
                  LangText(context: context).getLocal().orders_ucf),
              _navItem(3, "assets/icon/account.png",
                  LangText(context: context).getLocal().account_ucf),
            ],
          ),
        ),
        /*floatingActionButton: FloatingActionButton(
          //backgroundColor: MyTheme.app_accent_color,
          onPressed: () {
              MyTransaction(context: context).push(Conversation());

          },
          child: Container(
              margin: EdgeInsets.all(0.0),
              child: IconButton(
                  icon: new Image.asset(
                    'assets/icon/chat.png',
                    height: 16,
                    width: 16,
                  ),
                  tooltip: 'Action',
                  onPressed: () {
                    MyTransaction(context: context).push(Conversation());
                  })),
          elevation: 0.0,
        ),*/
      ),
    );
  }

  NavigationDestination _navItem(int index, String icon, String label) {
    final selected = _currentIndex == index;
    return NavigationDestination(
      icon: Image.asset(icon,
          height: 20,
          color: selected ? MyTheme.navy : MyTheme.grey_153),
      label: label,
    );
  }

  AppBar buildAppBar() {
    final onDashboard = _currentIndex == 0;
    // Dashboard, Products and Orders use the delivery-app navy bar.
    final navyBar = onDashboard || _currentIndex == 1 || _currentIndex == 2;
    final dateStyle = AppTheme.body(
        size: 12, color: Colors.white.withValues(alpha: 0.72));
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: navyBar ? MyTheme.navy : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle:
          navyBar ? AppTheme.darkStatusBar : AppTheme.lightStatusBar,
      shape: navyBar
          ? const Border()
          : const Border(bottom: BorderSide(color: MyTheme.hairline)),
      titleSpacing: 16,
      title: onDashboard
          ? Text(getTitle(),
              style: AppTheme.body(
                  size: 18, weight: FontWeight.w600, color: Colors.white))
          : Row(
              children: [
                BackChip(
                    onDark: navyBar,
                    onTap: () => setState(() => _currentIndex = 0)),
                const SizedBox(width: 12),
                Text(getTitle(),
                    style: navyBar
                        ? AppTheme.body(
                            size: 18,
                            weight: FontWeight.w600,
                            color: Colors.white)
                        : MyTextStyle().appbarText()),
              ],
            ),
      actions: [
        if (onDashboard)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(CustomDateTime.getDayName,
                    style: dateStyle.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(CustomDateTime.getDate, style: dateStyle),
              ],
            ),
          ),
      ],
    );
  }

  String getTitle() {
    switch (_currentIndex) {
      case 0:
        title = AppLocalizations.of(context)!.dashboard_ucf;
        break;
      case 1:
        title = AppLocalizations.of(context)!.products_ucf;
        break;
      case 2:
        title = AppLocalizations.of(context)!.orders_ucf;
        break;
      case 3:
        title = AppLocalizations.of(context)!.profile_ucf;
        break;
    }
    return title;
  }
}
