import 'dart:async';
import 'dart:convert';

import 'package:active_ecommerce_seller_app/custom/device_info.dart';
import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/osm_location_picker.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/repositories/shop_repository.dart';
import 'package:active_ecommerce_seller_app/custom/settings_ui.dart';
import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:one_context/one_context.dart';
import 'package:toast/toast.dart';

class ShopDeliveryBoyPickupPoint extends StatefulWidget {
  const ShopDeliveryBoyPickupPoint({super.key});

  @override
  State<ShopDeliveryBoyPickupPoint> createState() =>
      _ShopDeliveryBoyPickupPointState();
}

class _ShopDeliveryBoyPickupPointState
    extends State<ShopDeliveryBoyPickupPoint> {
  TextEditingController locationSearch = TextEditingController();

  late BuildContext loadingContext;

  String _lat = "";
  String _lang = "";

  bool faceAllData = false;
  LatLng kInitialPosition = LatLng(51.52034098371205, -0.12637399200000668);

  Future<bool> _getAccountInfo() async {
    var response = await ShopRepository().getShopInfo();
    _lat = response.shopInfo!.deliveryPickupLatitude.toString();
    _lang = response.shopInfo!.deliveryPickupLongitude.toString();

    faceAllData = true;
    if ((_lat == "" && _lang == "") || (_lat == null && _lang == null)) {
      setDummyInitialLocation();
    } else {
      setInitialLocation(response.shopInfo!.deliveryPickupLatitude.toString(),
          response.shopInfo!.deliveryPickupLongitude.toString());
    }
    return true;
  }

  setInitialLocation(lat, lng) {
    final la = double.tryParse(lat), ln = double.tryParse(lng);
    if (la == null || ln == null) return setDummyInitialLocation();
    kInitialPosition = LatLng(la, ln);
    setState(() {});
  }

  setDummyInitialLocation() {
    kInitialPosition = LatLng(51.52034098371205, -0.12637399200000668);
    setState(() {});
  }

  faceData() {
    _getAccountInfo();
  }

  changeLatLang(lat, lng) {
    setState(() {
      _lat = lat;
      _lang = lng;
    });

    //kInitialPositionInput.add(LatLng(double.parse(lat), double.parse(lng)));
  }

/*
  updatePickupPoint(selectedPlace) async {

    var  postBody = jsonEncode({
      "delivery_pickup_longitude": selectedPlace.geometry.location.lng.toString(),
      "delivery_pickup_latitude": selectedPlace.geometry.location.lat.toString(),
    });
    var response = await ShopRepository().updateShopSetting(postBody);

    ToastComponent.showDialog(response.message,
        gravity: Toast.center, duration: Toast.lengthLong);


  }*/

  updateInfo() async {
    if (_lat.isEmpty || _lang.isEmpty) {
      ToastComponent.showDialog(
          LangText(context: OneContext().context).getLocal().please_pick_place,
          bgColor: MyTheme.white,
          duration: Toast.lengthLong,
          gravity: Toast.center);
      return;
    }
    var postBody = jsonEncode({
      "delivery_pickup_longitude": _lang,
      "delivery_pickup_latitude": _lat,
    });
    loadingShow(context);
    var response = await ShopRepository().updateShopSetting(postBody);
    Navigator.pop(loadingContext);

    ToastComponent.showDialog(response.message,
        bgColor: MyTheme.white,
        duration: Toast.lengthLong,
        gravity: Toast.center);
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
      appBar: settingsAppBar(context, l.delivery_boy_pickup_point),
      bottomNavigationBar: faceAllData
          ? SettingsSaveBar(label: l.update_location, onPressed: updateInfo)
          : null,
      body: SingleChildScrollView(
        padding: kSettingsBodyPadding,
        child: faceAllData ? buildBodyContainer() : buildLoadingContainer(),
      ),
    );
  }

  Widget _readOnlyValue(String value) {
    return Container(
      height: 48,
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: MyTheme.paper,
        borderRadius: BorderRadius.circular(MyTheme.radius_control),
        border: Border.all(color: MyTheme.hairline, width: 1.5),
      ),
      child: Text(value.isEmpty ? "–" : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.body(size: 16, color: MyTheme.ink)),
    );
  }

  Widget buildBodyContainer() {
    final l = LangText(context: context).getLocal();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(
          title: l.delivery_boy_pickup_point,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(MyTheme.radius_control),
              child: SizedBox(
                height: DeviceInfo(context).getHeight() / 2,
                child: buildMap(),
              ),
            ),
          ],
        ),
        SettingsSection(title: l.your_delivery_location, children: [
          Row(
            children: [
              Expanded(
                child: SettingsField(
                    label: l.latitude_ucf,
                    bottomGap: 0,
                    child: _readOnlyValue(_lat)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SettingsField(
                    label: l.longitude_ucf,
                    bottomGap: 0,
                    child: _readOnlyValue(_lang)),
              ),
            ],
          ),
        ]),
      ],
    );
  }

  Padding buildLoadingContainer() {
    return Padding(
      padding: EdgeInsets.only(top: (DeviceInfo(context).getHeight() / 3)),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

/*
  Widget buildSearchContainer(BuildContext context) {
    return Container(
      child: TypeAheadField(
        suggestionsCallback: (name) async {
          var countryResponse =
              await GoogleMapLocationRepository().getAutoCompleteAddress(name);
          return countryResponse.predictions;
        },
        loadingBuilder: (context) {
          return Container(
            height: 50,
            child: Center(
                child: Text(
                    LangText(context: context).getLocal().common_no_more_Data,
                    style: TextStyle(color: MyTheme.medium_grey))),
          );
        },
        itemBuilder: (context, location) {
          //print(suggestion.toString());
          return ListTile(
            dense: true,
            title: Text(
              location.description,
              style: TextStyle(color: MyTheme.font_grey),
            ),
          );
        },
        noItemsFoundBuilder: (context) {
          return Container(
            height: 50,
            child: Center(
                child: Text(
                    LangText(context: context).getLocal().common_no_more_Data,
                    style: TextStyle(color: MyTheme.medium_grey))),
          );
        },
        onSuggestionSelected: (location) {
         // onSelectCountryDuringAdd(location);
        },
        textFieldConfiguration: TextFieldConfiguration(
          onTap: () {},
          //autofocus: true,
          controller: locationSearch,
          onSubmitted: (txt) {
            // keep this blank
          },
          decoration: InputDecoration(
              hintText:
                  LangText(context: context).getLocal().common_search_address,
              hintStyle:
                  TextStyle(fontSize: 12.0, color: MyTheme.textfield_grey),
              enabledBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: MyTheme.textfield_grey, width: 0.5),
                borderRadius: const BorderRadius.all(
                  const Radius.circular(8.0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: MyTheme.textfield_grey, width: 1.0),
                borderRadius: const BorderRadius.all(
                  const Radius.circular(8.0),
                ),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 8.0)),
        ),
      ),
    );
  }*/

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

  Widget buildMap() {
    return OsmLocationPicker(
      initialPosition: kInitialPosition,
      hintText: LangText(context: context).getLocal().your_delivery_location,
      loadingText: LangText(context: context).getLocal().calculating_ucf,
      actionLabel: LangText(context: context).getLocal().pick_here_ucf,
      onPicked: (position, _) {
        changeLatLang(
            position.latitude.toString(), position.longitude.toString());
      },
    );
  }
}
