import 'dart:async';
import 'dart:convert';

import 'package:active_ecommerce_seller_app/const/app_style.dart';
import 'package:active_ecommerce_seller_app/const/dropdown_models.dart';
import 'package:active_ecommerce_seller_app/custom/aiz_summer_note.dart';
import 'package:active_ecommerce_seller_app/custom/buttons.dart';
import 'package:active_ecommerce_seller_app/custom/common_style.dart';
import 'package:active_ecommerce_seller_app/custom/device_info.dart';
import 'package:active_ecommerce_seller_app/custom/input_decorations.dart';
import 'package:active_ecommerce_seller_app/custom/loading.dart';
import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/multi_category_section.dart';
import 'package:active_ecommerce_seller_app/custom/my_widget.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/data_model/language_list_response.dart';
import 'package:active_ecommerce_seller_app/data_model/product/attribut_model.dart';
import 'package:active_ecommerce_seller_app/data_model/product/category_response_model.dart';
import 'package:active_ecommerce_seller_app/data_model/product/category_view_model.dart';
import 'package:active_ecommerce_seller_app/data_model/product/custom_radio_model.dart';
import 'package:active_ecommerce_seller_app/data_model/product/product_edit_response.dart';
import 'package:active_ecommerce_seller_app/data_model/product/vat_tax_model.dart';
import 'package:active_ecommerce_seller_app/data_model/uploaded_file_list_response.dart';
import 'package:active_ecommerce_seller_app/helpers/main_helper.dart';
import 'package:active_ecommerce_seller_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/language_repository.dart';
import 'package:active_ecommerce_seller_app/repositories/product_repository.dart';
import 'package:active_ecommerce_seller_app/screens/uploads/upload_file.dart';
import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:one_context/one_context.dart';
import 'package:toast/toast.dart';

class UpdateProduct extends StatefulWidget {
  final productId;

  const UpdateProduct({super.key, this.productId});

  @override
  State<UpdateProduct> createState() => _UpdateProductState();
}

class _UpdateProductState extends State<UpdateProduct> {
  // double variables

  String _statAndEndTime = "Select Date";

  double mHeight = 0.0, mWidht = 0.0;
  int _selectedTabIndex = 0;
  bool isColorActive = false;
  bool isRefundable = false;
  bool isCashOnDelivery = false;
  bool isProductQuantityMultiply = false;
  bool isFeatured = false;
  bool isTodaysDeal = false;
  bool isShowStockQuantity = false;
  bool isShowStockWithTextOnly = false;
  bool isHideStock = false;

  bool isCategoryInit = false;
  List<CategoryModel> categories = [];
  List<Language> languages = [];
  List<CommonDropDownItem> brands = [];
  List<VatTaxViewModel> vatTaxList = [];
  List<CommonDropDownItem> videoType = [];
  List<CommonDropDownItem> discountTypeList = [];
  List<CommonDropDownItem> colorList = [];
  List<CommonDropDownItem> selectedColors = [];
  List<AttributesModel> attribute = [];
  List<AttributesModel> selectedAttributes = [];
  List<VariationModel> productVariations = [];
  List<CustomRadioModel> shippingConfigurationList = [];
  List<CustomRadioModel> stockVisibilityStateList = [];
  late CustomRadioModel selectedShippingConfiguration;
  late CustomRadioModel selectedstockVisibilityState;

  CommonDropDownItem? selectedBrand;
  Language? selectedLanguage;

  CommonDropDownItem? selectedVideoType;
  CommonDropDownItem? selectedAddToFlashType;
  CommonDropDownItem? selectedFlashDiscountType;
  CommonDropDownItem? selectedProductDiscountType;
  CommonDropDownItem? selectedColor;
  AttributesModel? selectedAttribute;
  FlutterSummernote? summernote;

  //Product value

  List<String> tmpColorList = [];
  List<ChoiceOption> tmpAttribute = [];
  String? tmpCategory = "";
  String? tmpBrand = "";
  bool isProductDetailsInit = false;

  List categoryIds = [];
  String? productName,
      categoryId,
      brandId,
      unit,
      weight,
      minQuantity,
      refundable,
      barcode,
      photos,
      thumbnailImg,
      videoProvider,
      videoLink,
      colorsActive,
      unitPrice,
      dateRange,
      discount,
      discountType,
      currentStock,
      sku,
      externalLink,
      externalLinkBtn,
      description,
      pdf,
      metaTitle,
      slug,
      metaDescription,
      metaImg,
      shippingType,
      flatShippingCost,
      lowStockQuantity,
      stockVisibilityState,
      cashOnDelivery,
      estShippingDays,
      button;
  String? lang = "en";
  var tagMap = [];
  List<String?>? tags = [],
      colors,
      choiceAttributes,
      choiceNo,
      choice,
      choiceOptions2,
      choiceOptions1,
      taxId,
      tax,
      taxType;

  Map choice_options = {};

  //ImagePicker pickImage = ImagePicker();

  List<FileInfo> productGalleryImages = [];
  FileInfo? thumbnailImage;
  FileInfo? metaImage;
  FileInfo? pdfDes;
  DateTimeRange? dateTimeRange =
      DateTimeRange(start: DateTime.now(), end: DateTime.now());

  //Edit text controller
  TextEditingController productNameEditTextController = TextEditingController();
  TextEditingController unitEditTextController = TextEditingController();
  TextEditingController weightEditTextController =
      TextEditingController(text: "0.0");
  TextEditingController minimumEditTextController =
      TextEditingController(text: "1");
  TextEditingController tagEditTextController = TextEditingController();
  TextEditingController barcodeEditTextController = TextEditingController();
  TextEditingController taxEditTextController = TextEditingController();
  TextEditingController videoLinkEditTextController = TextEditingController();
  TextEditingController metaTitleEditTextController = TextEditingController();
  TextEditingController slugEditTextController = TextEditingController();
  TextEditingController metaDescriptionEditTextController =
      TextEditingController();
  TextEditingController shippingDayEditTextController = TextEditingController();
  TextEditingController productDiscountEditTextController =
      TextEditingController(text: "0");
  TextEditingController flashDiscountEditTextController =
      TextEditingController();
  TextEditingController unitPriceEditTextController =
      TextEditingController(text: "0");
  TextEditingController productQuantityEditTextController =
      TextEditingController(text: "0");
  TextEditingController skuEditTextController = TextEditingController();
  TextEditingController externalLinkEditTextController =
      TextEditingController();
  TextEditingController externalLinkButtonTextEditTextController =
      TextEditingController();
  TextEditingController stockLowWarningTextEditTextController =
      TextEditingController();
  TextEditingController variationPriceTextEditTextController =
      TextEditingController();
  TextEditingController variationQuantityTextEditTextController =
      TextEditingController();
  TextEditingController variationSkuTextEditTextController =
      TextEditingController();
  TextEditingController flatShippingCostTextEditTextController =
      TextEditingController();
  TextEditingController lowStockQuantityTextEditTextController =
      TextEditingController(text: "1");
  final TextEditingController _TextEditTextController = TextEditingController();

  GlobalKey<FlutterSummernoteState> productDescriptionKey = GlobalKey();

  getCategories() async {
    var categoryResponse = await ProductRepository().getCategoryRes();
    for (var element in categoryResponse.data!) {
      CategoryModel model = CategoryModel(
          id: element.id.toString(),
          title: element.name,
          isExpanded: false,
          isSelected: false,
          height: 0.0,
          children: setChildCategory(element.child!));
      categories.add(model);
    }

    isCategoryInit = true;
    setState(() {});
  }

  List<CategoryModel> setChildCategory(List<Category> child) {
    List<CategoryModel> list = [];
    for (var element in child) {
      var children = element.child ?? [];
      CategoryModel model = CategoryModel(
          id: element.id.toString(),
          title: element.name,
          height: 0.0,
          children: children.isNotEmpty ? setChildCategory(children) : []);

      list.add(model);

      // if (element.level > 0) {
      //   model.setLevelText();
      // }
      // categories.add(model);
      // if (element.child!.isNotEmpty) {
      //
      // }
    }
    return list;
  }

  getBrands() async {
    var brandsRes = await ProductRepository().getBrandRes();
    brands.clear();
    for (var element in brandsRes.data!) {
      brands.addAll([
        CommonDropDownItem("${element.id}", element.name),
      ]);
    }

    if (tmpBrand != null && tmpBrand!.isNotEmpty && brands.isNotEmpty) {
      for (var element in brands) {
        if (element.key == tmpBrand) {
          selectedBrand = element;
        }
      }
    }

    setState(() {});
  }

  getColors() async {
    var colorRes = await ProductRepository().getColorsRes();
    colorList.clear();

    for (var element in colorRes.data!) {
      colorList.add(CommonDropDownItem("${element.code}", "${element.name}"));
    }

    selectedColors.clear();

    for (var element in colorList) {
      if (tmpColorList.contains(element.key)) {
        selectedColors.add(element);
      }
    }

    setState(() {});
  }

  getAttributes() async {
    var attributeRes = await ProductRepository().getAttributeRes();
    attribute.clear();

    selectedAttributes.clear();

    for (var element in attributeRes.data!) {
      attribute.add(
        AttributesModel(
          CommonDropDownItem("${element.id}", "${element.name}"),
          List.generate(
              element.values!.length,
              (index) => CommonDropDownItem("${element.values![index].id}",
                  "${element.values![index].value}")),
          [],
          null,
        ),
      );
    }

    for (var tmpElement in tmpAttribute) {
      for (var attributeElement in attribute) {
        if (attributeElement.name.key == tmpElement.attributeId) {
          List<CommonDropDownItem> items = [];

          for (var tmpItems in tmpElement.values!) {
            for (var attributeItems in attributeElement.attributeItems) {
              if (tmpItems == attributeItems.value) {
                items.add(attributeItems);
              }
            }
          }
          selectedAttributes.add(AttributesModel(attributeElement.name,
              attributeElement.attributeItems, items, null));
        }
      }
    }
    setState(() {});
  }

  setConstDropdownValues() {
    videoType.clear();
    videoType.addAll([
      CommonDropDownItem("youtube",
          LangText(context: OneContext().context).getLocal().youtube_ucf),
      CommonDropDownItem("dailymotion",
          LangText(context: OneContext().context).getLocal().dailymotion_ucf),
      CommonDropDownItem("vimeo",
          LangText(context: OneContext().context).getLocal().vimeo_ucf),
    ]);
    selectedVideoType = videoType.first;

    discountTypeList.clear();
    discountTypeList.addAll([
      CommonDropDownItem("amount", "Flat"),
      CommonDropDownItem("percent", "Percent"),
    ]);
    selectedProductDiscountType = discountTypeList.first;
    selectedFlashDiscountType = discountTypeList.first;
    // selectedCategory = categories.first;
    shippingConfigurationList.clear();
    shippingConfigurationList.addAll([
      CustomRadioModel("Free Shipping", "free", true),
      CustomRadioModel("Flat Rate", "flat_rate", false),
    ]);
    stockVisibilityStateList.clear();
    stockVisibilityStateList.addAll([
      CustomRadioModel("Show Stock Quantity", "quantity", true),
      CustomRadioModel("Show Stock With Text Only", "text", false),
      CustomRadioModel("Hide Stock", "hide", false)
    ]);

    selectedShippingConfiguration = shippingConfigurationList.first;
    selectedstockVisibilityState = stockVisibilityStateList.first;

    setState(() {});
  }

  getTaxType(ProductInfo productInfo) async {
    var taxRes = await ProductRepository().getTaxRes();
    vatTaxList.clear();
    for (var element in taxRes.data!) {
      var tmpTax = productInfo.tax!
          .where((productTax) => productTax.taxId == element.id);

      if (tmpTax.isNotEmpty) {
        var taxList = [
          CommonDropDownItem("amount", "Flat"),
          CommonDropDownItem("percent", "Percent")
        ];
        CommonDropDownItem selectedTax = taxList
            .where((element) => element.key == tmpTax.first.taxType)
            .first;

        vatTaxList.add(
          VatTaxViewModel(
              VatTaxModel("${element.id}", "${element.name}"), taxList,
              selectedItem: selectedTax, amount: tmpTax.first.tax?.toString()),
        );
      } else {
        vatTaxList.add(
          VatTaxViewModel(
            VatTaxModel("${element.id}", "${element.name}"),
            [
              CommonDropDownItem("amount", "Flat"),
              CommonDropDownItem("percent", "Percent"),
            ],
          ),
        );
      }
    }
  }

  pickGalleryImages() async {
    var tmp = productGalleryImages;
    List<FileInfo>? images = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => UploadFile(
                  fileType: "image",
                  canSelect: true,
                  canMultiSelect: true,
                  prevData: tmp,
                )));
    // ////print(images != null);
    productGalleryImages = images!;
    setChange();
  }

/*
  Future<XFile> pickSingleImage() async {
    return await pickImage.pickImage(source: ImageSource.gallery);
  }*/

  createProductVariation() {
    productVariations.clear();

    if (selectedColors.isNotEmpty) {
      for (var colors in selectedColors) {
        // add attribute with color;
        var colorName = colors.value;
        List<String> attributeList = generateAttributeVariation();
        if (attributeList.isNotEmpty) {
          for (var element in attributeList) {
            String variationName = "${colorName!}-$element";
            productVariations.add(VariationModel(
                variationName,
                FileInfo(),
                TextEditingController(
                    text: unitPriceEditTextController.text.trim().toString()),
                TextEditingController(text: "0"),
                TextEditingController(text: variationName),
                false));
          }
        } else {
          String? variationName = colorName;
          productVariations.add(VariationModel(
              variationName,
              FileInfo(),
              TextEditingController(
                  text: unitPriceEditTextController.text.trim().toString()),
              TextEditingController(text: "0"),
              TextEditingController(text: variationName),
              false));
        }
      }
    } else {
      List<String> attributeList = generateAttributeVariation();

      if (attributeList.isNotEmpty) {
        for (var element in attributeList) {
          String variationName = element;
          productVariations.add(VariationModel(
              variationName,
              null,
              TextEditingController(
                  text: unitPriceEditTextController.text.trim().toString()),
              TextEditingController(text: "10"),
              TextEditingController(text: variationName),
              false));
        }
      }
    }
  }

  setInitialProductVariation(Stock stock) {
    productVariations.clear();

    if (stock.data!.isNotEmpty) {
      for (var element in stock.data!) {
        FileInfo? image;
        if (element.image!.data!.isNotEmpty) {
          image = element.image!.data!.first;
        }

        productVariations.add(VariationModel(
            element.variant,
            image,
            TextEditingController(text: element.price?.toString()),
            TextEditingController(text: element.qty?.toString()),
            TextEditingController(text: element.sku),
            false));
      }
    }

    ////print("productVariations.length${productVariations.length}");

    /*if (stock.data.isNotEmpty) {
      selectedColors.forEach((colors) {
        // add attribute with color;
        var colorName = colors.value;
        List<String> attributeList = generateAttributeVariation();
        if (attributeList.isNotEmpty) {
          attributeList.forEach((element) {

            String variationName = colorName + "-" + element;
            productVariations.add(VariationModel(
                variationName,
                FileInfo(),
                TextEditingController(
                    text: unitPriceEditTextController.text.trim()?.toString()),
                TextEditingController(text: "0"),
                TextEditingController(text: variationName),
                false));
          });
        } else {
          String variationName = colorName ;
          productVariations.add(VariationModel(
              variationName,
              FileInfo(),
              TextEditingController(
                  text: unitPriceEditTextController.text.trim()?.toString()),
              TextEditingController(text: "0"),
              TextEditingController(text: variationName),
              false));
        }
      });
    } else {
      List<String> attributeList = generateAttributeVariation();

      if (attributeList.isNotEmpty) {
        attributeList.forEach((element) {
          String variationName = element ;
          productVariations.add(VariationModel(
              variationName,
              null,
              TextEditingController(
                  text: unitPriceEditTextController.text.trim()?.toString()),
              TextEditingController(text: "10"),
              TextEditingController(text: variationName),
              false));
        });
      }
    }*/
    setChange();
  }

  List<String> generateAttributeVariation() {
    var variationColumn = 1;

    for (var element in selectedAttributes) {
      if (element.selectedAttributeItems.isNotEmpty) {
        variationColumn =
            variationColumn * element.selectedAttributeItems.length;
      }
    }

    List<String> mList = [];

    for (int i = 0; i < selectedAttributes.length; i++) {
      for (int j = 0;
          j < selectedAttributes[i].selectedAttributeItems.length;
          j++) {
        if (i == 0) {
          for (int k = 0;
              k <
                  (variationColumn /
                      selectedAttributes[i].selectedAttributeItems.length);
              k++) {
            var value = selectedAttributes[i]
                .selectedAttributeItems[j]
                .value!
                .replaceAll(" ", "");
            mList.add(value);
          }
        } else {
          for (int l = j;
              l < mList.length;
              l = l + selectedAttributes[i].selectedAttributeItems.length) {
            String tmp =
                "${mList[l]}-${selectedAttributes[i].selectedAttributeItems[j].value!.replaceAll(" ", "")}";
            mList[l] = tmp;
          }
        }
      }
    }

    return mList;
  }

  setProductPhotoValue() {
    photos = "";
    for (int i = 0; i < productGalleryImages.length; i++) {
      if (i != (productGalleryImages.length - 1)) {
        photos = "$photos " "${productGalleryImages[i].id},";
      } else {
        photos = "$photos " "${productGalleryImages[i].id}";
      }
    }
  }

  setColors() {
    colors = [];
    for (var element in selectedColors) {
      colors!.add(element.key);
    }
  }

  setChoiceAtt() {
    choiceAttributes = [];
    choiceNo = [];
    choice = [];
    choice_options.clear();

    for (var element in selectedAttributes) {
      choiceAttributes!.add(element.name.key);
      choiceNo!.add(element.name.key);
      choice!.add(element.name.value);

      List<String?> tmpValue = [];
      for (var attributes in element.selectedAttributeItems) {
        tmpValue.add(attributes.value);
      }
      choice_options.addAll({"choice_options_${element.name.key}": tmpValue});
    }

    choiceAttributes!.sort();
  }

  setTaxes() {
    taxType = [];
    tax = [];
    taxId = [];
    for (var element in vatTaxList) {
      taxId!.add(element.vatTaxModel.id);
      tax!.add(element.amount.text.trim().toString());
      if (element.selectedItem != null) taxType!.add(element.selectedItem!.key);
    }
  }

  setProductValues() async {
    productName = productNameEditTextController.text.trim();

    if (selectedBrand != null) brandId = selectedBrand!.key;

    unit = unitEditTextController.text.trim();
    weight = weightEditTextController.text.trim();
    minQuantity = minimumEditTextController.text.trim();

    tagMap.clear();
    for (var element in tags!) {
      tagMap.add(jsonEncode({"value": '$element'}));
    }
    // add product photo
    setProductPhotoValue();
    if (thumbnailImage != null) thumbnailImg = "${thumbnailImage!.id}";
    videoProvider = selectedVideoType!.key;
    videoLink = videoLinkEditTextController.text.trim().toString();
    //Set colors
    setColors();
    colorsActive = isColorActive ? "1" : "0";
    unitPrice = unitPriceEditTextController.text.trim().toString();
    //print("#########################");
    //print(unitPrice);
    //print("#########################");
    dateRange = "${dateTimeRange!.start} to ${dateTimeRange!.end}";
    discount = productDiscountEditTextController.text.trim().toString();
    discountType = selectedProductDiscountType!.key;
    currentStock = productVariations.isEmpty
        ? productQuantityEditTextController.text.trim().toString()
        : "0";
    sku = productVariations.isEmpty
        ? skuEditTextController.text.trim().toString()
        : null;
    externalLink = externalLinkEditTextController.text.trim().toString();
    externalLinkBtn =
        externalLinkButtonTextEditTextController.text.trim().toString();

    if (productDescriptionKey.currentState != null) {
      description = await productDescriptionKey.currentState!.getText() ?? "";
      description = await productDescriptionKey.currentState!.getText() ?? "";
    }

    if (pdfDes != null) pdf = "${pdfDes!.id}";
    metaTitle = metaTitleEditTextController.text.trim().toString();
    slug = slugEditTextController.text.trim().toString();
    ////print("slug");
    ////print(slug);

    metaDescription = metaDescriptionEditTextController.text.trim().toString();
    if (metaImage != null) metaImg = "${metaImage!.id}";
    shippingType = selectedShippingConfiguration.key;
    flatShippingCost =
        flatShippingCostTextEditTextController.text.trim().toString();
    lowStockQuantity =
        lowStockQuantityTextEditTextController.text.trim().toString();
    stockVisibilityState = selectedstockVisibilityState.key;
    cashOnDelivery = isCashOnDelivery ? "1" : "0";
    estShippingDays = shippingDayEditTextController.text.trim().toString();
    // get taxes
    refundable = isRefundable ? "1" : "0";
    setTaxes();
  }

  bool requiredFieldVerification() {
    if (productNameEditTextController.text.trim().toString().isEmpty) {
      ToastComponent.showDialog("Product Name Required", gravity: Toast.center);
      return false;
    } else if (minimumEditTextController.text.trim().toString().isEmpty) {
      ToastComponent.showDialog("Product Minimum Quantity Required");
      return false;
    } else if (unitEditTextController.text.trim().toString().isEmpty) {
      ToastComponent.showDialog("Product Unit Required");
      return false;
    }
    return true;
  }

  submitProduct() async {
    if (!requiredFieldVerification()) {
      return;
    }

    Loading().show();

    await setProductValues();

    setChoiceAtt();
    Map postValue = {};
    postValue.addAll({
      "name": productName,
      "category_id": categoryId,
      "category_ids": categoryIds,
      "brand_id": brandId,
      "unit": unit,
      "weight": weight,
      "min_qty": minQuantity,
      "tags": [tagMap.toString()],
      "photos": photos,
      "thumbnail_img": thumbnailImg,
      "video_provider": videoProvider,
      "video_link": videoLink,
      "colors": colors,
      "colors_active": colorsActive,
      "choice_attributes": choiceAttributes,
      "choice_no": choiceNo,
      "choice": choice
    });

    postValue.addAll(choice_options);

    if (refund_addon.$) {
      postValue.addAll({"refundable": refundable});
    }

    postValue.addAll({
      "unit_price": unitPrice,
      "date_range": int.parse(discount!) <= 0 ? null : dateRange,
      "discount": discount,
      "discount_type": discountType,
      "current_stock": currentStock,
      "sku": sku,
      "external_link": externalLink,
      "external_link_btn": externalLinkBtn,
    });
    postValue.addAll(makeVariationMap());

    if (shipping_type.$) {
      postValue.addAll({
        "shipping_type": shippingType,
        "flat_shipping_cost": flatShippingCost
      });
    }

    postValue.addAll({
      "description": description,
      "pdf": pdf,
      "meta_title": metaTitle,
      "meta_description": metaDescription,
      "meta_img": metaImg,
      "slug": slug,
      "low_stock_quantity": lowStockQuantity,
      "stock_visibility_state": stockVisibilityState,
      "cash_on_delivery": cashOnDelivery,
      "est_shipping_days": estShippingDays,
      "tax_id": taxId,
      "tax": tax,
      "tax_type": taxType,
      "button": button,
    });

    ////print("lang");
    ////print(lang);
    ////print(postValue);

    var postBody = jsonEncode(postValue);
    var response = await ProductRepository()
        .updateProductResponse(postBody, widget.productId, lang);

    Loading().hide();
    if (response.result!) {
      ToastComponent.showDialog(response.message, gravity: Toast.center);

      Navigator.pop(context);
    } else {
      List errorMessages = response.message;
      ToastComponent.showDialog(errorMessages.join(","), gravity: Toast.center);
    }
  }

  Map makeVariationMap() {
    Map variation = {};
    for (var element in productVariations) {
      variation.addAll({
        "price_${element.name!.replaceAll(" ", "-")}":
            element.priceEditTextController.text.trim().toString(),
        "sku_${element.name!.replaceAll(" ", "-")}":
            element.skuEditTextController.text.trim().toString(),
        "qty_${element.name!.replaceAll(" ", "-")}":
            element.quantityEditTextController.text.trim().toString(),
        "img_${element.name!.replaceAll(" ", "-")}": element.photo?.id,
      });
    }
    return variation;
  }

  setInitialValue(ProductInfo productInfo) {
    selectedLanguage =
        languages.where((element) => element.code == productInfo.lang).first;
    setConstDropdownValues();
    isColorActive = productInfo.colors!.isNotEmpty;
    isRefundable = productInfo.refundable == 1 ? true : false;

    ////print(productInfo.refundable);
    ////print("productInfo.refundable");

    isCashOnDelivery = productInfo.cashOnDelivery == 1 ? true : false;

    isProductQuantityMultiply =
        productInfo.isQuantityMultiplied == 1 ? true : false;
    // isFeatured = productInfo.featured == 1 ? true : false;
    isTodaysDeal = productInfo.todaysDeal == 1 ? true : false;
    tmpColorList.addAll(productInfo.colors!);
    getColors();

    tmpAttribute.clear();
    tmpAttribute.addAll(productInfo.choiceOptions!);
    getAttributes();
    if (productInfo.choiceOptions!.isNotEmpty) {
      setInitialProductVariation(productInfo.stocks!);
    }

    for (var element in shippingConfigurationList) {
      element.isActive = false;
      if (element.key == productInfo.shippingType) {
        selectedShippingConfiguration = element;
        element.isActive = true;
        flatShippingCostTextEditTextController.text =
            productInfo.shippingCost!.toString();
      }
    }

    for (var element in stockVisibilityStateList) {
      element.isActive = false;
      if (element.key == productInfo.stockVisibilityState) {
        selectedstockVisibilityState = element;
        element.isActive = true;
      }
    }

    categoryId = productInfo.categoryId?.toString();
    categoryIds.addAll(productInfo.categories);
    //print("cate = $categoryIds");
    getCategories();

    tmpBrand = productInfo.brandId?.toString();
    getBrands();

    for (var element in videoType) {
      if (element.key == productInfo.videoProvider) {
        selectedVideoType = element;
      }
    }

    getTaxType(productInfo);

    for (var element in discountTypeList) {
      if (productInfo.discountType == element.key) {
        selectedProductDiscountType = element;
      }
    }
    if (productInfo.photos!.data!.isNotEmpty) {
      productGalleryImages.addAll(productInfo.photos!.data!);
    }
    if (productInfo.thumbnailImg!.data!.isNotEmpty) {
      thumbnailImage = productInfo.thumbnailImg!.data!.first;
    }
    if (productInfo.metaImg!.data!.isNotEmpty) {
      metaImage = productInfo.metaImg!.data!.first;
    }
    if (productInfo.pdf!.data!.isNotEmpty) {
      pdfDes = productInfo.pdf!.data!.first;
    }

    var start = DateTime.tryParse(productInfo.discountStartDate)!;
    var end = DateTime.tryParse(productInfo.discountEndDate)!;
    ////print(start);
    ////print(end);
    dateTimeRange = DateTimeRange(start: start, end: end);

    _statAndEndTime =
        "${intl.DateFormat('d/MM/y').format(dateTimeRange!.start)} - ${intl.DateFormat('d/MM/y').format(dateTimeRange!.end)}";
    tags!.clear();
    if (productInfo.tags!.isNotEmpty) {
      tags!.addAll(productInfo.tags!.split(","));
    }

    productNameEditTextController.text = productInfo.productName!;
    unitEditTextController.text = productInfo.productUnit ?? '';
    weightEditTextController.text = productInfo.weight!.toString();
    minimumEditTextController.text = productInfo.minQty!.toString();
    barcodeEditTextController.text = productInfo.barcode ?? "";

    videoLinkEditTextController.text = productInfo.videoLink ?? "";
    metaTitleEditTextController.text = productInfo.metaTitle!;
    slugEditTextController.text = productInfo.slug!;
    metaDescriptionEditTextController.text = productInfo.metaDescription!;
    shippingDayEditTextController.text =
        productInfo.estShippingDays.toString() ?? "";
    productDiscountEditTextController.text = productInfo.discount!.toString();

    unitPriceEditTextController.text = productInfo.unitPrice!.toString();

    if (productInfo.choiceOptions!.isEmpty) {
      productQuantityEditTextController.text =
          productInfo.stocks!.data!.first.qty!.toString();
      skuEditTextController.text = productInfo.stocks!.data!.first.sku ?? "";
    }

    externalLinkEditTextController.text = productInfo.externalLink ?? "";
    externalLinkButtonTextEditTextController.text =
        productInfo.externalLinkBtn ?? '';

    stockLowWarningTextEditTextController.text =
        productInfo.stockVisibilityState!.toString();

    lowStockQuantityTextEditTextController.text =
        productInfo.lowStockQuantity.toString() ?? "";
    description = productInfo.description ?? "";

    // summernote  = FlutterSummernote(
    //     showBottomToolbar: false,
    //     hint: "",
    //     value:description ,
    //     key: productDescriptionKey);

    productDescriptionKey.currentState!.setText(description!);

    ////print(productInfo.description);

    setChange();
  }

  getProductCurrentValues() async {
    if (selectedLanguage != null) {
      lang = selectedLanguage!.code;
    } else {
      lang = languages.first.code;
    }

    await Future.delayed(Duration.zero);
    Loading.setInstance(context);
    Loading().show();

    var productResponse =
        await ProductRepository().productEdit(id: widget.productId, lang: lang);

    Loading().hide();
    if (productResponse.result!) {
      isProductDetailsInit = true;
      ////print("result true");
      setInitialValue(productResponse.data!);
    }
  }

  Future getLanguages() async {
    var languageListResponse = await LanguageRepository().getLanguageList();
    languages.addAll(languageListResponse.languages!);

    setChange();

    return;
  }

  @override
  void initState() {
    getLanguages().then((value) {
      getProductCurrentValues();
    });
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    mHeight = MediaQuery.of(context).size.height;
    mWidht = MediaQuery.of(context).size.width;
    if (Loading.getInstance() == null) {
      Loading.setInstance(context);
    }
    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.paper,
        appBar: buildAppBar(context) as PreferredSizeWidget?,
        body: SingleChildScrollView(
          // New key per tab so each tab opens at the top.
          key: ValueKey(_selectedTabIndex),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: buildBodyContainer(),
        ),
        bottomNavigationBar: buildBottomAppBar(context),
      ),
    );
  }

  Widget buildBodyContainer() {
    return changeMainContent(_selectedTabIndex);
  }

  Widget buildBottomAppBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: MyTheme.hairline)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: () => submitProduct(),
            child: Text(LangText(context: context).getLocal().update_now_ucf,
                style: AppTheme.body(
                    size: 16, weight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  changeMainContent(int index) {
    switch (index) {
      case 0:
        return buildGeneral();
        break;
      case 1:
        return buildMedia();
        break;
      case 2:
        return buildPriceNStock();
        break;
      case 3:
        return buildSEO();
        break;
      case 4:
        return buildShipping();
        break;
      case 5:
        //return buildMarketing();
        break;
      default:
        return Container();
    }
  }

  /// White panel with a title; every tab is a stack of these.
  Widget _section(String title, List<Widget> children, {Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MyTheme.radius_card),
        border: Border.all(color: MyTheme.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: buildGroupTitle(title)),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// Step counter above the sections: "1 / 5  General".
  Widget _stepHeader(int index, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
              text: "${index + 1} / 5   ",
              style: AppTheme.body(
                  size: 14, weight: FontWeight.w600, color: MyTheme.royal)),
          TextSpan(text: title),
        ]),
        style: AppTheme.body(
            size: 18, weight: FontWeight.w600, color: MyTheme.navy),
      ),
    );
  }

  Widget buildGeneral() {
    final l = LangText(context: context).getLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(0, l.general_ucf),
        _section(l.product_information_ucf, [
          buildEditTextField(
            l.product_name_ucf,
            l.product_name_ucf,
            productNameEditTextController,
            isMandatory: true,
          ),
          itemSpacer(height: 16),
          _buildDropDownField(l.brands_ucf, (value) {
            selectedBrand = value;
            setChange();
          }, selectedBrand, brands),
          itemSpacer(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: buildEditTextField(
                    l.unit_ucf, l.unit_eg_ucf, unitEditTextController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildEditTextField(
                    l.weight_in_kg_ucf, "0.0", weightEditTextController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
              ),
            ],
          ),
          itemSpacer(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: buildEditTextField(l.minimum_purchase_quantity_ucf,
                    "1", minimumEditTextController,
                    isMandatory: true, keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildEditTextField(
                    l.barcode_ucf, l.barcode_ucf, barcodeEditTextController),
              ),
            ],
          ),
          itemSpacer(height: 16),
          buildTagsEditTextField(l.tags_ucf,
              l.type_and_hit_enter_to_add_a_tag_ucf, tagEditTextController,
              isMandatory: true),
        ]),
        _section("${l.categories_ucf} *", [
          _buildMultiCategory("", isMandatory: false),
        ]),
        _section(l.product_description_ucf, [
          summerNote(l.product_description_ucf),
        ]),
        _section(l.options_ucf, [
          if (refund_addon.$) ...[
            buildSwitchField(l.refundable_ucf, isRefundable, (value) {
              isRefundable = value;
              setChange();
            }),
            const Divider(height: 16),
          ],
          buildSwitchField(l.cash_on_delivery_ucf, isCashOnDelivery,
              (onChanged) {
            isCashOnDelivery = onChanged;
            setChange();
          }),
        ]),
        if (vatTaxList.isNotEmpty)
          _section(l.vat_n_tax_ucf, [
            for (int index = 0; index < vatTaxList.length; index++)
              buildVatTax(vatTaxList[index].vatTaxModel.name,
                  vatTaxList[index].amount, (onChangeDropDown) {
                vatTaxList[index].selectedItem = onChangeDropDown;
              }, vatTaxList[index].selectedItem, vatTaxList[index].items),
          ]),
      ],
    );
  }

  Widget buildVatTax(title, TextEditingController controller, onChangeDropDown,
      CommonDropDownItem? selectedDropdown, List<CommonDropDownItem> iteams) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: buildEditTextField(title, "0", controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDropDown((newValue) {
              onChangeDropDown(newValue);
              setChange();
            }, selectedDropdown, iteams),
          ),
        ],
      ),
    );
  }

  Widget buildMedia() {
    final l = LangText(context: context).getLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(1, l.media_ucf),
        _section(l.product_images_ucf, [
          chooseGalleryImageField(),
          itemSpacer(height: 16),
          chooseSingleImageField(l.thumbnail_image_300_ucf,
              l.thumbnail_image_300_des, (onChosenImage) {
            thumbnailImage = onChosenImage;
            setChange();
          }, thumbnailImage),
        ]),
        _section(l.product_videos_ucf, [
          _buildDropDownField(l.video_provider_ucf, (newValue) {
            selectedVideoType = newValue;
            setChange();
          }, selectedVideoType, videoType),
          itemSpacer(height: 16),
          buildEditTextField(
              l.video_link_ucf, l.video_link_ucf, videoLinkEditTextController,
              keyboardType: TextInputType.url),
          itemSpacer(height: 6),
          smallTextForMessage(l.video_link_des),
        ]),
        _section(l.pdf_description_ucf, [
          chooseSingleFileField(l.pdf_specification_ucf, "", (onChosenFile) {
            pdfDes = onChosenFile;
            setChange();
          }, pdfDes),
        ]),
      ],
    );
  }

  Widget buildPriceNStock() {
    final l = LangText(context: context).getLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(2, l.price_n_stock_ucf),
        // ---- price & discount ----
        _section(l.price_ucf, [
          buildPriceEditTextField(l.unit_price_ucf, "0", unitPriceEditTextController,
              isMandatory: true),
          itemSpacer(height: 16),
          buildCommonSingleField(
            l.discount_date_range_ucf,
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MyTheme.radius_control),
                side: const BorderSide(color: MyTheme.hairline, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () async {
                  dateTimeRange = await _buildPickDate();
                  if (dateTimeRange == null) return;
                  _statAndEndTime =
                      "${intl.DateFormat('d/MM/y').format(dateTimeRange!.start)} - ${intl.DateFormat('d/MM/y').format(dateTimeRange!.end)}";
                  setChange();
                },
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(_statAndEndTime,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.body(
                                size: 16, color: MyTheme.dark_grey)),
                      ),
                      Icon(Icons.calendar_today_outlined,
                          size: 18, color: MyTheme.dark_grey),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
          itemSpacer(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: buildEditTextField(
                    l.discount_ucf, "0", productDiscountEditTextController,
                    isMandatory: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropDown((onchange) {
                  selectedProductDiscountType = onchange;
                  setChange();
                }, selectedProductDiscountType, discountTypeList),
              ),
            ],
          ),
        ]),

        // ---- stock ----
        _section(l.quantity_ucf, [
          if (productVariations.isEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: buildEditTextField(l.quantity_ucf, "0",
                      productQuantityEditTextController,
                      isMandatory: true, keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildEditTextField(l.sku_all_capital,
                      l.sku_all_capital, skuEditTextController),
                ),
              ],
            ),
            itemSpacer(height: 16),
          ],
          buildEditTextField(l.low_stock_quantity_warning_ucf, "0",
              lowStockQuantityTextEditTextController,
              keyboardType: TextInputType.number),
          itemSpacer(height: 16),
          buildFieldTitle(l.stock_visibility_state_ucf),
          const SizedBox(height: 4),
          for (int index = 0; index < stockVisibilityStateList.length; index++)
            buildSwitchField(stockVisibilityStateList[index].title,
                stockVisibilityStateList[index].isActive, (changedValue) {
              for (var element in stockVisibilityStateList) {
                if (element.key == stockVisibilityStateList[index].key) {
                  stockVisibilityStateList[index].isActive = true;
                } else {
                  element.isActive = false;
                }
              }
              selectedstockVisibilityState = stockVisibilityStateList[index];
              setChange();
            }),
        ]),

        // ---- variations ----
        _section(l.product_variation_ucf, [
          buildSwitchField(l.colors_ucf, isColorActive, (onChanged) {
            isColorActive = onChanged;
            selectedColors.clear();
            selectedColor = null;
            createProductVariation();
            setChange();
          }),
          if (isColorActive) ...[
            itemSpacer(height: 8),
            _buildColorDropDown((value) {
              selectedColor = value;
              if (!selectedColors.contains(value)) {
                selectedColors.add(value);
              }
              setChange();
              createProductVariation();
            }, selectedColor, colorList),
            const SizedBox(height: 10),
            buildShowSelectedOptions(selectedColors, (index) {
              selectedColors.removeAt(index);
              setChange();
              createProductVariation();
            }),
          ],
          itemSpacer(height: 16),
          buildCommonSingleField(
              l.attributes_ucf,
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: _fieldDecoration,
                child: DropdownButton<AttributesModel>(
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  isExpanded: true,
                  style: AppTheme.body(size: 16, color: MyTheme.ink),
                  onChanged: (AttributesModel? value) {
                    selectedAttribute = value;

                    var tmp = selectedAttributes.where(
                        (element) => element.name.key == value!.name.key);

                    if (tmp.isEmpty) {
                      selectedAttributes.add(AttributesModel(
                          value!.name, value.attributeItems, [], null));
                    }
                    createProductVariation();
                    setChange();
                  },
                  icon: Icon(Icons.expand_more_rounded,
                      color: MyTheme.dark_grey),
                  value: selectedAttribute,
                  items: attribute
                      .map(
                        (value) => DropdownMenuItem<AttributesModel>(
                          value: value,
                          child: Text(value.name.value!),
                        ),
                      )
                      .toList(),
                ),
              )),
          if (selectedAttributes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14.0),
              child: Column(
                children: List.generate(selectedAttributes.length, (index) {
                  return buildAttributeModelView(
                      index,
                      selectedAttributes[index].name.value,
                      selectedAttributes[index].attributeItems,
                      selectedAttributes[index].selectedAttributeItem,
                      (onchange) {
                    selectedAttributes[index].selectedAttributeItem = onchange;
                    if (!selectedAttributes[index]
                        .selectedAttributeItems
                        .contains(onchange)) {
                      selectedAttributes[index]
                          .selectedAttributeItems
                          .add(onchange);
                    }
                    setChange();
                    createProductVariation();
                  }, (removeIndex) {
                    selectedAttributes.removeAt(removeIndex);
                    setChange();
                    createProductVariation();
                  });
                }),
              ),
            ),
          if (productVariations.isNotEmpty) ...[
            itemSpacer(height: 16),
            ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) => variationViewModel(index),
                separatorBuilder: (context, index) => itemSpacer(height: 12),
                itemCount: productVariations.length),
          ],
        ]),

        // ---- external link ----
        _section(l.external_link_ucf, [
          buildEditTextField(l.external_link_ucf, "https://",
              externalLinkEditTextController,
              keyboardType: TextInputType.url),
          itemSpacer(height: 16),
          buildEditTextField(
              l.external_link_button_text_ucf,
              l.external_link_button_text_ucf,
              externalLinkButtonTextEditTextController),
          itemSpacer(height: 6),
          smallTextForMessage(
              l.leave_it_blank_if_you_do_not_use_external_site_link),
        ]),
      ],
    );
  }

  Widget buildSEO() {
    final l = LangText(context: context).getLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(3, l.seo_all_capital),
        _section(l.seo_all_capital, [
          buildEditTextField(
              l.meta_title_ucf, l.meta_title_ucf, metaTitleEditTextController),
          itemSpacer(height: 16),
          buildCommonSingleField(
            l.description_ucf.replaceAll(":", ""),
            TextField(
              controller: metaDescriptionEditTextController,
              keyboardType: TextInputType.multiline,
              minLines: 4,
              maxLines: 8,
              style: AppTheme.body(size: 16, color: MyTheme.ink),
              decoration: InputDecoration(
                  hintText: l.description_ucf.replaceAll(":", "")),
            ),
          ),
          itemSpacer(height: 16),
          buildEditTextField(l.slug_ucf, l.slug_ucf, slugEditTextController),
          itemSpacer(height: 16),
          chooseSingleImageField(l.meta_image_ucf, "", (onChosenImage) {
            metaImage = onChosenImage;
            setChange();
          }, metaImage),
        ]),
      ],
    );
  }

  Widget buildShipping() {
    final l = LangText(context: context).getLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader(4, l.shipping_ucf),
        _section(l.shipping_configuration_ucf, [
          if (shipping_type.$) ...[
            for (int index = 0;
                index < shippingConfigurationList.length;
                index++)
              buildSwitchField(shippingConfigurationList[index].title,
                  shippingConfigurationList[index].isActive, (changedValue) {
                for (var element in shippingConfigurationList) {
                  if (element.key == shippingConfigurationList[index].key) {
                    shippingConfigurationList[index].isActive = true;
                  } else {
                    element.isActive = false;
                  }
                }
                selectedShippingConfiguration =
                    shippingConfigurationList[index];
                setChange();
              }),
            if (selectedShippingConfiguration.key == "flat_rate") ...[
              itemSpacer(height: 12),
              buildEditTextField(l.shipping_cost_ucf, "0",
                  flatShippingCostTextEditTextController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true)),
            ],
          ] else
            Text(l.shipping_configuration_is_maintained_by_admin,
                style: AppTheme.body(size: 14, color: MyTheme.dark_grey)),
        ]),
        _section(l.estimate_shipping_time_ucf, [
          buildCommonSingleField(
            l.shipping_days_ucf,
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
              ],
              controller: shippingDayEditTextController,
              style: AppTheme.body(size: 16, color: MyTheme.ink),
              decoration: InputDecoration(
                hintText: "0",
                suffixIcon: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 16),
                  child: Center(
                    widthFactor: 1,
                    child: Text(getLocal(context).days_ucf,
                        style: AppTheme.body(
                            size: 14,
                            weight: FontWeight.w500,
                            color: MyTheme.dark_grey)),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ],
    );
  }

/*
  Widget buildMarketing() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: AppStyles.itemMargin,
            right: AppStyles.itemMargin,
            top: AppStyles.itemMargin,
          ),
          child: Container(
            padding: EdgeInsets.all(AppStyles.itemMargin),
            decoration: _fieldDecoration,
            child: buildGroupItems(
              LangText(context: context).getLocal().product_add_screen_featured,
              Container(
                child: Column(
                  children: [
                    buildSwitchField(
                        LangText(context: context)
                            .getLocal()
                            .product_add_screen_status,
                        isFeatured, (changedValue) {
                      isFeatured = changedValue;
                      setChange();
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: AppStyles.itemMargin,
            right: AppStyles.itemMargin,
            top: AppStyles.itemMargin,
          ),
          child: Container(
            padding: EdgeInsets.all(AppStyles.itemMargin),
            decoration: _fieldDecoration,
            child: buildGroupItems(
                LangText(context: context)
                    .getLocal()
                    .product_add_screen_todays_deal,
                Container(
                  child: Column(
                    children: [
                      buildSwitchField(
                          LangText(context: context)
                              .getLocal()
                              .product_add_screen_status,
                          isTodaysDeal, (changedValue) {
                        isTodaysDeal = changedValue;
                        setChange();
                      }),
                    ],
                  ),
                )),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            left: AppStyles.itemMargin,
            right: AppStyles.itemMargin,
            top: AppStyles.itemMargin,
          ),
          child: Container(
            padding: EdgeInsets.all(AppStyles.itemMargin),
            decoration: _fieldDecoration,
            child: buildGroupItems(
              LangText(context: context)
                  .getLocal()
                  .product_add_screen_flash_deal,
              Column(
                children: [
                  _buildFlatDropDown(
                      LangText(context: context)
                          .getLocal()
                          .product_add_screen_add_to_flash, (onchange) {
                    selectedAddToFlashType = onchange;
                    setChange();
                  }, selectedAddToFlashType, addToFlashType),
                  itemSpacer(),
                  buildFlatEditTextField(
                      LangText(context: context)
                          .getLocal()
                          .product_add_screen_discount,
                      "0",
                      flashDiscountEditTextController),
                  itemSpacer(),
                  _buildFlatDropDown(
                      LangText(context: context)
                          .getLocal()
                          .product_add_screen_discount_type, (onchange) {
                    selectedFlashDiscountType = onchange;
                    setChange();
                  }, selectedFlashDiscountType, discountTypeList),
                  itemSpacer(),
                ],
              ),
            ),
          ),
        ),
        itemSpacer()
      ],
    );
  }*/

  Widget buildTabViewItem(String title, Widget children) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppStyles.itemMargin,
        right: AppStyles.itemMargin,
        top: AppStyles.itemMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: MyTheme.font_grey),
            ),
          const SizedBox(
            height: 16,
          ),
          children,
        ],
      ),
    );
  }

  Widget buildAttributeModelView(
      index,
      attributeName,
      List<CommonDropDownItem> attributesValues,
      selectedValue,
      dynamic onchange,
      dynamic remove) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: 72, child: buildFieldTitle(attributeName)),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
              height: 48,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: _fieldDecoration,
              child: DropdownButton<CommonDropDownItem>(
                isDense: true,
                underline: Container(),
                isExpanded: true,
                onChanged: (CommonDropDownItem? value) {
                  onchange(value);
                },
                icon: Icon(Icons.expand_more_rounded, color: MyTheme.dark_grey),
                value: selectedValue,
                items: attributesValues
                    .map(
                      (value) => DropdownMenuItem<CommonDropDownItem>(
                        value: value,
                        child: Text(
                          value.value!,
                        ),
                      ),
                    )
                    .toList(),
              ),
            )),
            SizedBox(
              width: 44,
              child: IconButton(
                  onPressed: () {
                    remove(index);
                  },
                  icon: Icon(
                    Icons.delete,
                    color: MyTheme.red,
                  )),
            )
          ],
        ),
        SizedBox(
          height: 10,
        ),
        buildShowSelectedOptions(
            selectedAttributes[index].selectedAttributeItems, (deleteIndex) {
          selectedAttributes[index]
              .selectedAttributeItems
              .removeAt(deleteIndex);
          setChange();
          createProductVariation();
        })
      ],
    );
  }

  Widget buildGroupItems(groupTitle, Widget children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildGroupTitle(groupTitle),
        itemSpacer(height: 14.0),
        children,
      ],
    );
  }

  Text buildGroupTitle(title) {
    return Text(
      title,
      style: AppTheme.body(size: 18, weight: FontWeight.w600, color: MyTheme.navy),
    );
  }

  Widget chooseGalleryImageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LangText(context: context).getLocal().gallery_images_600,
              style: AppTheme.body(
                  size: 14, weight: FontWeight.w600, color: MyTheme.navy),
            ),
            SizedBox(
              height: 10,
            ),
            Buttons(
              padding: EdgeInsets.zero,
              onPressed: () {
                pickGalleryImages();
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              child: MyWidget().myContainer(
                  width: DeviceInfo(context).getWidth(),
                  height: 48,
                  borderRadius: MyTheme.radius_control,
                  borderColor: MyTheme.hairline,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 14.0),
                        child: Text(
                          getLocal(context).choose_file,
                          style: AppTheme.body(size: 14, color: MyTheme.dark_grey),
                        ),
                      ),
                      Container(
                          alignment: Alignment.center,
                          height: 48,
                          width: 88,
                          color: MyTheme.blue_tint,
                          child: Text(
                            getLocal(context).browse_ucf,
                            style: AppTheme.body(
                                size: 14,
                                weight: FontWeight.w600,
                                color: MyTheme.navy),
                          )),
                    ],
                  )),
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        Text(
          LangText(context: context)
              .getLocal()
              .these_images_are_visible_in_product_details_page_gallery_600,
          style: AppTheme.body(size: 12, color: MyTheme.dark_grey),
        ),
        SizedBox(
          height: 10,
        ),
        if (productGalleryImages.isNotEmpty)
          Wrap(
            children: List.generate(
              productGalleryImages.length,
              (index) => Stack(
                children: [
                  MyWidget.imageWithPlaceholder(
                      height: 60.0,
                      width: 60.0,
                      url: productGalleryImages[index].url),
                  Positioned(
                    top: 0,
                    right: 5,
                    child: Container(
                      height: 15,
                      width: 15,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: MyTheme.white),
                      child: InkWell(
                        onTap: () {
                          ////print(index);
                          productGalleryImages.removeAt(index);
                          setState(() {});
                        },
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: MyTheme.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget chooseSingleImageField(String title, String shortMessage,
      dynamic onChosenImage, FileInfo? selectedFile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.body(
                  size: 14, weight: FontWeight.w600, color: MyTheme.navy),
            ),
            SizedBox(
              height: 10,
            ),
            imageField(shortMessage, onChosenImage, selectedFile)
          ],
        ),
      ],
    );
  }

  Widget chooseSingleFileField(String title, String shortMessage,
      dynamic onChosenFile, FileInfo? selectedFile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTheme.body(
                  size: 14, weight: FontWeight.w600, color: MyTheme.navy),
            ),
            SizedBox(
              height: 10,
            ),
            fileField("document", shortMessage, onChosenFile, selectedFile)
          ],
        ),
      ],
    );
  }

  Widget buildShowSelectedOptions(
      List<CommonDropDownItem> options, dynamic remove) {
    return SizedBox(
      width: DeviceInfo(context).getWidth() - 34,
      child: Wrap(
        children: List.generate(
            options.length,
            (index) => Container(
                decoration: BoxDecoration(
                    color: MyTheme.blue_tint,
                    borderRadius: BorderRadius.circular(999)),
                constraints: BoxConstraints(
                    maxWidth: (DeviceInfo(context).getWidth() - 50) / 4),
                margin: const EdgeInsets.only(right: 5, bottom: 5),
                child: Stack(
                  children: [
                    Container(
                        padding: const EdgeInsets.only(
                            left: 10, right: 20, top: 5, bottom: 5),
                        constraints: BoxConstraints(
                            maxWidth:
                                (DeviceInfo(context).getWidth() - 50) / 4),
                        child: Text(
                          options[index].value!.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                              size: 13,
                              weight: FontWeight.w600,
                              color: MyTheme.navy),
                        )),
                    Positioned(
                      right: 2,
                      child: InkWell(
                        onTap: () {
                          remove(index);
                        },
                        child: Icon(Icons.highlight_remove,
                            size: 15, color: MyTheme.red),
                      ),
                    )
                  ],
                ))),
      ),
    );
  }

  Widget imageField(
      String shortMessage, dynamic onChosenImage, FileInfo? selectedFile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Buttons(
          padding: EdgeInsets.zero,
          onPressed: () async {
            // XFile chooseFile = await pickSingleImage();
            List<FileInfo> chooseFile = await (Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UploadFile(
                          fileType: "image",
                          canSelect: true,
                        ))));
            ////print("chooseFile.url");
            ////print(chooseFile.first.url);
            if (chooseFile.isNotEmpty) {
              onChosenImage(chooseFile.first);
            }
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          child: MyWidget().myContainer(
            width: DeviceInfo(context).getWidth(),
            height: 48,
            borderRadius: MyTheme.radius_control,
            borderColor: MyTheme.hairline,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Text(
                    getLocal(context).choose_file,
                    style: AppTheme.body(size: 14, color: MyTheme.dark_grey),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  height: 48,
                  width: 88,
                  color: MyTheme.blue_tint,
                  child: Text(
                    getLocal(context).browse_ucf,
                    style: AppTheme.body(size: 14, color: MyTheme.dark_grey),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (shortMessage.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 10,
              ),
              Text(
                shortMessage,
                style: AppTheme.body(size: 12, color: MyTheme.dark_grey),
              ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        if (selectedFile != null)
          Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                height: 60,
                width: 70,
              ),
              MyWidget.imageWithPlaceholder(
                  border: Border.all(width: 0.5, color: MyTheme.light_grey),
                  radius: BorderRadius.circular(5),
                  height: 50.0,
                  width: 50.0,
                  url: selectedFile.url),
              Positioned(
                top: 3,
                right: 2,
                child: Container(
                  height: 15,
                  width: 15,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: MyTheme.light_grey),
                  child: InkWell(
                    onTap: () {
                      onChosenImage(null);
                    },
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: MyTheme.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget fileField(String fileType, String shortMessage, dynamic onChosenFile,
      FileInfo? selectedFile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Buttons(
          padding: EdgeInsets.zero,
          onPressed: () async {
            List<FileInfo> chooseFile = await (Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UploadFile(
                  fileType: fileType,
                  canSelect: true,
                ),
              ),
            ));
            ////print("chooseFile.url");
            ////print(chooseFile.first.url);
            if (chooseFile.isNotEmpty) {
              onChosenFile(chooseFile.first);
            }
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          child: MyWidget().myContainer(
            width: DeviceInfo(context).getWidth(),
            height: 48,
            borderRadius: MyTheme.radius_control,
            borderColor: MyTheme.hairline,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Text(
                    getLocal(context).choose_file,
                    style: AppTheme.body(size: 14, color: MyTheme.dark_grey),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  height: 48,
                  width: 88,
                  color: MyTheme.blue_tint,
                  child: Text(
                    getLocal(context).browse_ucf,
                    style: AppTheme.body(size: 14, color: MyTheme.dark_grey),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        if (shortMessage.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shortMessage,
                style: AppTheme.body(size: 12, color: MyTheme.dark_grey),
              ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        if (selectedFile != null)
          Stack(
            children: [
              Container(
                padding: EdgeInsets.all(3),
                height: 40,
                alignment: Alignment.center,
                width: 40,
                decoration: BoxDecoration(
                  color: MyTheme.grey_153,
                ),
                child: Text(
                  "${selectedFile.fileOriginalName!}.${selectedFile.extension!}",
                  style: TextStyle(fontSize: 9, color: MyTheme.white),
                ),
              ),
              Positioned(
                top: 0,
                right: 5,
                child: Container(
                  height: 15,
                  width: 15,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: MyTheme.white),
                  // remove the selected file button
                  child: InkWell(
                    onTap: () {
                      onChosenFile(null);
                    },
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: MyTheme.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  summerNote(title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: MyTheme.font_grey),
        ),
        const SizedBox(
          height: 10,
        ),
        SizedBox(
          height: 250,
          width: mWidht,
          //child: summernote??Container(),
          child: FlutterSummernote(
              showBottomToolbar: false,
              returnContent: (text) {
                description = text;
                ////print(description);
              },
              hint: "",
              value: description,
              key: productDescriptionKey),
        ),
      ],
    );
    // FlutterSummernote(
    // hint: "Your text here...",
    // key: productDescriptionKey,
    // customToolbar: """
    //         [
    //             ['style', ['bold', 'italic', 'underline', 'clear']],
    //             ['font', ['strikethrough', 'superscript', 'subscript']]
    //         ]"""
    // )
  }

  Widget smallTextForMessage(String txt) {
    return Text(
      txt,
      style: AppTheme.body(size: 12, color: MyTheme.dark_grey),
    );
  }

  setChange() {
    setState(() {});
  }

  Widget itemSpacer({double height = 24}) {
    return SizedBox(
      height: height,
    );
  }

  Widget _buildDropDownField(String title, dynamic onchange,
      CommonDropDownItem? selectedValue, List<CommonDropDownItem> itemList,
      {bool isMandatory = false, double? width}) {
    return buildCommonSingleField(
        title, _buildDropDown(onchange, selectedValue, itemList, width: width),
        isMandatory: isMandatory);
  }

  Widget _buildMultiCategory(String title,
      {bool isMandatory = false, double? width}) {
    //print("object $categoryIds");
    return buildCommonSingleField(
        title,
        Container(
            height: 260,
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: _fieldDecoration,
            child: SingleChildScrollView(
              child: isProductDetailsInit
                  ? MultiCategory(
                      isCategoryInit: isCategoryInit,
                      categories: categories,
                      onSelectedCategories: (categories) {
                        categoryIds = categories;
                      },
                      onSelectedMainCategory: (mainCategory) {
                        categoryId = mainCategory;
                      },
                      initialCategoryIds: categoryIds,
                      initialMainCategory: categoryId,
                    )
                  : SizedBox.shrink(),
            )),
        isMandatory: isMandatory);
  }

  Widget _buildDropDown(dynamic onchange, CommonDropDownItem? selectedValue,
      List<CommonDropDownItem> itemList,
      {double? width}) {
    return Container(
      height: 48,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: _fieldDecoration,
      child: DropdownButton<CommonDropDownItem>(
        menuMaxHeight: 300,
        isDense: true,
        underline: const SizedBox.shrink(),
        isExpanded: true,
        style: AppTheme.body(size: 16, color: MyTheme.ink),
        borderRadius: BorderRadius.circular(MyTheme.radius_control),
        onChanged: (CommonDropDownItem? value) {
          onchange(value);
        },
        icon: Icon(Icons.expand_more_rounded, color: MyTheme.dark_grey),
        value: selectedValue,
        items: itemList
            .map(
              (value) => DropdownMenuItem<CommonDropDownItem>(
                value: value,
                child: Text(
                  value.value!,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildLanguageDropDown(
      dynamic onchange, Language? selectedValue, List<Language> itemList,
      {double? width}) {
    return Container(
      height: 40,
      padding: const EdgeInsetsDirectional.only(start: 4, end: 8),
      alignment: Alignment.center,
      //decoration: MDecoration,
      child: DropdownButton<Language>(
        menuMaxHeight: 300,
        isDense: true,
        underline: Container(),
        isExpanded: true,
        onChanged: (Language? value) {
          onchange(value);
        },
        icon: Icon(Icons.expand_more_rounded, color: MyTheme.dark_grey),
        value: selectedValue,
        items: itemList
            .map(
              (value) => DropdownMenuItem<Language>(
                value: value,
                child: Row(
                  children: [
                    SizedBox(
                        width: 32,
                        height: 32,
                        child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child:
                                /*Image.asset(
                          _list[index].image,
                          fit: BoxFit.fitWidth,
                        ),*/
                                FadeInImage.assetNetwork(
                              placeholder: 'assets/logo/placeholder.png',
                              image: value.image!,
                              fit: BoxFit.fitWidth,
                            ))),
                    Text(
                      value.name!,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildColorDropDown(dynamic onchange,
      CommonDropDownItem? selectedValue, List<CommonDropDownItem> itemList,
      {double? width}) {
    return Container(
      height: 48,
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: _fieldDecoration,
      child: DropdownButton<CommonDropDownItem>(
        menuMaxHeight: 300,
        isDense: true,
        underline: const SizedBox.shrink(),
        isExpanded: true,
        style: AppTheme.body(size: 16, color: MyTheme.ink),
        borderRadius: BorderRadius.circular(MyTheme.radius_control),
        onChanged: (CommonDropDownItem? value) {
          onchange(value);
        },
        icon: Icon(Icons.expand_more_rounded, color: MyTheme.dark_grey),
        value: selectedValue,
        items: itemList
            .map(
              (value) => DropdownMenuItem<CommonDropDownItem>(
                value: value,
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      height: 20,
                      width: 20,
                      decoration: BoxDecoration(
                          color: Color(
                              int.parse(value.key!.replaceAll("#", "0xFF"))),
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    Text(
                      value.value!,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFlatDropDown(String title, dynamic onchange,
      CommonDropDownItem selectedValue, List<CommonDropDownItem> itemList,
      {bool isMandatory = false, double? width}) {
    return buildCommonSingleField(
        title,
        Container(
          height: 46,
          width: width ?? mWidht,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: MyTheme.app_accent_color_extra_light),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: DropdownButton<CommonDropDownItem>(
            isDense: true,
            underline: Container(),
            isExpanded: true,
            onChanged: (value) {
              onchange(value);
            },
            icon: Icon(Icons.expand_more_rounded, color: MyTheme.dark_grey),
            value: selectedValue,
            items: itemList
                .map(
                  (value) => DropdownMenuItem<CommonDropDownItem>(
                    value: value,
                    child: Text(
                      value.value!,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        isMandatory: isMandatory);
  }

  Widget buildEditTextField(
      String title, String hint, TextEditingController textEditingController,
      {isMandatory = false, TextInputType? keyboardType}) {
    return buildCommonSingleField(
      title,
      TextField(
        controller: textEditingController,
        keyboardType: keyboardType,
        style: AppTheme.body(size: 16, color: MyTheme.ink),
        decoration: InputDecoration(hintText: hint),
      ),
      isMandatory: isMandatory,
    );
  }

  BoxDecoration get _fieldDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MyTheme.radius_control),
        border: Border.all(color: MyTheme.hairline, width: 1.5),
      );

  Widget buildTagsEditTextField(
      String title, String hint, TextEditingController textEditingController,
      {isMandatory = false}) {
    //textEditingController.buildTextSpan(context: context, withComposing: true);
    return buildCommonSingleField(
      title,
      Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        alignment: Alignment.centerLeft,
        constraints: const BoxConstraints(minHeight: 48),
        decoration: _fieldDecoration,
        child: Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          runAlignment: WrapAlignment.start,
          clipBehavior: Clip.antiAlias,
          children: List.generate(tags!.length + 1, (index) {
            if (index == tags!.length) {
              return TextField(
                onSubmitted: (string) {
                  var tag = textEditingController.text
                      .trim()
                      .replaceAll(",", "")
                      .toString();
                  addTag(tag);
                },
                onChanged: (string) {
                  if (string.trim().contains(",")) {
                    var tag = string.trim().replaceAll(",", "").toString();
                    addTag(tag);
                  }
                },
                controller: textEditingController,
                keyboardType: TextInputType.text,
                maxLines: 1,
                style: AppTheme.body(size: 16, color: MyTheme.ink),
                decoration: InputDecoration.collapsed(
                        hintText: hint,
                        hintStyle:
                            AppTheme.body(size: 14, color: MyTheme.grey_153))
                    .copyWith(constraints: BoxConstraints(maxWidth: 150)),
              );
            }
            return Container(
                decoration: BoxDecoration(
                    color: MyTheme.blue_tint,
                    borderRadius: BorderRadius.circular(999)),
                constraints: BoxConstraints(
                    maxWidth: (DeviceInfo(context).getWidth() - 50) / 4),
                margin: const EdgeInsets.only(right: 5, bottom: 5),
                child: Stack(
                  fit: StackFit.loose,
                  children: [
                    Container(
                        padding: const EdgeInsets.only(
                            left: 10, right: 20, top: 5, bottom: 5),
                        constraints: BoxConstraints(
                            maxWidth:
                                (DeviceInfo(context).getWidth() - 50) / 4),
                        child: Text(
                          tags![index]!.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                              size: 13,
                              weight: FontWeight.w600,
                              color: MyTheme.navy),
                        )),
                    Positioned(
                      right: 2,
                      child: InkWell(
                        onTap: () {
                          tags!.removeAt(index);
                          setChange();
                        },
                        child: Icon(Icons.highlight_remove,
                            size: 15, color: MyTheme.red),
                      ),
                    )
                  ],
                ));
          }),
        ),
      ),
      isMandatory: isMandatory,
    );
  }

  addTag(String string) {
    if (string.trim().isNotEmpty) {
      tags!.add(string.trim());
    }
    tagEditTextController.clear();
    setChange();
  }

  Widget buildPriceEditTextField(
      String title, String hint, TextEditingController textEditingController,
      {isMandatory = false}) {
    return buildCommonSingleField(
      title,
      TextField(
        controller: textEditingController,
        onChanged: (string) {
          if (string.isEmpty) {
            textEditingController.text = "0";
          }
          createProductVariation();
        },
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppTheme.body(size: 16, color: MyTheme.ink),
        decoration: InputDecoration(hintText: hint),
      ),
      isMandatory: isMandatory,
    );
  }

  Widget buildFlatEditTextField(
      String title, String hint, TextEditingController textEditingController,
      {isMandatory = false}) {
    return Container(
      child: buildCommonSingleField(
        title,
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: MyTheme.app_accent_color_extra_light),
          width: DeviceInfo(context).getWidth(),
          height: 45,
          child: TextField(
            controller: textEditingController,
            decoration: InputDecorations.buildInputDecoration_1(
                hint_text: hint,
                borderColor: MyTheme.noColor,
                hintTextColor: MyTheme.grey_153),
          ),
        ),
        isMandatory: isMandatory,
      ),
    );
  }

  buildCommonSingleField(title, Widget child, {isMandatory = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if ((title ?? "").toString().isNotEmpty) ...[
          Text.rich(
            TextSpan(children: [
              TextSpan(text: title),
              if (isMandatory)
                TextSpan(
                    text: " *",
                    style: AppTheme.body(
                        size: 14, weight: FontWeight.w600, color: MyTheme.red)),
            ]),
            style: AppTheme.body(
                size: 14, weight: FontWeight.w600, color: MyTheme.navy),
          ),
          const SizedBox(height: 8),
        ],
        child,
      ],
    );
  }

  Text buildFieldTitle(title) {
    return Text(
      title,
      style: AppTheme.body(size: 14, weight: FontWeight.w600, color: MyTheme.navy),
    );
  }

  variationViewModel(int index) {
    return buildExpansionTile(index, (onExpand) {
      productVariations[index].isExpended = onExpand;
      setChange();
    }, productVariations[index].isExpended);
  }

  buildExpansionTile(int index, dynamic onExpand, isExpanded) {
    return Container(
      height: isExpanded
          ? productVariations[index].photo == null
              ? 274
              : 334
          : 100,
      decoration: _fieldDecoration,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            width: 20,
            height: 20,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: MyTheme.light_grey),
            constraints: BoxConstraints(),
            child: IconButton(
              splashRadius: 5,
              splashColor: MyTheme.noColor,
              constraints: BoxConstraints(),
              iconSize: 12,
              padding: EdgeInsets.zero,
              onPressed: () {
                isExpanded = !isExpanded;
                onExpand(isExpanded);
              },
              icon: Image.asset(
                isExpanded ? "assets/icon/remove.png" : "assets/icon/add.png",
                color: MyTheme.red,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                        width: (mWidht - 120) / 2.2,
                        child: Text(
                          productVariations[index].name!,
                          style: MyTextStyle.smallFontSize()
                              .copyWith(color: MyTheme.font_grey),
                        )),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: MyTheme.app_accent_color_extra_light),
                      width: (mWidht - 120) / 2.2,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        controller:
                            productVariations[index].priceEditTextController,
                        decoration: InputDecorations.buildInputDecoration_1(
                            hint_text: "0",
                            borderColor: MyTheme.noColor,
                            hintTextColor: MyTheme.grey_153),
                      ),
                    )
                  ],
                ),
                if (isExpanded)
                  Column(
                    children: [
                      itemSpacer(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                              width: 80,
                              child: Text(
                                LangText(context: context)
                                    .getLocal()
                                    .sku_all_capital,
                                style: MyTextStyle.smallFontSize()
                                    .copyWith(color: MyTheme.font_grey),
                              )),
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: MyTheme.white),
                            width: (mWidht - 200),
                            child: TextField(
                              controller: productVariations[index]
                                  .skuEditTextController,
                              decoration:
                                  InputDecorations.buildInputDecoration_1(
                                      fillColor: MyTheme.noColor,
                                      hint_text: "sku",
                                      borderColor: MyTheme.grey_153,
                                      hintTextColor: MyTheme.grey_153),
                            ),
                          )
                        ],
                      ),
                      itemSpacer(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              LangText(context: context)
                                  .getLocal()
                                  .quantity_ucf,
                              style: MyTextStyle.smallFontSize()
                                  .copyWith(color: MyTheme.font_grey),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: MyTheme.white),
                            width: (mWidht - 200),
                            child: TextField(
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9]'))
                              ],
                              keyboardType: TextInputType.number,
                              controller: productVariations[index]
                                  .quantityEditTextController,
                              decoration:
                                  InputDecorations.buildInputDecoration_1(
                                      fillColor: MyTheme.noColor,
                                      hint_text: "0",
                                      borderColor: MyTheme.grey_153,
                                      hintTextColor: MyTheme.grey_153),
                            ),
                          )
                        ],
                      ),
                      itemSpacer(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            child: Text(
                              LangText(context: context).getLocal().photo_ucf,
                              style: MyTextStyle.smallFontSize()
                                  .copyWith(color: MyTheme.font_grey),
                            ),
                          ),
                          SizedBox(
                            width: (mWidht - 200),
                            child: imageField("", (onChosenImage) {
                              productVariations[index].photo = onChosenImage;
                              setChange();
                            }, productVariations[index].photo),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  buildSwitchField(String title, value, onChanged, {isMandatory = false}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: title),
              if (isMandatory)
                TextSpan(
                    text: " *",
                    style: AppTheme.body(
                        size: 15, weight: FontWeight.w600, color: MyTheme.red)),
            ]),
            style: AppTheme.body(
                size: 15, weight: FontWeight.w500, color: MyTheme.ink),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}


  Future<DateTimeRange?> _buildPickDate() async {
    DateTimeRange? p;
    p = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.utc(2050),
        builder: (context, child) {
          return SizedBox(
            width: 500,
            height: 500,
            child: DateRangePickerDialog(
              initialDateRange:
                  DateTimeRange(start: DateTime.now(), end: DateTime.now()),
              saveText: getLocal(context).select_ucf,
              initialEntryMode: DatePickerEntryMode.calendarOnly,
              firstDate: DateTime.now(),
              lastDate: DateTime.utc(2050),
            ),
          );
        });

    return p;
  }

  Widget buildTapBar() {
    final l = LangText(context: context).getLocal();
    final tabs = [
      l.general_ucf,
      l.media_ucf,
      l.price_n_stock_ucf,
      l.seo_all_capital,
      l.shipping_ucf,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(MyTheme.radius_control),
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (int i = 0; i < tabs.length; i++)
              Semantics(
                button: true,
                selected: _selectedTabIndex == i,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _selectedTabIndex = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: _selectedTabIndex == i
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(MyTheme.radius_control - 4),
                    ),
                    child: Text(
                      tabs[i],
                      maxLines: 1,
                      style: AppTheme.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: _selectedTabIndex == i
                            ? MyTheme.navy
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MyTheme.navy,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: AppTheme.darkStatusBar,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: const Border(),
      titleSpacing: 0,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const BackButtonIcon(),
        color: Colors.white,
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        LangText(context: context).getLocal().update_product_ucf,
        style: AppTheme.body(
            size: 18, weight: FontWeight.w600, color: Colors.white),
      ),
      actions: [
        if (languages.isNotEmpty)
          Container(
            height: 40,
            width: 150,
            margin: const EdgeInsetsDirectional.only(end: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MyTheme.radius_control),
            ),
            child: _buildLanguageDropDown((onchange) {
              selectedLanguage = onchange;
              setChange();
              getProductCurrentValues();
            }, selectedLanguage, languages),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: buildTapBar(),
      ),
    );
  }
}

class VariationModel {
  String? name;

  FileInfo? photo;
  TextEditingController priceEditTextController,
      quantityEditTextController,
      skuEditTextController;
  bool isExpended;

  VariationModel(
      this.name,
      //this.id,
      this.photo,
      this.priceEditTextController,
      this.quantityEditTextController,
      this.skuEditTextController,
      this.isExpended);
}

// class AttributeItemsModel {
//   List<CommonDropDownItem> attributeItems;
//   List<CommonDropDownItem> selectedAttributeItems;
//   CommonDropDownItem selectedAttributeItem;
//
//   AttributeItemsModel(this.attributeItems, this.selectedAttributeItems,
//       this.selectedAttributeItem);
// }

class Tags {
  static List<String> tags = [];

  static toJson() {
    Map<String, String> map = {};

    for (var element in tags) {
      map.addAll({"value": element});
    }

    return map;
  }

  static string() {
    return jsonEncode(toJson());
  }
}
