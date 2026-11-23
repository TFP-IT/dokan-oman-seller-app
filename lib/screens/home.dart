import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/const/app_style.dart';
import 'package:active_ecommerce_seller_app/const/homepage_features.dart';
import 'package:active_ecommerce_seller_app/custom/device_info.dart';
import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/my_widget.dart';
import 'package:active_ecommerce_seller_app/custom/route_transaction.dart';
import 'package:active_ecommerce_seller_app/data_model/category_wise_product_response.dart';
import 'package:active_ecommerce_seller_app/data_model/top_12_product_response.dart';
import 'package:active_ecommerce_seller_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_seller_app/helpers/shimmer_helper.dart';
import 'package:active_ecommerce_seller_app/helpers/shop_info_helper.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/shop_repository.dart';
import 'package:active_ecommerce_seller_app/screens/payment_setting.dart';
import 'package:active_ecommerce_seller_app/screens/shop_settings/shop_settings.dart';
import 'package:active_ecommerce_seller_app/screens/verify_page.dart';
import 'package:flutter/material.dart';

import '../custom/chart2.dart';

class Home extends StatefulWidget {
  final bool fromBottombar;

  /// Switches the bottom-bar tab in Main (1 = products, 2 = orders).
  final ValueChanged<int>? onOpenTab;

  const Home({super.key, this.fromBottombar = false, this.onOpenTab});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  //String variables
  // String homePageTitle = "Dashboard";

  //bool type
  bool _faceTopProducts = false;
  bool _faceCategoryWiseProducts = false;

  // double variables
  double mHeight = 0.0, mWidht = 0.0;

  //List
  List<ChartData> chartValues = [];
  List<ProductOfTop> product = [];
  List<String> logoSliders = [];
  List<CategoryWiseProductResponse> categoryWiseProducts = [];

  String? _productsCount = '...',
      _rattingCount = "...",
      _totalOrdersCount = "...",
      _totalSalesCount = '...',
      _soldOutProducts = "...",
      _lowStockProducts = "...";

  // Future<bool> _getTop12Product() async {
  //   var response = await ShopRepository().getTop12ProductRequest();
  //   product.addAll(response.data!);
  //   _faceTopProducts = true;
  //   setState(() {});

  //   return true;
  // }
  Future<bool> _getTop12Product() async {
    try {
      var response = await ShopRepository().getTop12ProductRequest();

      if (response.data != null) {
        product.addAll(response.data!);
        _faceTopProducts = true;
        setState(() {});
        return true;
      } else {
        // Handle case when response.data is null
        debugPrint('No data found in response.');
        return false;
      }
    } catch (e) {
      // Handle other exceptions (like network errors)
      debugPrint('Error fetching top products: $e');
      return false;
    }
  }

  Future<bool> _getCategoryWiseProduct() async {
    var response = await ShopRepository().getCategoryWiseProductRequest();
    categoryWiseProducts.addAll(response);
    _faceCategoryWiseProducts = true;
    setState(() {});
    return true;
  }

  Future<bool> _getShopInfo() async {
    var response = await ShopRepository().getShopInfo();

    _productsCount = response.shopInfo!.products.toString();
    _rattingCount = response.shopInfo!.rating.toString();
    _totalOrdersCount = response.shopInfo!.orders.toString();
    _totalSalesCount = response.shopInfo!.sales.toString();
    logoSliders.addAll(response.shopInfo!.sliders!);

    ShopInfoHelper().setShopInfo();
    setState(() {});
    return true;
  }

  cleanAll() {
    _productsCount = '...';
    _rattingCount = "...";
    _totalOrdersCount = "...";
    _totalSalesCount = '...';
    _soldOutProducts = "...";
    _lowStockProducts = "...";
    chartValues = [];
    product = [];
    categoryWiseProducts = [];
    _faceTopProducts = false;
    _faceCategoryWiseProducts = false;
    setState(() {});
  }

  Future<void> reFresh() {
    cleanAll();
    facingAll();
    return Future.delayed(Duration(seconds: 1));
  }

  facingAll() async {
    _getTop12Product();
    _getCategoryWiseProduct();
    _getShopInfo();
  }

  @override
  void initState() {
    // TODO: implement initState
    facingAll();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    mHeight = MediaQuery.of(context).size.height;
    mWidht = MediaQuery.of(context).size.width;
    return RefreshIndicator(
      color: MyTheme.navy,
      backgroundColor: Colors.white,
      onRefresh: reFresh,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: dashboard(),
          ),
        ],
      ),
    );
  }

  Widget buildTopProductsShimmer() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MyTheme.radius_card),
            child: ShimmerHelper().buildBasicShimmer(
                height: 92.0, width: DeviceInfo(context).getWidth()),
          ),
        ),
      ),
    );
  }

  // Container topProductsContainer() {
  //   return Container(
  //       padding: EdgeInsets.symmetric(horizontal: AppStyles.layoutMargin),
  //       alignment: Alignment.topLeft,
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         mainAxisAlignment: MainAxisAlignment.start,
  //         children: [
  //           Container(
  //             height: 17,
  //             child: Text(
  //               LangText(context: context).getLocal()!.top_products_ucf,
  //               style: TextStyle(
  //                   fontSize: 14,
  //                   color: MyTheme.app_accent_color,
  //                   fontWeight: FontWeight.bold),
  //             ),
  //           ),
  //           SizedBox(
  //             height: AppStyles.itemMargin,
  //           ),
  //           _faceTopProducts
  //               ? product.length == 0
  //                   ? Container(
  //                       alignment: Alignment.center,
  //                       height: 205,
  //                       padding: const EdgeInsets.only(left: 15.0),
  //                       child: Text(
  //                         LangText(context: context)
  //                             .getLocal()!
  //                             .no_data_is_available,
  //                         style: TextStyle(
  //                             fontSize: 14,
  //                             color: MyTheme.app_accent_color,
  //                             fontWeight: FontWeight.bold),
  //                       ),
  //                     )
  //                   : ListView.builder(
  //                       physics: const NeverScrollableScrollPhysics(),
  //                       shrinkWrap: true,
  //                       itemCount: product.length,
  //                       itemBuilder: (context, index) {
  //                         return buildTopProductItem(index);
  //                       },
  //                     )
  //               : buildTopProductsShimmer(),
  //         ],
  //       ));
  // }

  Container topProductsContainer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppStyles.layoutMargin),
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Main content
          _faceTopProducts
              ? product.isEmpty
                  ? Container(
                      alignment: Alignment.center,
                      height: 205,
                      padding: const EdgeInsets.only(left: 15.0),
                      child: Text(
                        LangText(context: context)
                            .getLocal()
                            .no_data_is_available,
                        style: AppTheme.body(size: 14, color: MyTheme.dark_grey),
                      ),
                    )
                  : ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: product.length,
                      itemBuilder: (context, index) {
                        return buildTopProductItem(index);
                      },
                    )
              : buildTopProductsShimmer(),
        ],
      ),
    );
  }

  Widget buildTopProductItem(int index) {
    final p = product[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: _surface,
      child: Row(
        children: [
          MyWidget.imageWithPlaceholder(
            url: p.thumbnailImg,
            width: 72.0,
            height: 72.0,
            radius: BorderRadius.circular(MyTheme.radius_control),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(
                        size: 14, weight: FontWeight.w600, color: MyTheme.ink)),
                const SizedBox(height: 2),
                Text(p.category ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(size: 12, color: MyTheme.grey_153)),
                const SizedBox(height: 6),
                Text(p.price ?? "",
                    style: AppTheme.display(
                        size: 15, weight: FontWeight.w600, color: MyTheme.navy)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCategoriesShimmer() {
    return SizedBox(
      height: 112,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return ShimmerHelper()
                .buildBasicShimmer(height: 112.0, width: 89.0);
          }),
    );
  }

  Widget categoryWiseProductShimmer() {
    return Column(
      children: [
        ShimmerHelper().buildBasicShimmer(height: 20),
        SizedBox(
          height: 5,
        ),
        ShimmerHelper().buildBasicShimmer(height: 20),
        SizedBox(
          height: 5,
        ),
        ShimmerHelper().buildBasicShimmer(height: 20),
        SizedBox(
          height: 5,
        ),
        ShimmerHelper().buildBasicShimmer(height: 20),
      ],
    );
  }

  Container categoryWiseProduct() {
    return MyWidget.customContainer(
        alignment: Alignment.topLeft,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _faceCategoryWiseProducts
                ? categoryWiseProducts.isEmpty
                    ? Container(
                        alignment: Alignment.center,
                        height: 112,
                        padding: const EdgeInsets.only(left: 15.0),
                        child: Text(
                          LangText(context: context)
                              .getLocal()
                              .no_data_is_available,
                          style: AppTheme.body(size: 14, color: MyTheme.dark_grey),
                        ),
                      )
                    : SizedBox(
                        height: 112,
                        child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                                horizontal: AppStyles.itemMargin),
                            separatorBuilder: (context, index) {
                              return SizedBox(
                                width: AppStyles.itemMargin,
                              );
                            },
                            scrollDirection: Axis.horizontal,
                            itemCount: categoryWiseProducts.length,
                            itemBuilder: (context, index) {
                              return buildCategoryItem(index);
                            }),
                      )
                : buildCategoriesShimmer(),
          ],
        ));
  }

  Widget buildCategoryItem(int index) {
    return MyWidget.customCardView(
        backgroundColor: MyTheme.noColor,
        elevation: 0,
        blurSize: 20,
        height: 112,
        width: 89,
        // borderRadius: 12.0,
        shadowColor: MyTheme.app_accent_shado,
        child: Container(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                child: MyWidget.imageWithPlaceholder(
                  url: categoryWiseProducts[index].banner,
                  width: 89.0,
                  height: 112.0,
                  fit: BoxFit.cover,
                  backgroundColor: MyTheme.noColor,
                  radius: BorderRadius.circular(MyTheme.radius_control),
                ),
              ),
              Container(
                height: 112,
                width: 89,
                decoration: BoxDecoration(
                    color: MyTheme.app_accent_tranparent,
                    borderRadius:
                        BorderRadius.circular(MyTheme.radius_control)),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        categoryWiseProducts[index].name!,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        style: AppTheme.body(
                            size: 12,
                            weight: FontWeight.w600,
                            color: MyTheme.white,
                            height: 1.2),
                        overflow: TextOverflow.fade,
                      ),
                    ),
                    Text(
                      "(${categoryWiseProducts[index].cntProduct})",
                      style: AppTheme.body(
                          size: 11, color: MyTheme.white.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  Widget dashboard() {
    final needsVerify = !verify_form_submitted.$ && !shop_verify.$;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        top4Boxes(),
        if (logoSliders.isNotEmpty) ...[
          const SizedBox(height: 16),
          bannerContainer(),
        ],
        if (needsVerify) ...[
          const SizedBox(height: 16),
          verifyContainer(),
        ],
        _sectionTitle("Shortcuts"),
        featureContainer(),
        _sectionTitle("Settings"),
        settingContainer(),
        _sectionTitle(LangText(context: context).getLocal().sales_stat_ucf),
        chartContainer(),
        _sectionTitle(
            "${LangText(context: context).getLocal().your_categories_ucf} (${categoryWiseProducts.length})"),
        categoryWiseProduct(),
        _sectionTitle(LangText(context: context).getLocal().top_products_ucf),
        topProductsContainer(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(text,
          style: AppTheme.body(
              size: 18, weight: FontWeight.w600, color: MyTheme.navy)),
    );
  }

  BoxDecoration get _surface => BoxDecoration(
        color: MyTheme.white,
        borderRadius: BorderRadius.circular(MyTheme.radius_card),
        border: Border.all(color: MyTheme.hairline),
      );

  EdgeInsets get _gutter => const EdgeInsets.symmetric(horizontal: 16);

  // ---------------------------------------------------------------------------
  // Header: flat navy hero, same layout as the delivery app dashboard
  // ---------------------------------------------------------------------------

  /// A number that shows a faded dash while it is loading.
  Widget _figure(String? value, TextStyle style) {
    final loaded = value != null && value != "..." && value.isNotEmpty;
    final color = style.color ?? MyTheme.navy;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        loaded ? value : "–",
        maxLines: 1,
        style: style.copyWith(
            color: loaded ? color : color.withValues(alpha: 0.35)),
      ),
    );
  }

  Widget top4Boxes() {
    final l = LangText(context: context).getLocal();
    final name = shop_name.$;

    Widget stat(String label, String? value, VoidCallback? onTap) => Expanded(
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white24,
            borderRadius: BorderRadius.circular(MyTheme.radius_control),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _figure(value, AppTheme.figure(32, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(
                          size: 14,
                          weight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
          ),
        );

    return Container(
      color: MyTheme.navy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: widget.onOpenTab == null ? null : () => widget.onOpenTab!(2),
            splashColor: Colors.white24,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (name.isNotEmpty) ...[
                          Text("Hello, $name",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body(
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.65))),
                          const SizedBox(height: 8),
                        ],
                        Text(l.total_sales_ucf,
                            style: AppTheme.body(
                                size: 16,
                                weight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.8))),
                        _figure(_totalSalesCount,
                            AppTheme.figure(72, color: Colors.white)),
                      ],
                    ),
                  ),
                  if (widget.onOpenTab != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 12),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: MyTheme.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: MyTheme.navy),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                stat(l.total_orders_ucf, _totalOrdersCount,
                    widget.onOpenTab == null ? null : () => widget.onOpenTab!(2)),
                stat(l.products_ucf, _productsCount,
                    widget.onOpenTab == null ? null : () => widget.onOpenTab!(1)),
                stat(l.rating_ucf, _rattingCount, null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget bannerContainer() {
    return Padding(
      padding: _gutter,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MyTheme.radius_card),
        child: AspectRatio(
          aspectRatio: 16 / 7,
          child: MyWidget.imageSlider(imageUrl: logoSliders, context: context),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Attention: account verification (amber = needs action)
  // ---------------------------------------------------------------------------

  Widget verifyContainer() {
    final l = LangText(context: context).getLocal();
    return Container(
      margin: _gutter,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyTheme.amber_soft,
        borderRadius: BorderRadius.circular(MyTheme.radius_card),
        border: Border.all(color: MyTheme.amber.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: MyTheme.amber, shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_outlined,
                color: MyTheme.ink, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.your_account_is_unverified,
                    style: AppTheme.body(
                        size: 15, weight: FontWeight.w700, color: MyTheme.ink)),
                const SizedBox(height: 2),
                Text("Verify your shop to start receiving payouts.",
                    style: AppTheme.body(size: 13, color: MyTheme.amber_ink)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: MyTheme.amber,
              foregroundColor: MyTheme.ink,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: () {
              MyTransaction(context: context)
                  .push(const VerifyPage())
                  .then((value) {
                if (!verify_form_submitted.$) {
                  setState(() {});
                }
              });
            },
            child: Text(l.verify_now),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shortcuts & settings
  // ---------------------------------------------------------------------------

  Widget featureContainer() {
    final items = FeaturesList(context).getFeatureList();
    return Container(
      margin: _gutter,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: _surface,
      // Four shortcuts per row. Wrap (not a fixed-ratio grid) so each row is
      // only as tall as its tiles and there is no empty space under them.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = constraints.maxWidth / 4;
          return Wrap(
            runSpacing: 4,
            children: [
              for (final item in items)
                SizedBox(width: tileWidth, child: item),
            ],
          );
        },
      ),
    );
  }

  Widget settingContainer() {
    final l = LangText(context: context).getLocal();
    Widget row(String icon, String title, String sub, VoidCallback onTap) =>
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
            child: Row(
              children: [
                Image.asset(icon, color: MyTheme.navy, height: 24, width: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTheme.body(
                              size: 16,
                              weight: FontWeight.w500,
                              color: MyTheme.ink)),
                      Text(sub.replaceAll("\n", " "),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              AppTheme.body(size: 13, color: MyTheme.dark_grey)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: MyTheme.dark_grey),
              ],
            ),
          ),
        );

    return Container(
      margin: _gutter,
      decoration: _surface,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          row("assets/icon/shop_setting.png", l.shop_settings_ucf,
              l.manage_n_organize_your_shop,
              () => MyTransaction(context: context).push(ShopSettings())),
          const Divider(indent: 16, endIndent: 16),
          row("assets/icon/payment_setting.png", l.payment_settings_ucf,
              l.configure_your_payment_method,
              () => MyTransaction(context: context).push(PaymentSetting())),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sales chart
  // ---------------------------------------------------------------------------

  Widget chartShimmer() {
    return SizedBox(
      height: 130,
      width: DeviceInfo(context).getWidth() / 1.5,
      child:
          ShimmerHelper().buildListShimmer(item_height: 20.0, item_count: 10),
    );
  }

  Widget chartContainer() {
    return Container(
      margin: _gutter,
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
      height: 220,
      decoration: _surface,
      child: const MChart(),
    );
  }
}

class ChartData {
  int salesValue;
  String date;

  ChartData(this.date, this.salesValue);
}
