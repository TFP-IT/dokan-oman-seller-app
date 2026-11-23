import 'package:active_ecommerce_seller_app/custom/device_info.dart';
import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/my_widget.dart';
import 'package:active_ecommerce_seller_app/custom/route_transaction.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/data_model/products_response.dart';
import 'package:active_ecommerce_seller_app/helpers/main_helper.dart';
import 'package:active_ecommerce_seller_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/product_repository.dart';
import 'package:active_ecommerce_seller_app/screens/product/new_product.dart';
import 'package:active_ecommerce_seller_app/screens/product/update_product.dart';
import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_seller_app/l10n/app_localizations.dart';
import 'package:route_transitions/route_transitions.dart';
import 'package:toast/toast.dart';

class Products extends StatefulWidget {
  final bool fromBottomBar;

  const Products({super.key, this.fromBottomBar = false});

  @override
  _ProductsState createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  bool _isProductInit = false;
  bool _showMoreProductLoadingContainer = false;

  List<Product> _productList = [];

  // List<bool> _productStatus=[];
  // List<bool> _productFeatured=[];

  int? _totalProducts;
  late BuildContext loadingContext;
  late BuildContext switchContext;
  late BuildContext featuredSwitchContext;

  //MenuOptions _menuOptionSelected = MenuOptions.Published;

  final ScrollController _scrollController =
      ScrollController(initialScrollOffset: 0);

  // double variables
  double mHeight = 0.0, mWidht = 0.0;
  int _page = 1;

  getProductList() async {
    var productResponse = await ProductRepository().getProducts(page: _page);
    if (productResponse.data!.isEmpty && _page > 1) {
      // Only when paging past the end; the first load shows an empty state.
      ToastComponent.showDialog(
          LangText(context: context).getLocal().no_more_products_ucf,
          gravity: Toast.center,
          bgColor: MyTheme.white,
          textStyle: TextStyle(color: MyTheme.ink));
    }
    _productList.addAll(productResponse.data!);
    _totalProducts = productResponse.meta?.total ?? _productList.length;
    _showMoreProductLoadingContainer = false;
    _isProductInit = true;
    setState(() {});
  }

  duplicateProduct(int? id) async {
    loading();
    var response = await ProductRepository().productDuplicateReq(id: id);
    Navigator.pop(loadingContext);
    if (response.result) {
      resetAll();
    }
    ToastComponent.showDialog(
      response.message,
      gravity: Toast.center,
      duration: 3,
      textStyle: TextStyle(color: MyTheme.black),
    );
  }

  deleteProduct(int? id) async {
    loading();
    var response = await ProductRepository().productDeleteReq(id: id);
    Navigator.pop(loadingContext);
    if (response.result) {
      resetAll();
    }
    ToastComponent.showDialog(
      response.message,
      gravity: Toast.center,
      duration: 3,
      textStyle: TextStyle(color: MyTheme.black),
    );
  }

  productStatusChange(int? index, bool value, setState, id) async {
    loading();
    var response = await ProductRepository()
        .productStatusChangeReq(id: id, status: value ? 1 : 0);
    Navigator.pop(loadingContext);
    if (response.result) {
      // _productStatus[index] = value;
      _productList[index!].status = value;
      resetAll();
    }
    Navigator.pop(switchContext);
    ToastComponent.showDialog(
      response.message,
      gravity: Toast.center,
      duration: 3,
      textStyle: TextStyle(color: MyTheme.black),
    );
  }

  productFeaturedChange({int? index, required bool value, setState, id}) async {
    print(value);
    loading();
    var response = await ProductRepository()
        .productFeaturedChangeReq(id: id, featured: value ? 1 : 0);
    Navigator.pop(loadingContext);

    if (response.result) {
      // _productFeatured[index]=value;
      _productList[index!].featured = value;
      resetAll();
    }
    Navigator.pop(featuredSwitchContext);

    ToastComponent.showDialog(
      response.message,
      gravity: Toast.center,
      duration: 3,
      textStyle: TextStyle(color: MyTheme.black),
    );
  }

  scrollControllerPosition() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _showMoreProductLoadingContainer = true;
        setState(() {
          _page++;
        });
        getProductList();
      }
    });
  }

  cleanAll() {
    _isProductInit = false;
    _showMoreProductLoadingContainer = false;
    _productList = [];
    _page = 1;
    // _productStatus=[];
    // _productFeatured=[];
    _totalProducts = null;
    setState(() {});
  }

  fetchAll() {
    getProductList();
    setState(() {});
  }

  resetAll() {
    cleanAll();
    fetchAll();
  }

  _tabOption(int index, productId, listIndex) {
    switch (index) {
      case 0:
        slideRightWidget(
                newPage: UpdateProduct(
                  productId: productId,
                ),
                context: context)
            .then((value) {
          resetAll();
        });
        break;
      case 1:
        showPublishUnPublishDialog(listIndex, productId);
        break;
      case 2:
        showFeaturedUnFeaturedDialog(listIndex, productId);
        break;
      case 3:
        showDeleteWarningDialog(productId);
        //deleteProduct(productId);
        break;
      case 4:
        print(productId);
        duplicateProduct(productId);
        break;
      default:
        break;
    }
  }

  @override
  void initState() {
    scrollControllerPosition();
    fetchAll();
    super.initState();
  }

  // ---------------------------------------------------------------------------
  // UI — follows the delivery app: navy hero with the key number and a gold
  // action, a blue-tint link row, and hairline white panels for the list.
  // ---------------------------------------------------------------------------

  void _openNewProduct() {
    MyTransaction(context: context).push(NewProduct()).then((value) {
      resetAll();
    });
  }

  void _openProduct(productId) {
    slideRightWidget(newPage: UpdateProduct(productId: productId), context: context)
        .then((value) {
      resetAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    mHeight = MediaQuery.of(context).size.height;
    mWidht = MediaQuery.of(context).size.width;
    final l = LangText(context: context).getLocal();

    final body = RefreshIndicator(
      color: MyTheme.navy,
      backgroundColor: Colors.white,
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () async {
        resetAll();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildTop2BoxContainer(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  productsContainer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Directionality(
      textDirection:
          app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: MyTheme.paper,
        appBar: !widget.fromBottomBar
            ? AppBar(
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
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                title: Text(l.products_ucf,
                    style: AppTheme.body(
                        size: 18,
                        weight: FontWeight.w600,
                        color: Colors.white)),
              )
            : null,
        body: body,
      ),
    );
  }

  /// Navy hero: total product count as the big number, gold "add" action.
  Widget buildTop2BoxContainer(BuildContext context) {
    final l = LangText(context: context).getLocal();
    final loaded = _totalProducts != null;
    return Container(
      color: MyTheme.navy,
      child: InkWell(
        onTap: _openNewProduct,
        splashColor: Colors.white24,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 16, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.my_products_ucf,
                        style: AppTheme.body(
                            size: 16,
                            weight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8))),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(loaded ? "$_totalProducts" : "–",
                          maxLines: 1,
                          style: AppTheme.figure(72,
                              color: loaded
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35))),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 12),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                          color: MyTheme.amber, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded,
                          color: MyTheme.navy, size: 26),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 96,
                      child: Text(l.add_new_product_ucf,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: AppTheme.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                              height: 1.2)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget productsContainer() {
    final l = LangText(context: context).getLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(l.all_products_ucf,
              style: AppTheme.body(
                  size: 18, weight: FontWeight.w600, color: MyTheme.navy)),
        ),
        if (!_isProductInit)
          ...List.generate(4, (_) => const _ProductCardPlaceholder())
        else if (_productList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 72),
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 40, color: MyTheme.dark_grey),
                const SizedBox(height: 12),
                Text(l.no_data_is_available,
                    textAlign: TextAlign.center,
                    style: AppTheme.body(size: 16, color: MyTheme.dark_grey)),
              ],
            ),
          )
        else ...[
          for (int i = 0; i < _productList.length; i++)
            productItem(
                index: i,
                productId: _productList[i].id,
                imageUrl: _productList[i].thumbnailImg,
                productTitle: _productList[i].name ?? "",
                category: _productList[i].category ?? "",
                productPrice: _productList[i].price.toString(),
                quantity: _productList[i].quantity.toString()),
          moreProductLoading(),
        ],
      ],
    );
  }

  Widget productItem(
      {int? index,
      productId,
      String? imageUrl,
      required String productTitle,
      required category,
      required String productPrice,
      required String quantity}) {
    final product = _productList[index!];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MyTheme.radius_card),
          side: const BorderSide(color: MyTheme.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openProduct(productId),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 4, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyWidget.imageWithPlaceholder(
                  width: 72.0,
                  height: 72.0,
                  fit: BoxFit.cover,
                  url: imageUrl,
                  radius: BorderRadius.circular(MyTheme.radius_control),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(productTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                              size: 16,
                              weight: FontWeight.w500,
                              color: MyTheme.ink)),
                      Text(category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                              size: 12,
                              weight: FontWeight.w500,
                              color: MyTheme.dark_grey)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: Text(productPrice,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.figure(18, color: MyTheme.navy)
                                    .copyWith(
                                        height: 1.2,
                                        letterSpacing: 0,
                                        fontVariations: const [
                                      FontVariation('wght', 700),
                                      FontVariation('wdth', 88),
                                    ])),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.inventory_2_outlined,
                              size: 16, color: MyTheme.dark_grey),
                          const SizedBox(width: 4),
                          Text(quantity,
                              style: AppTheme.body(
                                  size: 14,
                                  weight: FontWeight.w500,
                                  color: MyTheme.dark_grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Tag(
                            label: product.status
                                ? getLocal(context).published
                                : getLocal(context).unpublished,
                            color:
                                product.status ? MyTheme.green : MyTheme.red,
                          ),
                          if (product.featured)
                            _Tag(
                                label: getLocal(context).featured,
                                color: MyTheme.royal),
                        ],
                      ),
                    ],
                  ),
                ),
                showOptions(listIndex: index, productId: productId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  showDeleteWarningDialog(id) {
    showDialog(
        context: context,
        builder: (context) => SizedBox(
              width: DeviceInfo(context).getWidth() * 1.5,
              child: AlertDialog(
                title: Text(
                  LangText(context: context).getLocal().warning_ucf,
                  style: AppTheme.body(
                      size: 18, weight: FontWeight.w600, color: MyTheme.red),
                ),
                content: Text(
                  LangText(context: context)
                      .getLocal()
                      .do_you_want_to_delete_it,
                  style: const TextStyle(
                      fontWeight: FontWeight.w400, fontSize: 14),
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                          LangText(context: context).getLocal().no_ucf)),
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: MyTheme.red,
                          minimumSize: const Size(64, 44)),
                      onPressed: () {
                        Navigator.pop(context);
                        deleteProduct(id);
                      },
                      child: Text(
                          LangText(context: context).getLocal().yes_ucf)),
                ],
              ),
            ));
  }

  Widget showOptions({listIndex, productId}) {
    return SizedBox(
      width: 44,
      child: PopupMenuButton<MenuOptions>(
        tooltip: MaterialLocalizations.of(context).showMenuTooltip,
        icon: Icon(Icons.more_vert_rounded, color: MyTheme.dark_grey),
        onSelected: (MenuOptions result) {
          _tabOption(result.index, productId, listIndex);
          // setState(() {
          //   //_menuOptionSelected = result;
          // });
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOptions>>[
          PopupMenuItem<MenuOptions>(
            value: MenuOptions.Edit,
            child: Text(getLocal(context).edit_ucf),
          ),
          PopupMenuItem<MenuOptions>(
            value: MenuOptions.Published,
            child: Text(getLocal(context).published),
          ),
          PopupMenuItem<MenuOptions>(
            value: MenuOptions.Featured,
            child: Text(getLocal(context).featured),
          ),
          PopupMenuItem<MenuOptions>(
            value: MenuOptions.Delete,
            child: Text(getLocal(context).delete_ucf),
          ),
          PopupMenuItem<MenuOptions>(
            value: MenuOptions.Duplicate,
            child: Text(getLocal(context).duplicate),
          ),
        ],
      ),
    );
  }

  void showPublishUnPublishDialog(int? index, id) {
    //print(index.toString()+" "+_productStatus[index].toString());
    showDialog(
        context: context,
        builder: (context) {
          switchContext = context;
          return StatefulBuilder(builder: (context, setState) {
            return SizedBox(
              height: 75,
              width: DeviceInfo(context).getWidth(),
              child: AlertDialog(
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _productList[index!].status
                          ? getLocal(context).published
                          : getLocal(context).unpublished,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: MyTheme.ink),
                    ),
                    Switch(
                      value: _productList[index].status,
                      activeColor: MyTheme.green,
                      inactiveThumbColor: MyTheme.grey_153,
                      onChanged: (value) {
                        productStatusChange(index, value, setState, id);
                      },
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }

  void showFeaturedUnFeaturedDialog(int? index, id) {
    //print(_productFeatured[index]);
    print(index);
    showDialog(
        context: context,
        builder: (context) {
          featuredSwitchContext = context;
          return StatefulBuilder(builder: (context, setState) {
            return SizedBox(
              height: 75,
              width: DeviceInfo(context).getWidth(),
              child: AlertDialog(
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _productList[index!].featured
                          ? getLocal(context).featured
                          : getLocal(context).unfeatured,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: MyTheme.ink),
                    ),
                    Switch(
                      value: _productList[index].featured,
                      activeColor: MyTheme.green,
                      inactiveThumbColor: MyTheme.grey_153,
                      onChanged: (value) {
                        productFeaturedChange(
                            index: index,
                            value: value,
                            setState: setState,
                            id: id);
                      },
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }

  loading() {
    showDialog(
        context: context,
        builder: (context) {
          loadingContext = context;
          return AlertDialog(
              content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(
                width: 10,
              ),
              Text(AppLocalizations.of(context)!.please_wait_ucf),
            ],
          ));
        });
  }

  Widget moreProductLoading() {
    if (!_showMoreProductLoadingContainer) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
            LangText(context: context).getLocal().loading_more_products_ucf,
            style: AppTheme.body(
                size: 14, weight: FontWeight.w500, color: MyTheme.dark_grey)),
      ),
    );
  }
}

/// Small tinted status tag (published / featured).
class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: AppTheme.body(size: 12, weight: FontWeight.w700, color: color)),
    );
  }
}

/// Stands in for a product card while the first page loads.
class _ProductCardPlaceholder extends StatelessWidget {
  const _ProductCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h, [double r = 6]) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
              color: MyTheme.paper, borderRadius: BorderRadius.circular(r)),
        );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MyTheme.radius_card),
        border: Border.all(color: MyTheme.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(72, 72, MyTheme.radius_control),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(160, 16),
                const SizedBox(height: 6),
                bar(90, 12),
                const SizedBox(height: 12),
                bar(110, 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum MenuOptions { Edit, Published, Featured, Delete, Duplicate }
