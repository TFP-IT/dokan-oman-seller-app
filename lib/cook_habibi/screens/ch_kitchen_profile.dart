import 'dart:io';

import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_api.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_models.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_repository.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kitchen profile view + edit and working hours (guide §5).
class ChKitchenProfile extends StatefulWidget {
  const ChKitchenProfile({super.key});

  @override
  State<ChKitchenProfile> createState() => _ChKitchenProfileState();
}

class _ChKitchenProfileState extends State<ChKitchenProfile> {
  final _repo = ChRepository();
  final _form = GlobalKey<FormState>();
  ChProfile? _profile;
  Object? _error;
  bool _saving = false;
  Map<String, List<String>> _errors = {};

  // text fields: api key -> controller
  final Map<String, TextEditingController> _text = {
    for (final k in [
      "kitchen_name",
      "cook_name",
      "emoji",
      "cuisine_key",
      "area",
      "lat",
      "lng",
      "delivery_radius_km",
      "delivery_fee",
      "delivery_time_text",
      "offer_text",
      "offer_percent",
      "offer_min_order",
      "bio",
      "languages",
      "cooking_since",
    ])
      k: TextEditingController()
  };

  static const _numeric = {
    "lat",
    "lng",
    "delivery_radius_km",
    "delivery_fee",
    "offer_percent",
    "offer_min_order",
  };

  static const _flags = {
    "pickup_enabled": "Pickup",
    "delivery_enabled": "Delivery",
    "supports_pre_order": "Pre-orders",
    "supports_subscription": "Subscriptions",
    "supports_catering": "Catering",
    "has_family_meals": "Family meals",
  };
  final Map<String, bool> _flagValues = {};

  String? _coverPath, _ownerPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _repo.profile();
      _fill(p);
      if (mounted) setState(() {
        _profile = p;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _fill(ChProfile p) {
    _text.forEach((k, c) {
      final v = p.raw[k];
      if (k == "languages") {
        c.text = chStrList(v).join(", ");
      } else {
        c.text = v == null ? "" : v.toString();
      }
    });
    for (final k in _flags.keys) {
      _flagValues[k] = chBool(p.raw[k]);
    }
  }

  dynamic _valueOf(String k) {
    final t = _text[k]!.text.trim();
    if (k == "languages") {
      return t.split(",").map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    if (_numeric.contains(k)) return t.isEmpty ? null : double.tryParse(t);
    if (k == "cooking_since") return t.isEmpty ? null : int.tryParse(t) ?? t;
    return t;
  }

  dynamic _originalOf(String k) {
    final v = _profile!.raw[k];
    if (k == "languages") return chStrList(v);
    if (_numeric.contains(k)) return chDouble(v);
    if (k == "cooking_since") return v == null ? null : (chInt(v) ?? v.toString());
    return v?.toString() ?? "";
  }

  bool _same(dynamic a, dynamic b) {
    if (a is List && b is List) return a.join("|") == b.join("|");
    return a == b;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errors = {};
    });
    try {
      final changes = <String, dynamic>{};
      for (final k in _text.keys) {
        final v = _valueOf(k);
        if (!_same(v, _originalOf(k))) changes[k] = v;
      }
      // lat and lng go together
      if (changes.containsKey("lat") || changes.containsKey("lng")) {
        changes["lat"] = _valueOf("lat");
        changes["lng"] = _valueOf("lng");
      }
      _flagValues.forEach((k, v) {
        if (v != chBool(_profile!.raw[k])) changes[k] = v;
      });
      if (_coverPath != null) {
        changes["cover_image"] = await _repo.upload(_coverPath!);
      }
      if (_ownerPath != null) {
        changes["owner_image"] = await _repo.upload(_ownerPath!);
      }
      if (changes.isEmpty) {
        chToast("Nothing changed.");
        return;
      }
      final p = await _repo.updateProfile(changes);
      _coverPath = null;
      _ownerPath = null;
      _fill(p);
      setState(() => _profile = p);
      chToast("Profile saved.");
    } on ChApiException catch (e) {
      setState(() => _errors = e.errors);
      chToast(e.message);
    } catch (e) {
      chToastError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    final locked = p?.isSuspended ?? false;
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: chAppBar(context, "Kitchen profile", actions: [
        if (p != null)
          TextButton.icon(
            icon: const Icon(Icons.schedule),
            label: const Text("Hours"),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ChScheduleScreen(profile: p, locked: locked)));
              _load();
            },
          ),
      ]),
      body: p == null
          ? (_error != null
              ? ChErrorView(message: chErrorText(_error!), onRetry: _load)
              : const Center(child: CircularProgressIndicator()))
          : AbsorbPointer(
              absorbing: locked,
              child: Form(
                key: _form,
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  if (locked)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFBE7E4),
                          borderRadius:
                              BorderRadius.circular(MyTheme.radius_control)),
                      child: Text("Your kitchen is suspended. Editing is off.",
                          style: AppTheme.body(size: 13, color: MyTheme.red)),
                    ),
                  _readOnly(p),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: _imagePick("Cover photo", p.coverUrl, _coverPath,
                            (v) => setState(() => _coverPath = v))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _imagePick("Your photo", p.ownerUrl, _ownerPath,
                            (v) => setState(() => _ownerPath = v))),
                  ]),
                  const SizedBox(height: 16),
                  _section("Kitchen"),
                  _field("kitchen_name", "Kitchen name", required: true),
                  _field("cook_name", "Cook name"),
                  Row(children: [
                    Expanded(child: _field("emoji", "Emoji")),
                    const SizedBox(width: 12),
                    Expanded(child: _field("cuisine_key", "Cuisine")),
                  ]),
                  _field("bio", "About", lines: 3),
                  _field("languages", "Languages", hint: "Arabic, English"),
                  _field("cooking_since", "Cooking since (year)",
                      number: true),
                  _section("Location and delivery"),
                  _field("area", "Area"),
                  Row(children: [
                    Expanded(child: _field("lat", "Latitude", number: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field("lng", "Longitude", number: true)),
                  ]),
                  Row(children: [
                    Expanded(
                        child: _field("delivery_radius_km", "Radius km (0–50)",
                            number: true, max: 50)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field("delivery_fee", "Delivery fee (0–99)",
                            number: true, max: 99)),
                  ]),
                  _field("delivery_time_text", "Delivery time",
                      hint: "e.g. 30–45 min"),
                  _section("Services"),
                  ..._flags.entries.map((f) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(f.value),
                        value: _flagValues[f.key] ?? false,
                        onChanged: (v) =>
                            setState(() => _flagValues[f.key] = v),
                      )),
                  _section("Offer"),
                  _field("offer_text", "Offer text"),
                  Row(children: [
                    Expanded(
                        child: _field("offer_percent", "Offer %",
                            number: true, max: 100)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field("offer_min_order", "Min order",
                            number: true)),
                  ]),
                  const SizedBox(height: 16),
                  if (!locked)
                    ChButton(label: "Save", busy: _saving, onPressed: _save),
                ]),
              ),
            ),
    );
  }

  Widget _readOnly(ChProfile p) => ChCard(
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          ChPill("Status: ${p.status.isEmpty ? "–" : p.status}"),
          if (p.raw["verification_status"] != null)
            ChPill("Verification: ${p.raw["verification_status"]}"),
          if (chBool(p.raw["is_premium"]) || chBool(p.raw["premium"]))
            const ChPill("Premium",
                bg: MyTheme.amber_soft, fg: MyTheme.amber_ink),
          if (p.rating != null)
            ChPill("Rating ${p.rating!.toStringAsFixed(1)} ★"),
        ]),
      );

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(t,
            style: AppTheme.body(
                size: 15, weight: FontWeight.w600, color: MyTheme.ink)),
      );

  Widget _field(String key, String label,
      {bool required = false,
      bool number = false,
      int lines = 1,
      String? hint,
      double? max}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _text[key],
        maxLines: lines,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : null,
        inputFormatters: number
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]'))]
            : null,
        decoration: chInput(label, hint: hint, error: _errors[key]?.first),
        validator: (v) {
          final t = (v ?? "").trim();
          if (required && t.isEmpty) return "$label is required";
          if (number && t.isNotEmpty) {
            final n = double.tryParse(t);
            if (n == null) return "Enter a number";
            if (max != null && (n < 0 || n > max)) {
              return "0 to ${max.toStringAsFixed(0)}";
            }
          }
          if (key == "lat" || key == "lng") {
            final other = _text[key == "lat" ? "lng" : "lat"]!.text.trim();
            if (t.isEmpty != other.isEmpty) return "Send both or neither";
          }
          return null;
        },
      ),
    );
  }

  Widget _imagePick(String label, String? url, String? local,
      ValueChanged<String> onPicked) {
    return InkWell(
      onTap: () async {
        final p = await chPickImage(context);
        if (p != null) onPicked(p);
      },
      child: Column(children: [
        AspectRatio(
          aspectRatio: 1.6,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: MyTheme.hairline),
                borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: local != null
                ? Image.file(File(local), fit: BoxFit.cover)
                : (url != null
                    ? Image.network(url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_outlined))
                    : const Icon(Icons.add_a_photo_outlined,
                        color: MyTheme.navy)),
          ),
        ),
        const SizedBox(height: 4),
        Text(local != null ? "$label (new)" : label,
            style: AppTheme.body(size: 12, color: MyTheme.medium_grey)),
      ]),
    );
  }
}

/// Working hours editor: `{"working_hours": {"mon": ["10:00","22:00"]}}`.
class ChScheduleScreen extends StatefulWidget {
  final ChProfile profile;
  final bool locked;

  const ChScheduleScreen(
      {super.key, required this.profile, this.locked = false});

  @override
  State<ChScheduleScreen> createState() => _ChScheduleScreenState();
}

class _ChScheduleScreenState extends State<ChScheduleScreen> {
  static const _days = {
    "sat": "Saturday",
    "sun": "Sunday",
    "mon": "Monday",
    "tue": "Tuesday",
    "wed": "Wednesday",
    "thu": "Thursday",
    "fri": "Friday",
  };

  final _repo = ChRepository();
  late final Map<String, List<String>?> _hours;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final w = widget.profile.workingHours;
    _hours = {for (final d in _days.keys) d: w[d]};
  }

  Future<void> _pick(String day, int index) async {
    final cur = _hours[day] ?? ["10:00", "22:00"];
    final parts = cur[index].split(":");
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 10,
          minute: int.tryParse(parts.length > 1 ? parts[1] : "0") ?? 0),
    );
    if (t == null) return;
    final s =
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
    setState(() {
      final list = List<String>.from(cur);
      list[index] = s;
      _hours[day] = list;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      chToast(await _repo.updateSchedule(_hours));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      chToastError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: chAppBar(context, "Working hours"),
      body: AbsorbPointer(
        absorbing: widget.locked,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          ..._days.entries.map((d) {
            final h = _hours[d.key];
            final open = h != null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(children: [
                  SizedBox(
                      width: 96,
                      child: Text(d.value,
                          style: AppTheme.body(
                              size: 14,
                              weight: FontWeight.w600,
                              color: MyTheme.ink))),
                  Expanded(
                    child: open
                        ? Row(children: [
                            TextButton(
                                onPressed: () => _pick(d.key, 0),
                                child: Text(h[0])),
                            const Text("–"),
                            TextButton(
                                onPressed: () => _pick(d.key, 1),
                                child: Text(h[1])),
                          ])
                        : Text("Closed",
                            style: AppTheme.body(
                                size: 14, color: MyTheme.medium_grey)),
                  ),
                  Switch(
                    value: open,
                    onChanged: (v) => setState(
                        () => _hours[d.key] = v ? ["10:00", "22:00"] : null),
                  ),
                ]),
              ),
            );
          }),
          const SizedBox(height: 16),
          if (!widget.locked)
            ChButton(label: "Save hours", busy: _saving, onPressed: _save),
        ]),
      ),
    );
  }
}
