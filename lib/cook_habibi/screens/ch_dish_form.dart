import 'dart:io';

import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_api.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_repository.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class _Photo {
  int? uploadId;
  String? url;
  String? localPath;

  _Photo({this.uploadId, this.url, this.localPath});
}

/// Create or edit a dish (guide §7). Edit sends only changed fields.
class ChDishForm extends StatefulWidget {
  final int? dishId;

  const ChDishForm({super.key, this.dishId});

  @override
  State<ChDishForm> createState() => _ChDishFormState();
}

class _ChDishFormState extends State<ChDishForm> {
  static const _dietaryOptions = [
    "halal",
    "vegetarian",
    "vegan",
    "gluten_free",
    "dairy_free",
    "spicy",
    "healthy",
  ];

  final _repo = ChRepository();
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _discount = TextEditingController();
  final _emoji = TextEditingController();
  final _serves = TextEditingController(text: "1");
  final _allergens = TextEditingController();
  final _badge = TextEditingController();
  final _capacity = TextEditingController();
  final _sort = TextEditingController();
  Set<String> _dietary = {};
  bool _familyMeal = false;
  bool _preOrderOnly = false;
  bool _published = true;

  _Photo? _thumb;
  final List<_Photo> _photos = [];
  bool _photosChanged = false;
  bool _thumbChanged = false;

  Map<String, dynamic> _original = {};
  bool _loading = false;
  bool _saving = false;
  Map<String, List<String>> _errors = {};

  bool get _isEdit => widget.dishId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await _repo.dish(widget.dishId!);
      _name.text = d.name;
      _description.text = d.description;
      _price.text = d.price == 0 ? "" : d.price.toString();
      _discount.text =
          d.discountPercent == 0 ? "" : d.discountPercent.toStringAsFixed(0);
      _emoji.text = d.emoji;
      _serves.text = d.serves.toString();
      _allergens.text = d.allergens.join(", ");
      _badge.text = d.badge;
      _capacity.text = d.dailyCapacity?.toString() ?? "";
      _sort.text = d.sort?.toString() ?? "";
      _dietary = d.dietary.toSet();
      _familyMeal = d.isFamilyMeal;
      _preOrderOnly = d.preOrderOnly;
      _published = d.published;
      if (d.thumbnailUrl != null || d.thumbnailUploadId != null) {
        _thumb = _Photo(uploadId: d.thumbnailUploadId, url: d.thumbnailUrl);
      }
      final p = d.raw["photos"];
      if (p is List) {
        for (final e in p) {
          if (e is Map) {
            _photos.add(_Photo(
                uploadId: chInt(e["upload_id"] ?? e["id"]),
                url: chStr(e["url"])));
          } else if (e is int) {
            _photos.add(_Photo(uploadId: e));
          } else if (e is String) {
            _photos.add(_Photo(url: e));
          }
        }
      }
      _original = _body();
    } catch (e) {
      chToastError(e);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Every field as the API expects it (without images).
  Map<String, dynamic> _body() => {
        "name": _name.text.trim(),
        "description": _description.text.trim(),
        "price": double.tryParse(_price.text.trim()) ?? 0,
        "discount_percent": int.tryParse(_discount.text.trim()) ?? 0,
        "emoji": _emoji.text.trim(),
        "serves": int.tryParse(_serves.text.trim()) ?? 1,
        "dietary": _dietary.toList()..sort(),
        "allergens": _allergens.text
            .split(",")
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        "is_family_meal": _familyMeal,
        "pre_order_only": _preOrderOnly,
        "badge": _badge.text.trim(),
        "published": _published,
        if (_capacity.text.trim().isNotEmpty)
          "daily_capacity": int.tryParse(_capacity.text.trim()),
        if (_sort.text.trim().isNotEmpty) "sort": int.tryParse(_sort.text.trim()),
      };

  bool _same(dynamic a, dynamic b) {
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
    return a == b;
  }

  Future<int> _ensureUploaded(_Photo p) async {
    if (p.uploadId != null) return p.uploadId!;
    p.uploadId = await _repo.upload(p.localPath!);
    return p.uploadId!;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errors = {};
    });
    try {
      final all = _body();
      final body = <String, dynamic>{};
      if (_isEdit) {
        all.forEach((k, v) {
          if (!_same(_original[k], v)) body[k] = v;
        });
      } else {
        body.addAll(all);
      }
      if (_thumbChanged || (!_isEdit && _thumb != null)) {
        if (_thumb != null) body["thumbnail"] = await _ensureUploaded(_thumb!);
      }
      if (_photosChanged) {
        final ids = <int>[];
        for (final p in _photos) {
          if (p.uploadId == null && p.localPath == null) continue;
          ids.add(await _ensureUploaded(p));
        }
        body["photos"] = ids;
      }
      if (_isEdit && body.isEmpty) {
        if (mounted) Navigator.pop(context, false);
        return;
      }
      final msg = _isEdit
          ? await _repo.updateDish(widget.dishId!, body)
          : await _repo.createDish(body);
      chToast(msg);
      if (mounted) Navigator.pop(context, true);
    } on ChApiException catch (e) {
      setState(() => _errors = e.errors);
      chToast(e.message);
    } catch (e) {
      chToastError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _err(String f) => _errors[f]?.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: chAppBar(context, _isEdit ? "Edit dish" : "New dish"),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                _imageRow(),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: chInput("Name *", error: _err("name")),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Name is required" : null,
                ),
                _gap,
                TextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration:
                        chInput("Description", error: _err("description"))),
                _gap,
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      ],
                      decoration:
                          chInput("Price (OMR)", error: _err("price")),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _discount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: chInput("Discount %",
                          error: _err("discount_percent")),
                      validator: (v) {
                        final n = int.tryParse(v ?? "");
                        if (n != null && n > 100) return "0 to 100";
                        return null;
                      },
                    ),
                  ),
                ]),
                _gap,
                Row(children: [
                  Expanded(
                    child: TextFormField(
                        controller: _emoji,
                        decoration: chInput("Emoji", hint: "🍖")),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _serves,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: chInput("Serves", error: _err("serves")),
                      validator: (v) {
                        final n = int.tryParse(v ?? "");
                        if (n == null || n < 1 || n > 50) return "1 to 50";
                        return null;
                      },
                    ),
                  ),
                ]),
                _gap,
                Text("Dietary",
                    style: AppTheme.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: MyTheme.medium_grey)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: {..._dietaryOptions, ..._dietary}
                      .map((o) => FilterChip(
                            label: Text(o.replaceAll("_", " ")),
                            selected: _dietary.contains(o),
                            onSelected: (s) => setState(() =>
                                s ? _dietary.add(o) : _dietary.remove(o)),
                          ))
                      .toList(),
                ),
                _gap,
                TextFormField(
                  controller: _allergens,
                  decoration: chInput("Allergens",
                      hint: "Sesame, Nuts (comma separated, max 20)",
                      error: _err("allergens")),
                  validator: (v) {
                    final n = (v ?? "")
                        .split(",")
                        .where((e) => e.trim().isNotEmpty)
                        .length;
                    return n > 20 ? "Max 20 allergens" : null;
                  },
                ),
                _gap,
                Row(children: [
                  Expanded(
                    child: TextFormField(
                        controller: _badge,
                        decoration: chInput("Badge", hint: "e.g. Best seller")),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _capacity,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: chInput("Portions today",
                          error: _err("daily_capacity")),
                    ),
                  ),
                ]),
                _gap,
                TextFormField(
                  controller: _sort,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: chInput("Sort order", hint: "Lower shows first"),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Family meal"),
                    value: _familyMeal,
                    onChanged: (v) => setState(() => _familyMeal = v)),
                SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Pre-order only"),
                    value: _preOrderOnly,
                    onChanged: (v) => setState(() => _preOrderOnly = v)),
                SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Visible to customers"),
                    subtitle: const Text(
                        "New dishes may wait for admin approval first."),
                    value: _published,
                    onChanged: (v) => setState(() => _published = v)),
                const SizedBox(height: 16),
                ChButton(label: "Save", busy: _saving, onPressed: _save),
              ]),
            ),
    );
  }

  static const _gap = SizedBox(height: 12);

  Widget _imageRow() {
    Widget tile(_Photo? p, {required VoidCallback onTap, VoidCallback? onRemove}) {
      final Widget img;
      if (p?.localPath != null) {
        img = Image.file(File(p!.localPath!),
            width: 84, height: 84, fit: BoxFit.cover);
      } else if (p?.url != null) {
        img = Image.network(p!.url!,
            width: 84,
            height: 84,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
                width: 84, height: 84, child: Icon(Icons.image_outlined)));
      } else {
        img = const SizedBox(
            width: 84,
            height: 84,
            child: Icon(Icons.add_a_photo_outlined, color: MyTheme.navy));
      }
      return Stack(children: [
        InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: MyTheme.hairline),
                borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(12), child: img),
          ),
        ),
        if (onRemove != null)
          Positioned(
            right: 2,
            top: 2,
            child: InkWell(
              onTap: onRemove,
              child: const CircleAvatar(
                  radius: 11,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.close, size: 14, color: Colors.white)),
            ),
          ),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Main photo and gallery (max 10)",
          style: AppTheme.body(
              size: 13, weight: FontWeight.w600, color: MyTheme.medium_grey)),
      const SizedBox(height: 8),
      SizedBox(
        height: 84,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          tile(_thumb, onTap: () async {
            final path = await chPickImage(context);
            if (path != null) {
              setState(() {
                _thumb = _Photo(localPath: path);
                _thumbChanged = true;
              });
            }
          }),
          const SizedBox(width: 6),
          const VerticalDivider(),
          ..._photos.map((p) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: tile(p,
                    onTap: () {},
                    onRemove: () => setState(() {
                          _photos.remove(p);
                          _photosChanged = true;
                        })),
              )),
          if (_photos.length < 10)
            tile(null, onTap: () async {
              final path = await chPickImage(context);
              if (path != null) {
                setState(() {
                  _photos.add(_Photo(localPath: path));
                  _photosChanged = true;
                });
              }
            }),
        ]),
      ),
    ]);
  }
}
