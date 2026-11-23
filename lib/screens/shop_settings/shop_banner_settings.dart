import 'dart:convert';
import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/my_widget.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/data_model/uploaded_file_list_response.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/shop_repository.dart';
import 'package:active_ecommerce_seller_app/screens/uploads/upload_file.dart';
import 'package:active_ecommerce_seller_app/custom/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toast/toast.dart';

class ShopBannerSettings extends StatefulWidget {
  const ShopBannerSettings({super.key});

  @override
  State<ShopBannerSettings> createState() => _ShopBannerSettingsState();
}

class _ShopBannerSettingsState extends State<ShopBannerSettings> {
  late BuildContext loadingContext;

  List<String> _imageUrls = [];

  List<String> _imageIds = [];
  List<String> _errors = [];

  //for image uploading
  final ImagePicker _picker = ImagePicker();
  XFile? _file;

  Future<bool> _getAccountInfo() async {
    var response = await ShopRepository().getShopInfo();
    Navigator.pop(loadingContext);

    _imageUrls.addAll(response.shopInfo!.sliders!);

    if (response.shopInfo!.slidersId != null) {
      _imageIds = response.shopInfo!.slidersId.split(",");
    }

    print(_imageIds.join(','));
    setState(() {});
    return true;
  }

  updateInfo() async {
    var postBody = jsonEncode({
      "sliders": _imageIds.join(','),
    });
    loadingShow(context);
    var response = await ShopRepository().updateShopSetting(postBody);
    Navigator.pop(loadingContext);

    ToastComponent.showDialog(response.message,
        bgColor: MyTheme.white,
        duration: Toast.lengthLong,
        gravity: Toast.center);
  }

  resetData() {
    cleanData();
    faceData();
  }

  cleanData() {
    _imageUrls = [];
    _imageIds = [];
    _errors = [];
    //for image uploading
  }

  faceData() {
    WidgetsBinding.instance.addPostFrameCallback((_) => loadingShow(context));
    _getAccountInfo();
  }

  chooseAndUploadImage(context) async {
    List<FileInfo>? fileInfo = await Navigator.push<List<FileInfo>>(
        context,
        MaterialPageRoute(
            builder: (context) => const UploadFile(
                  fileType: "image",
                  canSelect: true,
                  canMultiSelect: true,
                )));
    if (fileInfo!.isNotEmpty) {
      for (var element in fileInfo) {
        _imageIds.add(element.id.toString());
        _imageUrls.add(element.url!);
      }

      setState(() {});
    }
  }

  formValidation() {
    _errors = [];
    if (_imageIds.isEmpty) {
      _errors.add(
          LangText(context: context).getLocal().shop_banner_image_is_required);
    }
    setState(() {});
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
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: settingsAppBar(context, l.banner_settings),
      bottomNavigationBar: SettingsSaveBar(
        label: l.save_ucf,
        onPressed: () {
          formValidation();
          if (_errors.isEmpty) {
            updateInfo();
          }
        },
      ),
      body: RefreshIndicator(
        color: MyTheme.navy,
        backgroundColor: Colors.white,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: kSettingsBodyPadding,
          children: [
            SettingsErrors(errors: _errors),
            SettingsSection(
              title: l.banner_1500_x_450,
              subtitle: l.banner_1500_x_450_des,
              children: [
                SettingsFilePicker(onTap: () => chooseAndUploadImage(context)),
                for (int index = 0; index < _imageUrls.length; index++) ...[
                  const SizedBox(height: 16),
                  SettingsImageThumb(
                    onRemove: () {
                      _imageUrls.removeAt(index);
                      _imageIds.removeAt(index);
                      setState(() {});
                    },
                    child: AspectRatio(
                      aspectRatio: 1500 / 450,
                      child: MyWidget.imageWithPlaceholder(
                          url: _imageUrls[index], fit: BoxFit.cover),
                    ),
                  ),
                ],
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
