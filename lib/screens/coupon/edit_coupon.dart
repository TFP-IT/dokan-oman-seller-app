import 'dart:convert';

import 'package:active_ecommerce_seller_app/const/newCouponOptions.dart';
import 'package:active_ecommerce_seller_app/custom/device_info.dart';
import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/multi_select.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/l10n/app_localizations.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/coupon_repository.dart';
import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/custom/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toast/toast.dart';
import 'package:validators/validators.dart';

class EditCoupon extends StatefulWidget {
  final String? id;

  const EditCoupon({super.key, this.id});

  @override
  State<EditCoupon> createState() => _EditCouponState();
}

class _EditCouponState extends State<EditCoupon> {
  String? _couponInformation;
  String? _couponInformation_key;
  List<dynamic> _errors = [];
  bool fetchData = false;
  late BuildContext loadingContext;

  final List<CouponDiscountOptions> _couponDiscountTypeList =
      CouponDiscountOptions().getList();

  final List<SelectProduct> _searchProductList = [];
  List<SelectProduct> _selectedProducts = [];

  final TextEditingController _couponCodeEditController =
      TextEditingController();
  final TextEditingController _discountAmountEditController =
      TextEditingController();
  final TextEditingController _minimumShoppingEditController =
      TextEditingController();
  final TextEditingController _maximumDiscountAmountEditController =
      TextEditingController();

  String? _couponProductText;
  final String _seachName = "t";
  final String _errorMessage = "";
  String? _couponCode = "";
  String _discountAmount = "";
  String? _minimumShoppingAmount = "";
  String? _maximumDiscountAmount = "";
  String _couponId = "";

  bool hasError = true;

  CouponDiscountOptions? _couponDiscountTypeText;

  String _statAndEndTime =
      "${DateFormat('MM/d/y').format(DateTime.now())} - ${DateFormat('MM/d/y').format(DateTime.now())}";

  _sendEditCouponReq() async {
    var res = await CouponRepository().editCoupon(widget.id);

    if (res.data != null) {
      fetchData = true;
      var decode = jsonDecode(res.data!.details!);
      print(decode);
      var data = decode['data'];
      _couponInformation_key = res.data!.type;
      if (res.data!.type == "product_base") {
        _couponInformation = "For Product";

        for (var product in data) {
          _searchProductList.add(SelectProduct(
              id: product["id"],
              name: product["name"].toString(),
              isSelect: true));
          _selectedProducts.add(SelectProduct(
              id: product["id"],
              name: product["name"].toString(),
              isSelect: true));
        }
      } else {
        _couponInformation = "For Total Orders";
        _minimumShoppingAmount = decode["min_buy"];
        _maximumDiscountAmount = decode["max_discount"];

        _minimumShoppingEditController.text = _minimumShoppingAmount!;
        _maximumDiscountAmountEditController.text = _maximumDiscountAmount!;
      }

      _couponId = res.data!.id.toString();
      _discountAmount = res.data!.discount.toString();
      _discountAmountEditController.text = _discountAmount;
      _couponCode = res.data!.code;
      _couponCodeEditController.text = _couponCode!;

      _couponDiscountTypeText = res.data!.discountType == "amount"
          ? _couponDiscountTypeList.first
          : _couponDiscountTypeList.last;
      _statAndEndTime = "${res.data!.startDate!} - ${res.data!.endDate!}";
      setState(() {});
    }
  }

  _sendUpdateCouponReq() async {
    _errors = [];
    String posBody;
    if (_couponInformation_key == "product_base") {
      List productIds = [];
      for (var element in _selectedProducts) {
        productIds.add(element.id);
      }

      posBody = jsonEncode({
        "type": "product_base",
        "code": _couponCode,
        "discount": int.parse(_discountAmount),
        "discount_type": _couponDiscountTypeText!.key,
        "product_ids": productIds,
        "date_range": _statAndEndTime
      });
    } else {
      posBody = jsonEncode({
        "type": "cart_base",
        "code": _couponCode,
        "discount": int.parse(_discountAmount),
        "discount_type": _couponDiscountTypeText!.key,
        "min_buy": _minimumShoppingAmount,
        "max_discount": _maximumDiscountAmount,
        "date_range": _statAndEndTime
      });
    }
    show();
    var res = await CouponRepository().updateCoupon(posBody, _couponId);
    Navigator.pop(loadingContext);
    if (res.result!) {
      ToastComponent.showDialog(res.message,
          gravity: Toast.center, duration: 3);
    } else {
      if (res.message is List) {
        _errors.addAll(res.message);
      } else {
        _errors.add(res.message.toString());
      }
      setState(() {});
    }
  }

/*
  bool hasErrors() {
    bool hasError = true;

    if (_couponCode.isEmpty) {
      _errorMessage =
          LangText(context: context).getLocal().common_error_coupon_code;
      hasError = true;
    } else if (_discountAmount.isEmpty || !isNumeric(_discountAmount)) {
      _errorMessage =
          LangText(context: context).getLocal().common_error_discount_amount;
      hasError = true;
    } else if (_couponInformation == "product_base") {
      if (_selectedProducts.isEmpty) {
        _errorMessage =
            LangText(context: context).getLocal().common_error_products;
        hasError = true;
      } else {
        _errorMessage = "";
        hasError = false;
      }
    } else if (_couponInformation == "cart_base") {
      if (!isNumeric(_minimumShoppingAmount)) {
        _errorMessage =
            LangText(context: context).getLocal().common_error_minimum_shopping;
        hasError = true;
      } else if (!isNumeric(_maximumDiscountAmount)) {
        _errorMessage =
            LangText(context: context).getLocal().common_error_maximum_discount;
        hasError = true;
      } else {
        _errorMessage = "";
        hasError = false;
      }
    } else {
      _errorMessage = "";
      hasError = false;
    }
    return hasError;
  }*/

  formValidation() {
    _errors = [];
    _couponCode = _couponCodeEditController.text;
    _discountAmount = _discountAmountEditController.text;
    _minimumShoppingAmount = _minimumShoppingEditController.text;
    _maximumDiscountAmount = _maximumDiscountAmountEditController.text;
    if (_couponCode!.isEmpty) {
      _errors
          .add(LangText(context: context).getLocal().coupon_code_is_empty_ucf);
    }
    if (_discountAmount.isEmpty || !isNumeric(_discountAmount)) {
      _errors.add(
          LangText(context: context).getLocal().discount_amount_is_invalid_ucf);
    }
    if (_couponInformation_key == "product_base") {
      if (_selectedProducts.isEmpty) {
        _errors.add(LangText(context: context)
            .getLocal()
            .please_select_minimum_1_product_ucf);
      }
    } else if (_couponInformation_key == "cart_base") {
      if (!isNumeric(_minimumShoppingAmount!)) {
        _errors.add(
            LangText(context: context).getLocal().invalid_minimum_shopping_ucf);
      } else if (!isNumeric(_maximumDiscountAmount!)) {
        _errors.add(
            LangText(context: context).getLocal().invalid_maximum_discount_ucf);
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    _sendEditCouponReq();
    //getSearchedProductList();

    //_couponInformationList.addAll(CouponInformationOptions().getList());
    // TODO: implement initState

    //_couponInformation = "select";
    super.initState();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  AppLocalizations get getLocal => LangText(context: context).getLocal();

  bool get _isProductBased => _couponInformation_key == "product_base";
  bool get _isPercent => _couponDiscountTypeText?.key == "percent";

  void _save() {
    formValidation();
    if (_errors.isEmpty) {
      _sendUpdateCouponReq();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = LangText(context: context).getLocal();
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: settingsAppBar(context, l.edit_coupon_ucf),
      bottomNavigationBar: fetchData
          ? SettingsSaveBar(label: l.save_ucf, onPressed: _save)
          : null,
      body: fetchData
          ? ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: kSettingsBodyPadding,
              children: [
                buildCouponInformationContainer(context),
                ...buildShowBox(context),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  List<Widget> buildShowBox(BuildContext context) {
    final l = LangText(context: context).getLocal();
    return [
      SettingsErrors(errors: _errors.map((e) => e.toString()).toList()),
      buildCouponCodeContainer(context),
      buildCouponDiscountContainer(),
      SettingsSection(
        title: _isProductBased ? l.product_ucf : l.for_total_orders_ucf,
        children: [
          if (_isProductBased)
            buildCouponProductContainer()
          else
            buildForOrderContainer(context),
        ],
      ),
      buildCouponDateContainer(),
    ];
  }

  /// Coupon type is fixed once created, so it is shown read-only.
  Widget buildCouponInformationContainer(BuildContext context) {
    final l = LangText(context: context).getLocal();
    return SettingsSection(
      title: l.coupon_information_adding,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MyTheme.paper,
            borderRadius: BorderRadius.circular(MyTheme.radius_control),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: MyTheme.blue_tint,
                  borderRadius: BorderRadius.circular(MyTheme.radius_control),
                ),
                child: Icon(
                    _isProductBased
                        ? Icons.inventory_2_outlined
                        : Icons.shopping_cart_outlined,
                    size: 22,
                    color: MyTheme.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                    _isProductBased
                        ? l.for_product_ucf
                        : l.for_total_orders_ucf,
                    style: AppTheme.body(
                        size: 16,
                        weight: FontWeight.w600,
                        color: MyTheme.ink)),
              ),
              Icon(Icons.lock_outline_rounded,
                  size: 18, color: MyTheme.dark_grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildCouponCodeContainer(BuildContext context) {
    final l = LangText(context: context).getLocal();
    return SettingsSection(title: l.coupon_code_ucf, children: [
      SettingsField(
        label: l.add_your_coupon_code_ucf,
        required: true,
        bottomGap: 0,
        child: TextField(
          controller: _couponCodeEditController,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          style: AppTheme.body(
              size: 18, weight: FontWeight.w700, color: MyTheme.navy),
          decoration: InputDecoration(
            hintText: "SAVE10",
            prefixIcon: Icon(Icons.local_offer_outlined,
                size: 20, color: MyTheme.dark_grey),
          ),
        ),
      ),
    ]);
  }

  /// Discount type as a two-way switch, then the amount.
  Widget buildCouponDiscountContainer() {
    final l = LangText(context: context).getLocal();
    return SettingsSection(title: l.discount_ucf, children: [
      Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: MyTheme.paper,
          borderRadius: BorderRadius.circular(MyTheme.radius_control),
        ),
        child: Row(
          children: [
            for (final option in _couponDiscountTypeList)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: option.key == _couponDiscountTypeText?.key,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        setState(() => _couponDiscountTypeText = option),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: option.key == _couponDiscountTypeText?.key
                            ? MyTheme.navy
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(MyTheme.radius_control - 4),
                      ),
                      child: Text(option.value ?? "",
                          style: AppTheme.body(
                              size: 14,
                              weight: FontWeight.w600,
                              color: option.key == _couponDiscountTypeText?.key
                                  ? Colors.white
                                  : MyTheme.dark_grey)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      buildCouponDiscountTextField(context),
    ]);
  }

  Widget buildCouponDiscountTextField(BuildContext context) {
    final l = LangText(context: context).getLocal();
    return SettingsField(
      label: l.amount_ucf,
      required: true,
      bottomGap: 0,
      child: TextField(
        controller: _discountAmountEditController,
        keyboardType: TextInputType.number,
        style: AppTheme.body(size: 16, color: MyTheme.ink),
        decoration: InputDecoration(
          hintText: "0",
          suffixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(
              widthFactor: 1,
              child: Text(_isPercent ? "%" : (_couponDiscountTypeText?.value ?? ""),
                  style: AppTheme.body(
                      size: 14,
                      weight: FontWeight.w600,
                      color: MyTheme.dark_grey)),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildForOrderContainer(BuildContext context) {
    final l = LangText(context: context).getLocal();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SettingsField(
            label: l.minimum_shopping_ucf,
            required: true,
            bottomGap: 0,
            child: SettingsTextField(
                controller: _minimumShoppingEditController,
                hint: "0",
                keyboardType: TextInputType.number),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SettingsField(
            label: l.maximum_discount_amount_ucf,
            required: true,
            bottomGap: 0,
            child: SettingsTextField(
                controller: _maximumDiscountAmountEditController,
                hint: "0",
                keyboardType: TextInputType.number),
          ),
        ),
      ],
    );
  }

  void _openProductPicker() {
    final l = LangText(context: context).getLocal();
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setSate) {
            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              title: Text(l.select_products_ucf,
                  style: AppTheme.body(
                      size: 18, weight: FontWeight.w600, color: MyTheme.navy)),
              content: productsDialogBox(context, setSate),
              actions: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      _selectedProducts = [];
                      for (var element in _searchProductList) {
                        if (element.isSelect!) {
                          _selectedProducts.add(element);
                        }
                      }
                      setState(() {});
                      Navigator.pop(context, _selectedProducts);
                    },
                    child: Text(getLocal.ok,
                        style: AppTheme.body(
                            size: 16,
                            weight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            );
          });
        });
  }

  Widget buildCouponProductContainer() {
    final l = LangText(context: context).getLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: MyTheme.blue_tint,
          borderRadius: BorderRadius.circular(MyTheme.radius_control),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _openProductPicker,
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.add_circle_outline_rounded,
                      size: 22, color: MyTheme.navy),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l.select_products_ucf,
                        style: AppTheme.body(
                            size: 16,
                            weight: FontWeight.w600,
                            color: MyTheme.navy)),
                  ),
                  if (_selectedProducts.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                          color: MyTheme.navy,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text("${_selectedProducts.length}",
                          style: AppTheme.body(
                              size: 13,
                              weight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  const Icon(Icons.chevron_right_rounded,
                      color: MyTheme.navy),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
        if (_selectedProducts.isNotEmpty) ...[
          const SizedBox(height: 12),
          build_selectedProductstList(),
        ],
      ],
    );
  }

  Widget build_selectedProductstList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        _selectedProducts.length,
        (index) => Container(
          constraints: BoxConstraints(
              maxWidth: DeviceInfo(context).getWidth() - 80),
          padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 6, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: MyTheme.hairline, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(_selectedProducts[index].name.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: MyTheme.ink)),
              ),
              const SizedBox(width: 4),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  _searchProductList.removeWhere(
                      (element) => element.id == _selectedProducts[index].id);
                  _selectedProducts.removeAt(index);
                  setState(() {});
                },
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: MyTheme.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCouponDateContainer() {
    final l = LangText(context: context).getLocal();
    return SettingsSection(title: l.date_ucf, children: [
      Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MyTheme.radius_control),
          side: const BorderSide(color: MyTheme.hairline, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final time = await _buildCouponDate();
            if (time == null) return;
            setState(() {
              _statAndEndTime =
                  "${DateFormat('MM/d/y').format(time.start)} - ${DateFormat('MM/d/y').format(time.end)}";
            });
          },
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.event_outlined, size: 20, color: MyTheme.dark_grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_statAndEndTime,
                      style: AppTheme.body(
                          size: 16,
                          weight: FontWeight.w500,
                          color: MyTheme.ink)),
                ),
                Icon(Icons.expand_more_rounded, color: MyTheme.dark_grey),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  Future<DateTimeRange?> _buildCouponDate() async {
    return showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.utc(2050),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      saveText: getLocal.select_ucf,
    );
  }

  Widget productsDialogBox(BuildContext context, setState) {
    return SizedBox(
      width: DeviceInfo(context).getWidth(),
      height: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            style: AppTheme.body(size: 16, color: MyTheme.ink),
            decoration: InputDecoration(
              hintText: getLocal.product_name_ucf,
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20, color: MyTheme.dark_grey),
            ),
            onChanged: (string) {
              searchProduct(string, setState);
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _searchProductList.isEmpty
                ? Center(
                    child: Text(getLocal.no_product_is_available,
                        textAlign: TextAlign.center,
                        style:
                            AppTheme.body(size: 14, color: MyTheme.dark_grey)),
                  )
                : ListView.separated(
                    itemCount: _searchProductList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.trailing,
                      value: _searchProductList[index].isSelect,
                      title: Text(_searchProductList[index].name ?? "",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(size: 14, color: MyTheme.ink)),
                      onChanged: (value) {
                        setState(() {
                          _searchProductList[index].isSelect = value;
                          _selectedProducts = [
                            for (var e in _searchProductList)
                              if (e.isSelect!) e
                          ];
                        });
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  searchProduct(String value, setState) async {
    _searchProductList.removeWhere((element) {
      if (element.isSelect!) {
        return false;
      }
      return true;
    });

    var response = await CouponRepository().searchProducts(value);

    for (var element in response.data!) {
      bool idHas = false;
      for (var element2 in _searchProductList) {
        if (element.id == element2.id) {
          idHas = true;
        }
      }
      if (!idHas) {
        _searchProductList.add(
            SelectProduct(id: element.id, name: element.name, isSelect: false));
      }
    }
    setState(() {});
  }

  show() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          //setDialogContext.add(context);
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
