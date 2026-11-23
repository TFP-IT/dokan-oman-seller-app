import 'package:active_ecommerce_seller_app/app_config.dart';
import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/custom/input_decorations.dart';
import 'package:active_ecommerce_seller_app/custom/intl_phone_input.dart';
import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/my_widget.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/helpers/auth_helper.dart';
import 'package:active_ecommerce_seller_app/helpers/main_helper.dart';
import 'package:active_ecommerce_seller_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/address_repository.dart';
import 'package:active_ecommerce_seller_app/repositories/auth_repository.dart';
import 'package:active_ecommerce_seller_app/screens/main.dart';
import 'package:active_ecommerce_seller_app/screens/password_forget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:active_ecommerce_seller_app/l10n/app_localizations.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:one_context/one_context.dart';
import 'package:toast/toast.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String _login_by = "email"; //phone or email
  String initialCountry = 'US';
  PhoneNumber phoneCode = PhoneNumber(isoCode: 'US', dialCode: "+1");
  String? _phone = "";
  late BuildContext loadingContext;
  var countries_code = <String?>[];

  //controllers
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  MyWidget? myWidget;

  fetch_country() async {
    var data = await AddressRepository().getCountryList();
    data.countries!.forEach((c) => countries_code.add(c.code));
    phoneCode = PhoneNumber(isoCode: data.countries!.first.code);
    setState(() {});
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    super.initState();
    if (otp_addon_installed.$) {
      fetch_country();
    }
    /*if (is_logged_in.value == true) {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return Main();
      }));
    }*/
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  onPressedLogin() async {
    var email = _emailController.text.toString();
    var password = _passwordController.text.toString();

    if (_login_by == 'email' && email == "") {
      ToastComponent.showDialog(
          LangText(context: OneContext().context).getLocal().enter_email,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      return;
    } else if (_login_by == 'phone' && _phone == "") {
      ToastComponent.showDialog(
          LangText(context: OneContext().context).getLocal().enter_phone_number,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      return;
    } else if (password == "") {
      ToastComponent.showDialog(
          LangText(context: OneContext().context).getLocal().enter_password,
          gravity: Toast.center,
          duration: Toast.lengthLong);
      return;
    }
    loading();
    var loginResponse = await AuthRepository().getLoginResponse(
        _login_by == 'email' ? email : _phone, password, _login_by);
    Navigator.pop(loadingContext);

    if (loginResponse.result == true) {
      if (loginResponse.message.runtimeType == List) {
        ToastComponent.showDialog(loginResponse.message!.join("\n"),
            gravity: Toast.center, duration: 3);
        return;
      }

      ToastComponent.showDialog(loginResponse.message!,
          gravity: Toast.center, duration: Toast.lengthLong);
      AuthHelper().setUserData(loginResponse);

      access_token.load().whenComplete(() {
        if (access_token.$!.isNotEmpty) {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
            builder: (context) {
              return Main();
            },
          ), (route) => false);
        }
      });
    } else {
      ToastComponent.showDialog(loginResponse.message!,
          gravity: Toast.center, duration: Toast.lengthLong);
    }
  }

  @override
  Widget build(BuildContext context) {
    myWidget = MyWidget(myContext: context);
    return WillPopScope(
      onWillPop: () async => false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.lightStatusBar,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: buildBody(context),
        ),
      ),
    );
  }

  bool _obscure = true;
  final FocusNode _passwordFocus = FocusNode();

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: AppTheme.body(
                size: 14, weight: FontWeight.w600, color: MyTheme.navy)),
      );

  Widget buildBody(BuildContext context) {
    final local = LangText(context: context).getLocal();
    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---- header: logo + title --------------------------------
              Padding(
                padding: EdgeInsets.fromLTRB(
                    24, MediaQuery.of(context).padding.top + 40, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      "assets/logo/app_logo_hd.png",
                      width: 220,
                      filterQuality: FilterQuality.high,
                      semanticLabel: AppConfig.app_name,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      local.hi_welcome_to_all_lower,
                      style: AppTheme.body(
                          size: 18,
                          weight: FontWeight.w600,
                          color: MyTheme.dark_grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      local.login_to_your_account_all_lower,
                      style: AppTheme.display(
                          size: 32, weight: FontWeight.w700, height: 1.08),
                    ),
                  ],
                ),
              ),
              // ---- form ------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (otp_addon_installed.$) ...[
                        _LoginBySwitch(
                          value: _login_by,
                          emailLabel: local.email_ucf,
                          phoneLabel: local.login_screen_phone,
                          onChanged: (v) => setState(() => _login_by = v),
                        ),
                        const SizedBox(height: 24),
                      ],
                      _fieldLabel(_login_by == "email"
                          ? local.email_ucf
                          : local.login_screen_phone),
                      if (_login_by == "email")
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                          style: AppTheme.body(size: 16, color: MyTheme.ink),
                          decoration:
                              InputDecoration(hintText: local.sellerexample),
                        )
                      else
                        Container(
                          padding:
                              const EdgeInsetsDirectional.only(start: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: MyTheme.hairline, width: 1.5),
                            borderRadius:
                                BorderRadius.circular(MyTheme.radius_control),
                          ),
                          child: CustomInternationalPhoneNumberInput(
                            countries: countries_code,
                            onInputChanged: (PhoneNumber number) {
                              setState(() {
                                _phone = number.phoneNumber;
                              });
                            },
                            onInputValidated: (bool value) {},
                            selectorConfig: SelectorConfig(
                              selectorType: PhoneInputSelectorType.DIALOG,
                            ),
                            ignoreBlank: false,
                            autoValidateMode: AutovalidateMode.disabled,
                            selectorTextStyle: AppTheme.body(
                                size: 16,
                                weight: FontWeight.w500,
                                color: MyTheme.ink),
                            textStyle:
                                AppTheme.body(size: 16, color: MyTheme.ink),
                            initialValue: phoneCode,
                            textFieldController: _phoneNumberController,
                            formatInput: true,
                            keyboardType: TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                            inputDecoration:
                                InputDecorations.buildInputDecoration_phone(
                                    borderColor: MyTheme.noColor,
                                    hint_text: "01XXX XXX XXX"),
                            onSaved: (PhoneNumber number) {},
                          ),
                        ),
                      const SizedBox(height: 16),
                      _fieldLabel(getLocal(context).password_ucf),
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: _obscure,
                        enableSuggestions: false,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onPressedLogin(),
                        style: AppTheme.body(size: 16, color: MyTheme.ink),
                        decoration: InputDecoration(
                          hintText: "• • • • • • • •",
                          suffixIcon: IconButton(
                            tooltip:
                                _obscure ? "Show password" : "Hide password",
                            icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: MyTheme.dark_grey),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return PasswordForget();
                            }));
                          },
                          child: Text(getLocal(context).forget_password_ucf),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: onPressedLogin,
                          child: Text(getLocal(context).log_in,
                              style: AppTheme.body(
                                  size: 16,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Text(
                  local.in_case_of_any_difficulties_contact_with_admin,
                  style: AppTheme.body(size: 14, color: MyTheme.dark_grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  loading() {
    showDialog(
        context: context,
        builder: (context) {
          loadingContext = context;
          return AlertDialog(
              content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(
                width: 10,
              ),
              Text(AppLocalizations.of(context)!.please_wait_ucf),
            ],
          ));
        });
  }
}

/// Two-way switch between logging in with an email or a phone number.
class _LoginBySwitch extends StatelessWidget {
  final String value;
  final String emailLabel;
  final String phoneLabel;
  final ValueChanged<String> onChanged;

  const _LoginBySwitch({
    required this.value,
    required this.emailLabel,
    required this.phoneLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MyTheme.paper,
        borderRadius: BorderRadius.circular(MyTheme.radius_control),
      ),
      child: Row(
        children: [
          _segment("email", emailLabel, Icons.mail_outline_rounded),
          _segment("phone", phoneLabel, Icons.phone_iphone_rounded),
        ],
      ),
    );
  }

  Widget _segment(String key, String label, IconData icon) {
    final selected = value == key;
    final color = selected ? Colors.white : MyTheme.dark_grey;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? MyTheme.navy : Colors.transparent,
              borderRadius:
                  BorderRadius.circular(MyTheme.radius_control - 4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(
                          size: 14, weight: FontWeight.w600, color: color)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
