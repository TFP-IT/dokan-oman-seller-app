import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/route_transaction.dart';
import 'package:active_ecommerce_seller_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/screens/shop_settings/shop_banner_settings.dart';
import 'package:active_ecommerce_seller_app/screens/shop_settings/shop_delivery_boy_pickup_point_setting.dart';
import 'package:active_ecommerce_seller_app/screens/shop_settings/shop_general_setting.dart';
import 'package:active_ecommerce_seller_app/screens/shop_settings/shop_social_media_setting.dart';
import 'package:flutter/cupertino.dart';
import 'package:active_ecommerce_seller_app/custom/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_seller_app/l10n/app_localizations.dart';

class ShopSettings extends StatefulWidget {
  const ShopSettings({super.key});

  @override
  _ShopSettingsState createState() => _ShopSettingsState();
}

class _ShopSettingsState extends State<ShopSettings> {
  @override
  Widget build(BuildContext context) {
    final l = LangText(context: context).getLocal();
    final push = MyTransaction(context: context).push;
    final rows = <Widget>[
      SettingsLinkRow(
          iconAsset: "assets/icon/general_setting.png",
          title: l.general_setting_ucf,
          onTap: () => push(ShopGeneralSetting())),
      if (delivery_boy_addon.$)
        SettingsLinkRow(
            iconAsset: "assets/icon/delivery_boy_setting.png",
            title: l.delivery_boy_pickup_point,
            onTap: () => push(ShopDeliveryBoyPickupPoint())),
      SettingsLinkRow(
          iconAsset: "assets/icon/banner_setting.png",
          title: l.banner_settings,
          onTap: () => push(ShopBannerSettings())),
      SettingsLinkRow(
          iconAsset: "assets/icon/social_setting.png",
          title: l.social_media_link,
          onTap: () => push(ShopSocialMedialSetting())),
    ];
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: settingsAppBar(
          context, AppLocalizations.of(context)!.shop_settings_ucf),
      body: ListView(
        padding: kSettingsBodyPadding,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MyTheme.radius_card),
              border: Border.all(color: MyTheme.hairline),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(indent: 70, endIndent: 16),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
