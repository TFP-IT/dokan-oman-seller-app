import 'dart:async';
import 'dart:convert';

import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// OpenStreetMap based location picker (replacement for Google PlacePicker).
///
/// The pin stays fixed in the centre of the map; the user drags the map to
/// choose a point, or searches an address (OSM Nominatim). The address of the
/// centre point is reverse-geocoded and shown in a card with an action button.
class OsmLocationPicker extends StatefulWidget {
  const OsmLocationPicker({
    super.key,
    required this.initialPosition,
    required this.actionLabel,
    required this.onPicked,
    this.hintText = "Search",
    this.loadingText = "...",
    this.pinAsset = 'assets/icon/delivery_map_icon.png',
    this.initialZoom = 15,
  });

  final LatLng initialPosition;
  final String actionLabel;
  final String hintText;
  final String loadingText;
  final String pinAsset;
  final double initialZoom;

  /// Called when the action button is pressed.
  final void Function(LatLng position, String? address) onPicked;

  @override
  State<OsmLocationPicker> createState() => _OsmLocationPickerState();
}

class _OsmLocationPickerState extends State<OsmLocationPicker> {
  static const _userAgent = 'com.activeitzone.active_ecommerce_seller_app';
  static const _headers = {'User-Agent': _userAgent};

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late LatLng _center = widget.initialPosition;
  String? _address;
  bool _resolving = false;
  bool _dragging = false;
  Timer? _debounce;
  int _reverseRequestId = 0;

  List<_SearchResult> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() => setState(() {}));
    _reverseGeocode(_center);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveStart || event is MapEventFlingAnimationStart) {
      if (!_dragging) setState(() => _dragging = true);
    }
    if (event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventFlingAnimationNotStarted) {
      _center = event.camera.center;
      setState(() => _dragging = false);
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500),
          () => _reverseGeocode(_center));
    }
  }

  Future<void> _reverseGeocode(LatLng p) async {
    final requestId = ++_reverseRequestId;
    setState(() => _resolving = true);
    String? address;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': p.latitude.toString(),
        'lon': p.longitude.toString(),
      });
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        address = jsonDecode(res.body)['display_name'] as String?;
      }
    } catch (_) {
      // Network failure: fall back to coordinates below.
    }
    if (!mounted || requestId != _reverseRequestId) return;
    setState(() {
      _resolving = false;
      _address = address ??
          '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
    });
  }

  Future<void> _search(String query) async {
    query = query.trim();
    if (query.isEmpty) return;
    setState(() => _searching = true);
    List<_SearchResult> results = [];
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'q': query,
        'limit': '8',
      });
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        results = (jsonDecode(res.body) as List)
            .map((e) => _SearchResult(
                  e['display_name'] as String,
                  LatLng(double.parse(e['lat'].toString()),
                      double.parse(e['lon'].toString())),
                ))
            .toList();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = results;
    });
  }

  void _selectResult(_SearchResult r) {
    _searchFocus.unfocus();
    setState(() {
      _results = [];
      _center = r.position;
      _address = r.name;
    });
    _mapController.move(r.position, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.initialPosition,
            initialZoom: widget.initialZoom,
            onMapEvent: _onMapEvent,
            onTap: (_, __) => _searchFocus.unfocus(),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: _userAgent,
            ),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),
        // Centre pin (bottom of the icon points at the map centre).
        IgnorePointer(
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: _dragging ? 80 : 60),
              child: Image.asset(widget.pinAsset, height: _dragging ? 80 : 60),
            ),
          ),
        ),
        Positioned(top: 8, left: 8, right: 8, child: _buildSearch()),
        if (!_searchFocus.hasFocus)
          Positioned(left: 8, right: 8, bottom: 24, child: _buildCard()),
      ],
    );
  }

  Widget _buildSearch() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : (_searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _results = []);
                          },
                        )
                      : null),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_searchFocus.hasFocus && _results.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(_results[i].name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: MyTheme.font_grey)),
                  onTap: () => _selectResult(_results[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    final busy = _dragging || _resolving;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                busy ? widget.loadingText : (_address ?? ''),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: MyTheme.medium_grey),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyTheme.app_accent_color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: busy && _dragging
                  ? null
                  : () => widget.onPicked(_center, _address),
              child: Text(widget.actionLabel,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResult {
  _SearchResult(this.name, this.position);
  final String name;
  final LatLng position;
}
