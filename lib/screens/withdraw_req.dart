import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/withdraw_repository.dart';
import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/custom/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';
import 'package:validators/validators.dart';

class SendAWithdrwRequest extends StatefulWidget {
  const SendAWithdrwRequest({super.key});

  @override
  State<SendAWithdrwRequest> createState() => _SendAWithdrwRequestState();
}

class _SendAWithdrwRequestState extends State<SendAWithdrwRequest> {
  sendRequest() async {
    var response =
        await WithdrawRepository().sendWithdrawReq(_message, _amount);
    if (response.result!) {
      ToastComponent.showDialog(response.message,
          gravity: Toast.center, duration: Toast.lengthLong);
      cleanAll();
    } else {
      ToastComponent.showDialog(response.message,
          gravity: Toast.center, duration: Toast.lengthLong);
    }
  }

  String? _message, _amount;
  final TextEditingController _messageTextController = TextEditingController();
  final TextEditingController _amountTextController = TextEditingController();
  List<String> _errors = [];

  cleanAll() {
    _message = "";
    _amount = "";
    _messageTextController.text = "";
    _amountTextController.text = "";
    _errors = [];
    setState(() {});
  }

  checkData() {
    _errors = [];
    _message = _messageTextController.text.trim();
    _amount = _amountTextController.text.trim();

    if (!isNumeric(_amount!) || _amount!.isEmpty) {
      _errors.add(LangText(context: context).getLocal().amount_is_invalid);
    }
    if (_message!.isEmpty) {
      _errors.add(LangText(context: context).getLocal().message_is_invalid);
    }
    setState(() {});
  }

  bool _sending = false;

  Future<void> _submit() async {
    checkData();
    if (_errors.isNotEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await sendRequest();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = LangText(context: context).getLocal();
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: settingsAppBar(context, l.send_withdraw_request_ucf),
      bottomNavigationBar: SettingsSaveBar(
          label: l.submit_ucf, onPressed: _sending ? null : _submit),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: kSettingsBodyPadding,
        children: [
          SettingsErrors(errors: _errors),
          SettingsSection(title: l.amount_ucf, children: [
            TextField(
              controller: _amountTextController,
              keyboardType: TextInputType.number,
              style: AppTheme.figure(32, color: MyTheme.navy),
              decoration: InputDecoration(
                hintText: "0",
                hintStyle: AppTheme.figure(32, color: MyTheme.grey_153),
                prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                    size: 22, color: MyTheme.dark_grey),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
          ]),
          SettingsSection(title: l.message_ucf, children: [
            SettingsTextField(
              controller: _messageTextController,
              hint: l.type_your_message_here,
              keyboardType: TextInputType.multiline,
              minLines: 4,
              maxLines: 8,
            ),
          ]),
        ],
      ),
    );
  }
}
