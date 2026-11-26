import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// Create / Edit a fixed service package (`ChDishForm` pattern).
class HmServiceForm extends StatefulWidget {
  final HmServicePackage? service;

  const HmServiceForm({super.key, this.service});

  @override
  State<HmServiceForm> createState() => _HmServiceFormState();
}

class _HmServiceFormState extends State<HmServiceForm> {
  final _repo = HmRepository();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _time = TextEditingController(text: "1-2 hours");
  final _warranty = TextEditingController(text: "30 Days DOKAN Guarantee");
  final _desc = TextEditingController();
  final _inclusions = TextEditingController();

  HmMeta? _meta;
  String _categoryId = "ac-cooling";
  bool _published = true;
  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    if (s != null) {
      _title.text = s.title;
      _price.text = s.fromPrice.toStringAsFixed(3);
      _time.text = s.estimatedTime;
      _warranty.text = s.warranty;
      _desc.text = s.description;
      _inclusions.text = s.inclusions.join(", ");
      _categoryId = s.categoryId.isNotEmpty ? s.categoryId : "ac-cooling";
      _published = s.published;
    }
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final m = await _repo.meta();
      if (mounted) {
        setState(() {
          _meta = m;
          if (!m.categories.any((c) => c.id == _categoryId) &&
              m.categories.isNotEmpty) {
            _categoryId = m.categories.first.id;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      hmToast("Service title is required.");
      return;
    }
    final price = double.tryParse(_price.text.trim());
    if (price == null || price <= 0) {
      hmToast("Enter a valid starting price.");
      return;
    }
    setState(() => _saving = true);
    try {
      int? imageId;
      if (_photoPath != null) {
        imageId =
            (await _repo.upload(_photoPath!, type: "service_photo")).uploadId;
      }
      final body = {
        "category_id": _categoryId,
        "title": _title.text.trim(),
        "from_price": price,
        "estimated_time": _time.text.trim(),
        "warranty": _warranty.text.trim(),
        "description": _desc.text.trim(),
        "inclusions": _inclusions.text
            .split(",")
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        if (imageId != null) "image_id": imageId,
        "published": _published,
      };
      final msg = widget.service == null
          ? await _repo.createService(body)
          : await _repo.updateService(widget.service!.id, body);
      if (!mounted) return;
      hmToast(msg);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      hmToastError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = _meta?.categories ?? const [];
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: hmAppBar(
        context,
        widget.service == null ? "New Service" : "Edit Service",
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cats.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _categoryId,
                    decoration: hmInput("Category"),
                    items: cats
                        .map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _categoryId = v);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                    controller: _title, decoration: hmInput("Service title")),
                const SizedBox(height: 12),
                TextField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: hmInput("Starting price (OMR)"),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: _time, decoration: hmInput("Estimated time")),
                const SizedBox(height: 12),
                TextField(
                    controller: _warranty, decoration: hmInput("Warranty")),
                const SizedBox(height: 12),
                TextField(
                  controller: _inclusions,
                  decoration: hmInput("Inclusions (comma separated)",
                      hint: "Inspection, Cleaning, Gas check"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _desc,
                  maxLines: 3,
                  decoration: hmInput("Description"),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final p = await hmPickImage(context);
                    if (p != null) setState(() => _photoPath = p);
                  },
                  icon: const Icon(Icons.photo_outlined),
                  label: Text(
                      _photoPath == null ? "Upload Photo" : "Photo selected"),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Published"),
                  value: _published,
                  onChanged: (v) => setState(() => _published = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HmButton(label: "Save service", busy: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

