import 'dart:convert';
import 'dart:ui';
import 'package:active_ecommerce_seller_app/custom/device_info.dart';
import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/multi_select.dart';
import 'package:active_ecommerce_seller_app/const/newCouponOptions.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/helpers/main_helper.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/coupon_repository.dart';
import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/custom/settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toast/toast.dart';
import 'package:validators/validators.dart';

class NewCoupon extends StatefulWidget {
  const NewCoupon({super.key});

  @override
  State<NewCoupon> createState() => _NewCouponState();
}

class _NewCouponState extends State<NewCoupon> {
  late BuildContext loadingContext;

  final List<CouponInformationOptions> _couponInformationList =
      CouponInformationOptions().getList();

  final List<CouponDiscountOptions> _couponDiscountTypeList =
      CouponDiscountOptions().getList();
  GlobalKey key = GlobalKey();

  final List<SelectProduct> _searchProductList = [];
  List<SelectProduct> _selectedProducts = [];
  List<dynamic> _errors = [];

  CouponInformationOptions? _couponInformation;

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
  String _couponCode = "";
  String _discountAmount = "";
  String _minimumShoppingAmount = "";
  String _maximumDiscountAmount = "";
  int count = 0;
  bool hasError = true;

  CouponDiscountOptions? _couponDiscountTypeText;

  String _statAndEndTime =
      "${DateFormat('MM/d/y').format(DateTime.now())} - ${DateFormat('MM/d/y').format(DateTime.now())}";

  _sendCreateCouponReq() async {
    _errors = [];
    String posBody;
    if (_couponInformation!.key == "product_base") {
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
    dialogShow();
    var res = await CouponRepository().createCoupon(posBody);
    Navigator.pop(loadingContext);
    if (res.result!) {
      ToastComponent.showDialog(res.message,
          bgColor: MyTheme.white,
          textStyle: TextStyle(color: MyTheme.black),
          gravity: Toast.center,
          duration: Toast.lengthLong);
      Navigator.pop(context);
    } else {
      if (res.message is List) {
        _errors.addAll(res.message);
      } else {
        _errors.add(res.message.toString());
      }
      setState(() {});
    }
  }

  resetData() {}

  formValidation() {
    _errors = [];
    _couponCode = _couponCodeEditController.text;
    _discountAmount = _discountAmountEditController.text;
    _minimumShoppingAmount = _minimumShoppingEditController.text;
    _maximumDiscountAmount = _maximumDiscountAmountEditController.text;
    if (_couponCode.isEmpty) {
      _errors
          .add(LangText(context: context).getLocal().coupon_code_is_empty_ucf);
    }
    if (_discountAmount.isEmpty || !isNumeric(_discountAmount)) {
      _errors.add(
          LangText(context: context).getLocal().discount_amount_is_invalid_ucf);
    }
    if (_couponInformation!.key == "product_base") {
      if (_selectedProducts.isEmpty) {
        _errors.add(LangText(context: context)
            .getLocal()
            .please_select_minimum_1_product_ucf);
      }
    } else if (_couponInformation!.key == "cart_base") {
      if (!isNumeric(_minimumShoppingAmount)) {
        _errors.add(
            LangText(context: context).getLocal().invalid_minimum_shopping_ucf);
      } else if (!isNumeric(_maximumDiscountAmount)) {
        _errors.add(
            LangText(context: context).getLocal().invalid_maximum_discount_ucf);
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    //getSearchedProductList();
    _couponInformation = _couponInformationList.first;
    _couponDiscountTypeText = _couponDiscountTypeList.first;

    //_couponInformationList.addAll(CouponInformationOptions().getList());
    // TODO: implement initState

    //_couponInformation = "select";
    super.initState();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  bool get _typeChosen => (_couponInformation?.key ?? "").isNotEmpty;
  bool get _isProductBased => _couponInformation?.key == "product_base";
  bool get _isPercent => _couponDiscountTypeText?.key == "percent";

  void _save() {
    formValidation();
    if (_errors.isEmpty) {
      _sendCreateCouponReq();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = LangText(context: context).getLocal();
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: settingsAppBar(context, l.add_new_coupon_ucf),
      bottomNavigationBar: SettingsSaveBar(
          label: l.save_ucf, onPressed: _typeChosen ? _save : null),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: kSettingsBodyPadding,
        children: [
          buildCouponInformationContainer(context),
          if (_typeChosen) ...buildShowBox(context),
        ],
      ),
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

  /// Step 1: what the coupon applies to, as two big choice cards.
  Widget buildCouponInformationContainer(BuildContext context) {
    final l = LangText(context: context).getLocal();
    Widget choice(CouponInformationOptions option, IconData icon) {
      final selected = _couponInformation?.key == option.key;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: Material(
            color: selected ? MyTheme.navy : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MyTheme.radius_control),
              side: BorderSide(
                  color: selected ? MyTheme.navy : MyTheme.hairline,
                  width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => setState(() {
                _couponInformation = option;
                _errors = [];
              }),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selected
                                ? MyTheme.amber
                                : MyTheme.blue_tint,
                            borderRadius:
                                BorderRadius.circular(MyTheme.radius_control),
                          ),
                          child: Icon(icon, size: 22, color: MyTheme.navy),
                        ),
                        const Spacer(),
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 22,
                          color: selected ? Colors.white : MyTheme.grey_153,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(option.value ?? "",
                        maxLines: 2,
                        style: AppTheme.body(
                            size: 16,
                            weight: FontWeight.w600,
                            color: selected ? Colors.white : MyTheme.ink,
                            height: 1.2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final options =
        _couponInformationList.where((o) => (o.key ?? "").isNotEmpty).toList();
    return SettingsSection(
      title: l.coupon_information_adding,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                choice(
                    options[i],
                    options[i].key == "product_base"
                        ? Icons.inventory_2_outlined
                        : Icons.shopping_cart_outlined),
              ],
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
                    child: Text(getLocal(context).ok,
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
      saveText: getLocal(context).select_ucf,
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
              hintText: getLocal(context).product_name_ucf,
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
                    child: Text(getLocal(context).no_product_is_available,
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

    var resPonse = await CouponRepository().searchProducts(value);

    for (var element in resPonse.data!) {
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

  dialogShow() {
    return showDialog(
        context: context,
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
