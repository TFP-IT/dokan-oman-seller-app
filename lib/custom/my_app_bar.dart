import 'package:active_ecommerce_seller_app/custom/common_style.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

class MyAppBar {
  bool? centerTitle = false;
  String? title;
  BuildContext? context;
  PreferredSizeWidget? bottom;

  MyAppBar({this.title, this.context, this.centerTitle, this.bottom});

  AppBar show({var elevation = 5.0}) {
    return AppBar(automaticallyImplyLeading: false,
      bottom: bottom,
      leadingWidth: 0.0,
      centerTitle: centerTitle,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      shape: const Border(bottom: BorderSide(color: MyTheme.hairline)),
      title: Row(
        children: [
          BackChip(onTap: () => Navigator.pop(context!)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title!,
              overflow: TextOverflow.ellipsis,
              style: MyTextStyle().appbarText(),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      /*leading:Container(
        margin: EdgeInsets.only(left: 10),
        child: IconButton(

          iconSize: 20,
          splashRadius: 15,
          padding: EdgeInsets.zero,
            onPressed: (){
          Navigator.pop(context);
        }, icon: Image.asset(
          'assets/icon/back_arrow.png',
          height: 20,
          width: 20,
          //color: MyTheme.dark_grey,
        ),),
      ),*/
    );
  }

  AppBar copyWithBottom(
      {var elevation = 5.0,
      Widget bottom = const SizedBox(
        height: 0,
        width: 0,
      ),
      Size size = const Size(0, 0)}) {
    return AppBar(
      leadingWidth: 0.0,
      centerTitle: centerTitle,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      shape: const Border(bottom: BorderSide(color: MyTheme.hairline)),
      title: Row(
        children: [
          BackChip(onTap: () => Navigator.pop(context!)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title!,
              overflow: TextOverflow.ellipsis,
              style: MyTextStyle().appbarText(),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      bottom: PreferredSize(
        preferredSize: size,
        child: bottom,
      ),
      /*leading:Container(
        margin: EdgeInsets.only(left: 10),
        child: IconButton(

          iconSize: 20,
          splashRadius: 15,
          padding: EdgeInsets.zero,
            onPressed: (){
          Navigator.pop(context);
        }, icon: Image.asset(
          'assets/icon/back_arrow.png',
          height: 20,
          width: 20,
          //color: MyTheme.dark_grey,
        ),),
      ),*/
    );
  }
}


/// Rounded back button used in every app bar.
class BackChip extends StatelessWidget {
  const BackChip({super.key, required this.onTap, this.onDark = false});
  final VoidCallback onTap;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: Material(
        color: onDark ? Colors.white.withValues(alpha: 0.12) : MyTheme.light_grey,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.arrow_back_rounded,
                size: 20, color: onDark ? Colors.white : MyTheme.navy),
          ),
        ),
      ),
    );
  }
}
