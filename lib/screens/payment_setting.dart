import 'dart:convert';

import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/shop_repository.dart';
import 'package:active_ecommerce_seller_app/custom/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';
import 'package:validators/validators.dart';

class PaymentSetting extends StatefulWidget {
  const PaymentSetting({super.key});

  @override
  State<PaymentSetting> createState() => _PaymentSettingState();
}

class _PaymentSettingState extends State<PaymentSetting> {
  TextEditingController bankNameEditingController =
      TextEditingController(text: "");
  TextEditingController accountNameEditingController =
      TextEditingController(text: "");
  TextEditingController accountNumberEditingController =
      TextEditingController(text: "");
  TextEditingController bankRoutingNumberEditingController =
      TextEditingController(text: "");

  late BuildContext loadingContext;

  String? bankName,
      accountName,
      accountNumber,
      bankRoutingNumber,
      bankPayment,
      cashPayment;

  setDataInEditController() {
    bankNameEditingController.text = bankName!;
    accountNameEditingController.text = accountName!;
    accountNumberEditingController.text = accountNumber!;
    bankRoutingNumberEditingController.text = bankRoutingNumber!;
  }

  bool _faceData = false;

  String error = "Provide Number";

  setDataInVariable() {
    bankName = bankNameEditingController.text;
    accountName = accountNameEditingController.text;
    accountNumber = accountNumberEditingController.text;
    bankRoutingNumber = bankRoutingNumberEditingController.text;
  }

  Future<bool> _getAccountInfo() async {
    var response = await ShopRepository().getShopInfo();
    Navigator.pop(loadingContext);
    bankName = response.shopInfo!.bankName;
    accountName = response.shopInfo!.bankAccName;
    accountNumber = response.shopInfo!.bankAccNo;
    bankRoutingNumber = response.shopInfo!.bankRoutingNo.toString();
    bankPayment = response.shopInfo!.bank_payment_status.toString();
    cashPayment = response.shopInfo!.cashOnDeliveryStatus.toString();

    print(bankPayment);

    setDataInEditController();

    _faceData = true;
    setState(() {});
    return true;
  }

  faceData() {
    WidgetsBinding.instance.addPostFrameCallback((_) => loadingShow(context));
    _getAccountInfo();
  }

  updateInfo() async {
    setDataInVariable();

    var postBody = jsonEncode({
      "cash_on_delivery_status": cashPayment,
      "bank_payment_status": bankPayment,
      "bank_name": bankName,
      "bank_acc_name": accountName,
      "bank_acc_no": accountNumber,
      "bank_routing_no": bankRoutingNumber,
    });
    loadingShow(context);
    var response = await ShopRepository().updateShopSetting(postBody);
    Navigator.pop(loadingContext);

    if (response.result!) {
      ToastComponent.showDialog(
        response.message,
        gravity: Toast.center,
        duration: 3,
        textStyle: TextStyle(color: MyTheme.black),
      );
    } else {
      ToastComponent.showDialog(
        response.message,
        gravity: Toast.center,
        duration: 3,
        textStyle: TextStyle(color: MyTheme.black),
      );
    }
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
    final bankOn = bankPayment == "1";
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: settingsAppBar(context, l.payment_settings_ucf),
      bottomNavigationBar:
          SettingsSaveBar(label: l.save_ucf, onPressed: updateInfo),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: kSettingsBodyPadding,
        children: [
          SettingsSection(
            title: l.payment_settings_ucf,
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            children: [
              SettingsSwitchRow(
                icon: Icons.account_balance_outlined,
                title: l.bank_payment,
                value: bankOn,
                onChanged: (value) =>
                    setState(() => bankPayment = value ? "1" : "0"),
              ),
              const Divider(height: 8),
              SettingsSwitchRow(
                icon: Icons.payments_outlined,
                title: l.cash_payment,
                value: cashPayment == "1",
                onChanged: (value) =>
                    setState(() => cashPayment = value ? "1" : "0"),
              ),
            ],
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: bankOn ? 1 : 0.55,
            child: SettingsSection(title: l.bank_name_ucf, children: [
              SettingsField(
                label: l.bank_name_ucf,
                child: SettingsTextField(
                    controller: bankNameEditingController,
                    hint: l.plains_commerce_bank),
              ),
              SettingsField(
                label: l.bank_account_name,
                child: SettingsTextField(
                    controller: accountNameEditingController,
                    hint: l.elmira_wisozk),
              ),
              SettingsField(
                label: l.bank_account_number,
                child: SettingsTextField(
                    controller: accountNumberEditingController,
                    hint: "7131259163",
                    keyboardType: TextInputType.number),
              ),
              SettingsField(
                label: l.bank_routing_number_ucf,
                bottomGap: 0,
                child: SettingsTextField(
                  controller: bankRoutingNumberEditingController,
                  hint: "91400554",
                  keyboardType: TextInputType.number,
                  onChanged: (data) {
                    if (!isNumeric(data)) {
                      bankRoutingNumberEditingController.text = "";
                    }
                  },
                ),
              ),
            ]),
          ),
        ],
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
