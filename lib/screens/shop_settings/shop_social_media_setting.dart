import 'dart:convert';

import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/helpers/main_helper.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/shop_repository.dart';
import 'package:active_ecommerce_seller_app/custom/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

class ShopSocialMedialSetting extends StatefulWidget {
  const ShopSocialMedialSetting({super.key});

  @override
  State<ShopSocialMedialSetting> createState() =>
      _ShopSocialMedialSettingState();
}

class _ShopSocialMedialSettingState extends State<ShopSocialMedialSetting> {
  TextEditingController facebookEditController = TextEditingController();
  TextEditingController instagramEditController = TextEditingController();
  TextEditingController twitterEditController = TextEditingController();
  TextEditingController googleEditController = TextEditingController();
  TextEditingController youtubeEditController = TextEditingController();

  late BuildContext loadingContext;

  Future<bool> _getAccountInfo() async {
    var response = await ShopRepository().getShopInfo();
    Navigator.pop(loadingContext);
    facebookEditController.text = response.shopInfo!.facebook!;
    instagramEditController.text = response.shopInfo!.instagram;
    twitterEditController.text = response.shopInfo!.twitter!;
    googleEditController.text = response.shopInfo!.google!;
    youtubeEditController.text = response.shopInfo!.youtube!;

    setState(() {});
    return true;
  }

  faceData() {
    WidgetsBinding.instance.addPostFrameCallback((_) => loadingShow(context));
    _getAccountInfo();
  }

  updateInfo() async {
    var postBody = jsonEncode({
      "facebook": facebookEditController.text.trim().toString(),
      "instagram": instagramEditController.text.trim().toString(),
      "google": googleEditController.text.trim().toString(),
      "twitter": twitterEditController.text.trim().toString(),
      "youtube": youtubeEditController.text.trim().toString(),
    });
    loadingShow(context);
    var response = await ShopRepository().updateShopSetting(postBody);
    Navigator.pop(loadingContext);

    ToastComponent.showDialog(response.message,
        bgColor: MyTheme.white,
        duration: Toast.lengthLong,
        gravity: Toast.center);
  }

  Future onRefresh() {
    faceData();
    return Future.delayed(Duration(seconds: 0));
  }

  @override
  void initState() {
    faceData();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final l = LangText(context: context).getLocal();
    Widget link(String label, TextEditingController c, {bool last = false}) =>
        SettingsField(
          label: label,
          bottomGap: last ? 0 : 16,
          child: SettingsTextField(
              controller: c,
              hint: "https://",
              keyboardType: TextInputType.url,
              prefixIcon: Icons.link_rounded),
        );
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: settingsAppBar(context, l.social_media_link),
      bottomNavigationBar:
          SettingsSaveBar(label: l.save_ucf, onPressed: updateInfo),
      body: RefreshIndicator(
        color: MyTheme.navy,
        backgroundColor: Colors.white,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: kSettingsBodyPadding,
          children: [
            SettingsSection(
              title: l.social_media_link,
              subtitle: getLocal(context).insert_link_with_https,
              children: [
                link(l.facebook_ucf, facebookEditController),
                link(l.instagram_ucf, instagramEditController),
                link(l.twitter_ucf, twitterEditController),
                link(l.google_ucf, googleEditController),
                link(l.youtube_ucf, youtubeEditController, last: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  loadingShow(BuildContext myContext) {
    return showDialog(
        //barrierDismissible: false,
        context: myContext,
        builder: (BuildContext context) {
          loadingContext = context;
          return AlertDialog(
              content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(
                width: 10,
              ),
              Text(LangText(context: context).getLocal().please_wait_ucf),
            ],
          ));
        });
  }
}
