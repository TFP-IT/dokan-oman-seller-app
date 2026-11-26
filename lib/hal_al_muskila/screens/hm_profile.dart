import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Partial-diff Specialist Profile Editor + Bargain Floor (`ChKitchenProfile` pattern).
class HmProfileScreen extends StatefulWidget {
  final bool showBack;

  const HmProfileScreen({super.key, this.showBack = true});

  @override
  State<HmProfileScreen> createState() => _HmProfileScreenState();
}

class _HmProfileScreenState extends State<HmProfileScreen> {
  final _repo = HmRepository();
  HmProfile? _profile;
  HmMeta? _meta;
  Object? _error;
  bool _saving = false;
  Map<String, List<String>> _errors = {};

  final _name = TextEditingController();
  final _title = TextEditingController();
  final _visit = TextEditingController();
  final _hourly = TextEditingController();
  final _exp = TextEditingController();
  final _bio = TextEditingController();
  final _skills = TextEditingController();
  final _minBargain = TextEditingController();

  String _categoryId = "";
  bool _allowCustomBargain = true;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Future.wait([
        _repo.profile(),
        _repo.meta().then<HmMeta?>((m) => m).catchError((_) => null),
      ]);
      final p = res[0] as HmProfile;
      final m = res[1] as HmMeta?;
      _name.text = p.name;
      _title.text = p.professionTitle;
      _visit.text = p.visitPrice.toStringAsFixed(3);
      _hourly.text = p.hourlyRate.toStringAsFixed(3);
      _exp.text = p.experienceYears.toString();
      _bio.text = p.bio;
      _skills.text = p.skills.join(", ");
      _minBargain.text = p.minCustomPrice.toStringAsFixed(3);
      _categoryId = p.categoryId;
      _allowCustomBargain = p.allowCustomBargain;
      if (mounted) {
        setState(() {
          _profile = p;
          _meta = m;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _save() async {
    final p = _profile;
    if (p == null) return;
    setState(() {
      _saving = true;
      _errors = {};
    });
    try {
      final changes = <String, dynamic>{};
      if (_avatarPath != null) {
        changes["avatar_upload_id"] =
            (await _repo.upload(_avatarPath!, type: "avatar")).uploadId;
      }
      if (_name.text.trim() != p.name) changes["name"] = _name.text.trim();
      if (_title.text.trim() != p.professionTitle) {
        changes["profession_title"] = _title.text.trim();
      }
      if (_categoryId != p.categoryId) changes["category_id"] = _categoryId;
      final v = double.tryParse(_visit.text.trim());
      if (v != null && v != p.visitPrice) changes["visit_price"] = v;
      final h = double.tryParse(_hourly.text.trim());
      if (h != null && h != p.hourlyRate) changes["hourly_rate"] = h;
      final exp = int.tryParse(_exp.text.trim());
      if (exp != null && exp != p.experienceYears) {
        changes["experience_years"] = exp;
      }
      if (_bio.text.trim() != p.bio) changes["bio"] = _bio.text.trim();
      final sk = _skills.text
          .split(",")
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (sk.join(",") != p.skills.join(",")) changes["skills"] = sk;
      if (_allowCustomBargain != p.allowCustomBargain) {
        changes["allow_custom_bargain"] = _allowCustomBargain;
      }
      final mb = double.tryParse(_minBargain.text.trim());
      if (mb != null && mb != p.minCustomPrice) {
        changes["min_custom_price"] = mb;
      }

      if (changes.isEmpty) {
        hmToast("Nothing changed.");
        setState(() => _saving = false);
        return;
      }

      final updated = await _repo.updateProfile(changes);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _avatarPath = null;
        _saving = false;
      });
      hmToast("Profile updated.");
    } on HmApiException catch (e) {
      if (mounted) {
        setState(() {
          _errors = e.errors;
          _saving = false;
        });
      }
      hmToast(e.message);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      hmToastError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    final cats = _meta?.categories ?? const [];
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: hmAppBar(
        context,
        "Specialist Profile",
        showBack: widget.showBack,
      ),
      body: p == null
          ? (_error != null
              ? HmErrorView(message: hmErrorText(_error!), onRetry: _load)
              : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              color: MyTheme.navy,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  HmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            HmNetImage(url: p.photo, size: 60),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: AppTheme.display(size: 18)),
                                  Text(
                                    "${p.rating.toStringAsFixed(1)} ★ · ${p.jobsCompleted} jobs",
                                    style: AppTheme.body(
                                        size: 13, color: MyTheme.medium_grey),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                final img = await hmPickImage(context);
                                if (img != null) {
                                  setState(() => _avatarPath = img);
                                }
                              },
                              child: Text(_avatarPath == null
                                  ? "Photo"
                                  : "Selected"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  HmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _name,
                          decoration: hmInput("Name",
                              error: _errors["name"]?.firstOrNull),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _title,
                          decoration: hmInput("Profession title",
                              error: _errors["profession_title"]?.firstOrNull),
                        ),
                        if (cats.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: cats.any((c) => c.id == _categoryId)
                                ? _categoryId
                                : cats.first.id,
                            decoration: hmInput("Primary Category"),
                            items: cats
                                .map((c) => DropdownMenuItem(
                                    value: c.id, child: Text(c.name)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _categoryId = v);
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _visit,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: hmInput("Visit Fee (OMR)",
                                    error:
                                        _errors["visit_price"]?.firstOrNull),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _hourly,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: hmInput("Hourly Rate (OMR)",
                                    error:
                                        _errors["hourly_rate"]?.firstOrNull),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _exp,
                          keyboardType: TextInputType.number,
                          decoration: hmInput("Experience (years)"),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _skills,
                          decoration: hmInput("Skills (comma separated)"),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bio,
                          maxLines: 3,
                          decoration: hmInput("Bio"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  HmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Allow Customer Bargaining"),
                          value: _allowCustomBargain,
                          onChanged: (v) =>
                              setState(() => _allowCustomBargain = v),
                        ),
                        if (_allowCustomBargain) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _minBargain,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration: hmInput("Minimum Acceptable Price (OMR)",
                                error:
                                    _errors["min_custom_price"]?.firstOrNull),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  HmButton(
                    label: "Save changes",
                    busy: _saving,
                    onPressed: p.isSuspended ? null : _save,
                  ),
                ],
              ),
            ),
    );
  }
}

/// Day-wise Schedule & Slots Manager (`PUT /seller/muskila/schedule`).
class HmScheduleScreen extends StatefulWidget {
  final HmProfile? profile;

  const HmScheduleScreen({super.key, this.profile});

  @override
  State<HmScheduleScreen> createState() => _HmScheduleScreenState();
}

class _HmScheduleScreenState extends State<HmScheduleScreen> {
  final _repo = HmRepository();
  static const _days = [
    ("sat", "Saturday"),
    ("sun", "Sunday"),
    ("mon", "Monday"),
    ("tue", "Tuesday"),
    ("wed", "Wednesday"),
    ("thu", "Thursday"),
    ("fri", "Friday"),
  ];

  final Map<String, bool> _open = {};
  final Map<String, Set<String>> _slots = {};
  List<HmScheduleSlot> _metaSlots = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ws = widget.profile?.workingSchedule ?? {};
    for (final d in _days) {
      final row = hmMap(ws[d.$1]);
      _open[d.$1] = row.isEmpty ? d.$1 != "fri" : hmBool(row["open"], true);
      _slots[d.$1] = hmStrList(row["slots"]).toSet();
    }
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final m = await _repo.meta();
      if (mounted) setState(() => _metaSlots = m.slots);
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{};
      for (final d in _days) {
        payload[d.$1] = {
          "open": _open[d.$1] ?? false,
          "slots": (_slots[d.$1] ?? {}).toList(),
        };
      }
      hmToast(await _repo.updateSchedule(payload));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      hmToastError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: hmAppBar(context, "Working Hours & Slots"),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final d in _days) ...[
            HmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(d.$2,
                        style: AppTheme.body(size: 15, weight: FontWeight.w600)),
                    value: _open[d.$1] ?? false,
                    onChanged: (v) => setState(() => _open[d.$1] = v),
                  ),
                  if ((_open[d.$1] ?? false) && _metaSlots.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: _metaSlots.map((s) {
                        final selected = _slots[d.$1]!.contains(s.id);
                        return FilterChip(
                          label: Text(s.label),
                          selected: selected,
                          onSelected: (on) {
                            setState(() {
                              on
                                  ? _slots[d.$1]!.add(s.id)
                                  : _slots[d.$1]!.remove(s.id);
                            });
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          HmButton(label: "Save schedule", busy: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

/// Service Area, Map Pin & Coverage Radius (`PUT /seller/muskila/location`).
class HmLocationScreen extends StatefulWidget {
  final HmProfile? profile;

  const HmLocationScreen({super.key, this.profile});

  @override
  State<HmLocationScreen> createState() => _HmLocationScreenState();
}

class _HmLocationScreenState extends State<HmLocationScreen> {
  final _repo = HmRepository();
  final _label = TextEditingController();
  late LatLng _pin;
  double _radius = 15;
  List<String> _allAreas = [];
  final Set<String> _selectedAreas = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _pin = LatLng(p?.lat ?? 23.5932, p?.lng ?? 58.4137);
    _radius = (p?.radiusKm ?? 15).toDouble().clamp(1, 50);
    _label.text = p?.locationLabel ?? "";
    _selectedAreas.addAll(p?.serviceAreas ?? []);
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final m = await _repo.meta();
      if (mounted) setState(() => _allAreas = m.serviceAreas);
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      hmToast(await _repo.updateLocation({
        "lat": _pin.latitude,
        "lng": _pin.longitude,
        "location_label": _label.text.trim(),
        "service_areas": _selectedAreas.toList(),
        "radius_km": _radius.round(),
      }));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      hmToastError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: hmAppBar(context, "Service Area & GPS"),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HmCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _pin,
                  initialZoom: 13,
                  onTap: (_, pt) => setState(() => _pin = pt),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: "com.dokan.seller",
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _pin,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin,
                            color: MyTheme.red, size: 38),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          HmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                    controller: _label, decoration: hmInput("Location label")),
                const SizedBox(height: 12),
                Text("Coverage Radius: ${_radius.round()} km",
                    style: AppTheme.body(size: 14, weight: FontWeight.w600)),
                Slider(
                  value: _radius,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  onChanged: (v) => setState(() => _radius = v),
                ),
                if (_allAreas.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text("Service Areas",
                      style: AppTheme.body(size: 14, weight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _allAreas.map((a) {
                      return FilterChip(
                        label: Text(a),
                        selected: _selectedAreas.contains(a),
                        onSelected: (on) => setState(() => on
                            ? _selectedAreas.add(a)
                            : _selectedAreas.remove(a)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          HmButton(label: "Save location", busy: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

/// 8-Point KYC Verification Status & Document Uploader.
class HmKycScreen extends StatelessWidget {
  final HmProfile? profile;

  const HmKycScreen({super.key, this.profile});

  static const _defaultKeys = [
    ("national_id", "National ID"),
    ("selfie", "Selfie check"),
    ("phone", "Phone"),
    ("address", "Address"),
    ("work_permit", "Work permit"),
    ("trade_licence", "Trade licence"),
    ("police_clearance", "Police clearance"),
    ("skill_test", "Skill test"),
  ];

  @override
  Widget build(BuildContext context) {
    final checks = profile?.verifications ?? const [];
    final map = {for (final c in checks) c.key: c};
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: hmAppBar(context, "KYC Verification"),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _defaultKeys.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final k = _defaultKeys[i];
          final v = map[k.$1]?.verified ?? false;
          return HmCard(
            child: Row(
              children: [
                Icon(
                  v ? Icons.verified_rounded : Icons.pending_outlined,
                  color: v ? MyTheme.green : MyTheme.amber_ink,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    map[k.$1]?.label ?? k.$2,
                    style: AppTheme.body(size: 15, weight: FontWeight.w600),
                  ),
                ),
                HmPill.status(
                  v ? "approved" : "pending",
                  v ? "Verified" : "Pending",
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

