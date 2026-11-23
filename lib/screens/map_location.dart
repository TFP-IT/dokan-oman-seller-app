import 'dart:convert';

import 'package:active_ecommerce_seller_app/custom/osm_location_picker.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/l10n/app_localizations.dart';
import 'package:active_ecommerce_seller_app/repositories/shop_repository.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:toast/toast.dart';

class MapLocation extends StatefulWidget {
  MapLocation({super.key, this.lng, this.lat});
  var lat, lng;

  @override
  State<MapLocation> createState() => MapLocationState();
}

class MapLocationState extends State<MapLocation> {
  static const LatLng _defaultPosition =
      LatLng(51.52034098371205, -0.12637399200000668); // London, arbitrary

  late final LatLng kInitialPosition = _parseInitial();

  LatLng _parseInitial() {
    final lat = double.tryParse(widget.lat?.toString() ?? '');
    final lng = double.tryParse(widget.lng?.toString() ?? '');
    return (lat != null && lng != null) ? LatLng(lat, lng) : _defaultPosition;
  }

  Future<void> onTapPickHere(LatLng position) async {
    var postBody = jsonEncode({
      "delivery_pickup_longitude": position.longitude.toString(),
      "delivery_pickup_latitude": position.latitude.toString(),
    });
    var response = await ShopRepository().updateShopSetting(postBody);

    ToastComponent.showDialog(response.message,
        gravity: Toast.center, duration: Toast.lengthLong);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: OsmLocationPicker(
          initialPosition: kInitialPosition,
          hintText: l10n.your_delivery_location,
          loadingText: l10n.calculating,
          actionLabel: l10n.update_location,
          onPicked: (position, _) => onTapPickHere(position),
        ),
      ),
    );
  }
}
