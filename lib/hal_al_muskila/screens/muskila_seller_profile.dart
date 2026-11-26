import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

class MuskilaSellerProfileScreen extends StatefulWidget {
  final bool showBack;

  const MuskilaSellerProfileScreen({super.key, this.showBack = true});

  @override
  State<MuskilaSellerProfileScreen> createState() =>
      _MuskilaSellerProfileScreenState();
}

class _MuskilaSellerProfileScreenState
    extends State<MuskilaSellerProfileScreen> {
  MuskilaSellerProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await MuskilaSellerApi.instance.getProfile();
    if (mounted) {
      setState(() {
        _profile = p;
        _isLoading = false;
      });
    }
  }

  void _showEditSheet() {
    if (_profile == null) return;
    final p = _profile!;
    final nameCtrl = TextEditingController(text: p.name);
    final titleCtrl = TextEditingController(text: p.professionTitle);
    final hourlyCtrl =
        TextEditingController(text: p.hourlyRate.toStringAsFixed(0));
    final visitCtrl =
        TextEditingController(text: p.visitPrice.toStringAsFixed(0));
    final bioCtrl = TextEditingController(text: p.bio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(MyTheme.radius_sheet)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 14, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: MyTheme.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Edit Profile & Rates",
                      style: AppTheme.body(
                          size: 18,
                          weight: FontWeight.w700,
                          color: MyTheme.ink)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Text("Full Name",
                  style: AppTheme.body(
                      size: 13, weight: FontWeight.w600, color: MyTheme.ink)),
              const SizedBox(height: 4),
              TextField(controller: nameCtrl, decoration: _deco("Name")),
              const SizedBox(height: 12),
              Text("Profession Title",
                  style: AppTheme.body(
                      size: 13, weight: FontWeight.w600, color: MyTheme.ink)),
              const SizedBox(height: 4),
              TextField(
                  controller: titleCtrl,
                  decoration: _deco("e.g. Master Electrician")),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Base Visit Fee (OMR)",
                            style: AppTheme.body(
                                size: 13,
                                weight: FontWeight.w600,
                                color: MyTheme.ink)),
                        const SizedBox(height: 4),
                        TextField(
                            controller: visitCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _deco("5.000")),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hourly Rate (OMR)",
                            style: AppTheme.body(
                                size: 13,
                                weight: FontWeight.w600,
                                color: MyTheme.ink)),
                        const SizedBox(height: 4),
                        TextField(
                            controller: hourlyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _deco("15.000")),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text("About & Experience",
                  style: AppTheme.body(
                      size: 13, weight: FontWeight.w600, color: MyTheme.ink)),
              const SizedBox(height: 4),
              TextField(
                  controller: bioCtrl,
                  maxLines: 3,
                  decoration: _deco("Brief bio...")),
              const SizedBox(height: 20),
              MuskilaButton(
                label: "Save Changes",
                icon: Icons.check_rounded,
                onPressed: () async {
                  Navigator.pop(ctx);
                  final updated =
                      await MuskilaSellerApi.instance.updateProfile(
                    name: nameCtrl.text.trim(),
                    professionTitle: titleCtrl.text.trim(),
                    hourlyRate: double.tryParse(hourlyCtrl.text) ?? p.hourlyRate,
                    visitPrice: double.tryParse(visitCtrl.text) ?? p.visitPrice,
                    bio: bioCtrl.text.trim(),
                    skills: p.skills,
                  );
                  setState(() => _profile = updated);
                  muskilaToast("Specialist profile updated!");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: MyTheme.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MyTheme.radius_control),
          borderSide: const BorderSide(color: MyTheme.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MyTheme.radius_control),
          borderSide: const BorderSide(color: MyTheme.hairline),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _profile == null) {
      return Scaffold(
        backgroundColor: MyTheme.paper,
        appBar: muskilaAppBar(context, "Specialist Profile",
            showBack: widget.showBack),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final p = _profile!;

    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: muskilaAppBar(
        context,
        "Specialist Profile",
        showBack: widget.showBack,
        actions: [
          TextButton.icon(
            onPressed: _showEditSheet,
            icon: const Icon(Icons.edit_outlined, size: 17, color: MyTheme.navy),
            label: Text(
              "Edit",
              style: AppTheme.body(
                  size: 13.5, weight: FontWeight.w600, color: MyTheme.navy),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Hero Card
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [MyTheme.navy_deep, MyTheme.navy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(MyTheme.radius_card),
              boxShadow: const [
                BoxShadow(
                  color: MyTheme.app_accent_shado,
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                MuskilaAvatar(name: p.name, size: 70, verified: p.isVerified),
                const SizedBox(height: 12),
                Text(
                  p.name,
                  style: AppTheme.body(
                      size: 19, weight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  p.professionTitle,
                  style: AppTheme.body(
                      size: 13, color: Colors.white.withValues(alpha: 0.78)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p.categoryName,
                    style: AppTheme.body(
                        size: 12,
                        weight: FontWeight.w600,
                        color: MyTheme.amber),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _metric("Rating", "${p.rating} ★"),
                      _metric("Jobs Done", "${p.jobsCompleted}"),
                      _metric("Experience", "${p.experienceYears} Yrs"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Pricing Card
          MuskilaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Service Pricing",
                    style: AppTheme.body(
                        size: 15.5,
                        weight: FontWeight.w700,
                        color: MyTheme.ink)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: MyTheme.paper,
                          borderRadius:
                              BorderRadius.circular(MyTheme.radius_control),
                          border: Border.all(color: MyTheme.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Visit Base Fee",
                                style: AppTheme.body(
                                    size: 11.5, color: MyTheme.medium_grey)),
                            const SizedBox(height: 4),
                            Text(muskilaMoney(p.visitPrice),
                                style:
                                    AppTheme.figure(18, color: MyTheme.navy)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: MyTheme.paper,
                          borderRadius:
                              BorderRadius.circular(MyTheme.radius_control),
                          border: Border.all(color: MyTheme.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Standard Hourly",
                                style: AppTheme.body(
                                    size: 11.5, color: MyTheme.medium_grey)),
                            const SizedBox(height: 4),
                            Text("${muskilaMoney(p.hourlyRate)}/hr",
                                style:
                                    AppTheme.figure(18, color: MyTheme.navy)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Skills & Bio Card
          MuskilaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Skills & Capabilities",
                    style: AppTheme.body(
                        size: 15.5,
                        weight: FontWeight.w700,
                        color: MyTheme.ink)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: p.skills
                      .map((s) => MuskilaPill(
                            s,
                            bg: MyTheme.blue_tint,
                            fg: MyTheme.navy,
                          ))
                      .toList(),
                ),
                const Divider(height: 24, color: MyTheme.hairline),
                Text("About",
                    style: AppTheme.body(
                        size: 14, weight: FontWeight.w700, color: MyTheme.ink)),
                const SizedBox(height: 6),
                Text(p.bio,
                    style: AppTheme.body(
                        size: 13.5, color: MyTheme.font_grey, height: 1.45)),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _metric(String title, String val) => Column(
        children: [
          Text(val, style: AppTheme.figure(18, color: Colors.white)),
          const SizedBox(height: 2),
          Text(title,
              style: AppTheme.body(
                  size: 11.5, color: Colors.white.withValues(alpha: 0.72))),
        ],
      );
}
