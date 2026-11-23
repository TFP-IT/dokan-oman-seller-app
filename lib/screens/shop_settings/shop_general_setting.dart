import 'dart:convert';

import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/my_widget.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/shop_repository.dart';
import 'package:active_ecommerce_seller_app/screens/uploads/upload_file.dart';
import 'package:active_ecommerce_seller_app/custom/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toast/toast.dart';

import '../../data_model/uploaded_file_list_response.dart';

class ShopGeneralSetting extends StatefulWidget {
  const ShopGeneralSetting({super.key});

  @override
  State<ShopGeneralSetting> createState() => _ShopGeneralSettingState();
}

class _ShopGeneralSettingState extends State<ShopGeneralSetting> {
  late BuildContext loadingContext;

  String? avatar_original = "";
  String? _imageId = "";
  List<String> _errors = [];

  bool _faceData = false;

  //for image uploading
  final ImagePicker _picker = ImagePicker();
  XFile? _file;

  TextEditingController nameEditingController = TextEditingController(text: "");
  TextEditingController addressEditingController =
      TextEditingController(text: "");
  TextEditingController titleEditingController =
      TextEditingController(text: "");
  TextEditingController phoneEditingController =
      TextEditingController(text: "");
  TextEditingController descriptionEditingController =
      TextEditingController(text: "");

  Future<bool> _getAccountInfo() async {
    var response = await ShopRepository().getShopInfo();
    Navigator.pop(loadingContext);
    avatar_original = response.shopInfo!.logo;
    nameEditingController.text = response.shopInfo!.name!;
    addressEditingController.text = response.shopInfo!.address!;
    titleEditingController.text = response.shopInfo!.title!;
    descriptionEditingController.text = response.shopInfo!.description!;
    phoneEditingController.text = response.shopInfo!.phone!;
    _imageId = response.shopInfo!.uploadId;
    _faceData = true;
    setState(() {});
    return true;
  }

  updateInfo() async {
    var postBody = jsonEncode({
      "name": nameEditingController.text.trim(),
      "address": addressEditingController.text.trim(),
      "phone": phoneEditingController.text.trim(),
      "meta_title": titleEditingController.text.trim(),
      "meta_description": descriptionEditingController.text.trim(),
      "logo": _imageId,
    });
    loadingShow(context);
    var response = await ShopRepository().updateShopSetting(postBody);
    Navigator.pop(loadingContext);

    if (response.result!) {
      ToastComponent.showDialog(response.message,
          bgColor: MyTheme.white,
          duration: Toast.lengthLong,
          gravity: Toast.center);
    } else {
      ToastComponent.showDialog(response.message,
          bgColor: MyTheme.white,
          duration: Toast.lengthLong,
          gravity: Toast.center);
    }
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
                )));
    if (fileInfo!.isNotEmpty) {
      _imageId = fileInfo.first.id.toString();
      avatar_original = fileInfo.first.url;
      setState(() {});
    }
  }

  formValidation() {
    _errors = [];
    if (nameEditingController.text.trim().isEmpty) {
      _errors.add(LangText(context: context).getLocal().shop_name_is_required);
    }
    if (phoneEditingController.text.trim().isEmpty) {
      _errors.add(LangText(context: context).getLocal().shop_phone_is_required);
    }
    if (addressEditingController.text.trim().isEmpty) {
      _errors
          .add(LangText(context: context).getLocal().shop_address_is_required);
    }
    if (titleEditingController.text.trim().isEmpty) {
      _errors.add(LangText(context: context).getLocal().shop_title_is_required);
    }
    if (descriptionEditingController.text.trim().isEmpty) {
      _errors.add(
          LangText(context: context).getLocal().shop_description_is_required);
    }
    if (_imageId!.isEmpty) {
      _errors.add(LangText(context: context).getLocal().shop_logo_is_required);
    }

    setState(() {});
  }

  Future<void> onRefresh() {
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
      appBar: settingsAppBar(context, l.general_setting_ucf),
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: kSettingsBodyPadding,
          children: [
            SettingsErrors(errors: _errors),
            SettingsSection(title: l.general_setting_ucf, children: [
              SettingsField(
                label: l.shop_name_ucf,
                required: true,
                child: SettingsTextField(
                    controller: nameEditingController,
                    hint: l.demo_store_ucf),
              ),
              SettingsField(
                label: l.shop_phone,
                required: true,
                child: SettingsTextField(
                    controller: phoneEditingController,
                    hint: "01XXX XXX XXX",
                    keyboardType: TextInputType.phone),
              ),
              SettingsField(
                label: l.shop_address,
                required: true,
                bottomGap: 0,
                child: SettingsTextField(
                    controller: addressEditingController,
                    hint: l.demo_address,
                    keyboardType: TextInputType.streetAddress,
                    minLines: 2,
                    maxLines: 4),
              ),
            ]),
            SettingsSection(title: l.shop_logo_ucf, children: [
              SettingsFilePicker(onTap: () => chooseAndUploadImage(context)),
              if (avatar_original!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SettingsImageThumb(
                    onRemove: () {
                      avatar_original = "";
                      _imageId = "";
                      setState(() {});
                    },
                    child: MyWidget.imageWithPlaceholder(
                        height: 112.0, width: 112.0, url: avatar_original),
                  ),
                ),
              ],
            ]),
            SettingsSection(title: l.seo_all_capital, children: [
              SettingsField(
                label: l.shop_title,
                required: true,
                child: SettingsTextField(
                    controller: titleEditingController,
                    hint: l.demo_store_ucf),
              ),
              SettingsField(
                label: l.shop_description,
                required: true,
                bottomGap: 0,
                child: SettingsTextField(
                    controller: descriptionEditingController,
                    hint: l.there_are_variations,
                    keyboardType: TextInputType.multiline,
                    minLines: 3,
                    maxLines: 6),
              ),
            ]),
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
