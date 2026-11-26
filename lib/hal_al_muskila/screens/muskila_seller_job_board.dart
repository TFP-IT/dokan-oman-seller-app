import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

class MuskilaSellerJobBoardScreen extends StatefulWidget {
  final bool showBack;

  const MuskilaSellerJobBoardScreen({super.key, this.showBack = true});

  @override
  State<MuskilaSellerJobBoardScreen> createState() =>
      _MuskilaSellerJobBoardScreenState();
}

class _MuskilaSellerJobBoardScreenState
    extends State<MuskilaSellerJobBoardScreen> {
  List<MuskilaJobLead> _leads = [];
  bool _loading = true;
  String _filter = "all"; // all | urgent | applied

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_leads.isEmpty) setState(() => _loading = true);
    final list = await MuskilaSellerApi.instance.getJobLeads(refresh: true);
    if (mounted) {
      setState(() {
        _leads = list;
        _loading = false;
      });
    }
  }

  List<MuskilaJobLead> get _filtered {
    switch (_filter) {
      case "urgent":
        return _leads.where((l) => l.isUrgent).toList();
      case "applied":
        return _leads.where((l) => l.hasApplied).toList();
      default:
        return _leads;
    }
  }

  void _openQuoteSheet(MuskilaJobLead lead) {
    final priceCtrl =
        TextEditingController(text: lead.budget.toStringAsFixed(0));
    final noteCtrl = TextEditingController();

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  "Submit Quote",
                  style: AppTheme.body(
                      size: 18, weight: FontWeight.w700, color: MyTheme.ink),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Text(lead.title,
                style: AppTheme.body(size: 13.5, color: MyTheme.dark_grey)),
            const Divider(height: 24, color: MyTheme.hairline),
            Text("Quote amount (OMR)",
                style: AppTheme.body(
                    size: 13, weight: FontWeight.w600, color: MyTheme.ink)),
            const SizedBox(height: 6),
            TextField(
              controller: priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: "OMR ",
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
              ),
            ),
            const SizedBox(height: 14),
            Text("Message to customer",
                style: AppTheme.body(
                    size: 13, weight: FontWeight.w600, color: MyTheme.ink)),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    "e.g. Can visit today at 3 PM. Official tools and warranty included.",
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
              ),
            ),
            const SizedBox(height: 20),
            MuskilaButton(
              label: "Send Quote",
              icon: Icons.send_rounded,
              onPressed: () async {
                final price = double.tryParse(priceCtrl.text) ?? lead.budget;
                Navigator.pop(ctx);
                await MuskilaSellerApi.instance.submitQuote(
                    leadId: lead.id, price: price, message: noteCtrl.text);
                _load();
                muskilaToast("Quote submitted to customer!");
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: muskilaAppBar(context, "Job Leads", showBack: widget.showBack),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter bar
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _chip("all", "All (${_leads.length})"),
                      const SizedBox(width: 8),
                      _chip(
                        "urgent",
                        "Urgent (${_leads.where((l) => l.isUrgent).length})",
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        "applied",
                        "Quoted (${_leads.where((l) => l.hasApplied).length})",
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: MyTheme.hairline),
                Expanded(
                  child: list.isEmpty
                      ? const MuskilaEmptyView(
                          text: "No job leads match this filter.",
                          icon: Icons.travel_explore_outlined,
                        )
                      : RefreshIndicator(
                          color: MyTheme.navy,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) => _leadItem(list[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _chip(String key, String label) {
    final selected = _filter == key;
    return ChoiceChip(
      label: Text(
        label,
        style: AppTheme.body(
          size: 12.5,
          weight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : MyTheme.ink,
        ),
      ),
      selected: selected,
      selectedColor: MyTheme.navy,
      backgroundColor: MyTheme.paper,
      side: BorderSide(color: selected ? MyTheme.navy : MyTheme.hairline),
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = key),
    );
  }

  Widget _leadItem(MuskilaJobLead lead) {
    return MuskilaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MuskilaPill(
                lead.categoryName,
                bg: MyTheme.blue_tint,
                fg: MyTheme.royal,
              ),
              const Spacer(),
              if (lead.isUrgent)
                const MuskilaPill(
                  "Urgent",
                  bg: Color(0xFFFBE7E4),
                  fg: MyTheme.red,
                  icon: Icons.bolt_rounded,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lead.title,
            style: AppTheme.body(
                size: 15.5, weight: FontWeight.w700, color: MyTheme.ink),
          ),
          const SizedBox(height: 4),
          Text(
            lead.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.body(size: 13, color: MyTheme.dark_grey, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 15, color: MyTheme.medium_grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lead.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(size: 12, color: MyTheme.medium_grey),
                ),
              ),
              Icon(Icons.schedule_outlined,
                  size: 15, color: MyTheme.medium_grey),
              const SizedBox(width: 4),
              Text(
                lead.preferredSchedule,
                style: AppTheme.body(size: 12, color: MyTheme.medium_grey),
              ),
            ],
          ),
          const Divider(height: 22, color: MyTheme.hairline),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Est. Budget",
                      style:
                          AppTheme.body(size: 11, color: MyTheme.medium_grey)),
                  Text(muskilaMoney(lead.budget),
                      style: AppTheme.figure(16, color: MyTheme.navy)),
                ],
              ),
              const Spacer(),
              Text(
                "${lead.proposalCount} quotes",
                style: AppTheme.body(size: 12, color: MyTheme.medium_grey),
              ),
              const SizedBox(width: 12),
              lead.hasApplied
                  ? const MuskilaPill(
                      "Quote Sent",
                      bg: Color(0xFFE2F3EC),
                      fg: MyTheme.green,
                      icon: Icons.check_circle_outline_rounded,
                    )
                  : FilledButton.icon(
                      onPressed: () => _openQuoteSheet(lead),
                      icon: const Icon(Icons.send_rounded, size: 15),
                      label: const Text("Quote"),
                      style: FilledButton.styleFrom(
                        backgroundColor: MyTheme.navy,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(MyTheme.radius_control),
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
