import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// 3-tab Job Board: Customer Job Leads, My Submitted Quotes, Expert Bargain Posts.
class HmJobBoardScreen extends StatelessWidget {
  final int initialTab;
  final bool showBack;

  const HmJobBoardScreen({
    super.key,
    this.initialTab = 0,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Scaffold(
        backgroundColor: MyTheme.paper,
        appBar: AppBar(
          automaticallyImplyLeading: showBack,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: AppTheme.lightStatusBar,
          iconTheme: const IconThemeData(color: MyTheme.ink),
          title: Text(
            "Job Board",
            style: AppTheme.body(
              size: 18,
              weight: FontWeight.w600,
              color: MyTheme.ink,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: MyTheme.navy,
            unselectedLabelColor: MyTheme.medium_grey,
            indicatorColor: MyTheme.navy,
            tabs: const [
              Tab(text: "Job Leads"),
              Tab(text: "My Quotes"),
              Tab(text: "Expert Posts"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LeadsTab(),
            _MyQuotesTab(),
            _ExpertPostsTab(),
          ],
        ),
      ),
    );
  }
}

// ---- Tab 1: Customer Job Leads ---------------------------------------------

class _LeadsTab extends StatefulWidget {
  const _LeadsTab();

  @override
  State<_LeadsTab> createState() => _LeadsTabState();
}

class _LeadsTabState extends State<_LeadsTab>
    with AutomaticKeepAliveClientMixin {
  final _repo = HmRepository();
  final List<HmJobLead> _leads = [];
  String _filter = "all";
  bool _loading = true;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _repo.jobLeads(filter: _filter);
      if (!mounted) return;
      setState(() {
        _leads
          ..clear()
          ..addAll(p.items);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _openQuoteSheet(HmJobLead lead) async {
    final priceCtrl = TextEditingController(
      text: (lead.budgetMax > 0 ? lead.budgetMax : lead.budgetMin)
          .toStringAsFixed(3),
    );
    final msgCtrl = TextEditingController();
    final teamCtrl = TextEditingController(text: "Solo Certified Pro");
    HmMeta? meta;
    try {
      meta = await _repo.meta();
    } catch (_) {}
    if (!mounted) return;

    String? date = meta?.dates.firstOrNull?.date;
    String? slotId = meta?.slots.firstOrNull?.id;
    String? whenText = [
      meta?.dates.firstOrNull?.label,
      meta?.slots.firstOrNull?.label,
    ].where((s) => s != null && s.isNotEmpty).join(", ");
    String sendKey = HmApi.newIdempotencyKey();
    bool busy = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(MyTheme.radius_sheet)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 14, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Submit Quote", style: AppTheme.display(size: 18)),
                const SizedBox(height: 4),
                Text(lead.title,
                    style:
                        AppTheme.body(size: 13, color: MyTheme.medium_grey)),
                const SizedBox(height: 14),
                TextField(
                  controller: priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: hmInput("Quote amount (OMR)"),
                ),
                const SizedBox(height: 10),
                if (meta != null && meta.dates.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: date,
                    decoration: hmInput("Available Date"),
                    items: meta.dates
                        .map((d) => DropdownMenuItem(
                            value: d.date, child: Text(d.label)))
                        .toList(),
                    onChanged: (v) => setS(() => date = v),
                  ),
                  const SizedBox(height: 10),
                ],
                if (meta != null && meta.slots.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: slotId,
                    decoration: hmInput("Available Time Slot"),
                    items: meta.slots
                        .map((s) => DropdownMenuItem(
                            value: s.id, child: Text(s.label)))
                        .toList(),
                    onChanged: (v) => setS(() => slotId = v),
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: teamCtrl,
                  decoration: hmInput("Team / Worker detail",
                      hint: "e.g. Master Tech + 1 Helper"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: msgCtrl,
                  maxLines: 3,
                  decoration: hmInput("Message to customer"),
                ),
                const SizedBox(height: 16),
                HmButton(
                  label: "Send Quote",
                  busy: busy,
                  onPressed: () async {
                    final price = double.tryParse(priceCtrl.text.trim());
                    if (price == null || price <= 0) {
                      hmToast("Enter a valid quote amount.");
                      return;
                    }
                    setS(() => busy = true);
                    try {
                      final res = await _repo.submitQuote({
                        "lead_id": lead.id,
                        "price": price,
                        "message": msgCtrl.text.trim(),
                        "when_text": whenText,
                        "date": date,
                        "slot_id": slotId,
                        "team_or_worker_detail": teamCtrl.text.trim(),
                      }, sendKey);
                      if (ctx.mounted) Navigator.pop(ctx);
                      hmToast(res);
                      _load();
                    } catch (e) {
                      if (e is HmApiException && e.status != 0) {
                        sendKey = HmApi.newIdempotencyKey();
                      }
                      if (ctx.mounted) setS(() => busy = false);
                      hmToastError(e);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              for (final f in [("all", "All"), ("urgent", "Urgent"), ("unquoted", "Unquoted")])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.$2),
                    selected: _filter == f.$1,
                    selectedColor: MyTheme.navy,
                    labelStyle: TextStyle(
                      color: _filter == f.$1 ? Colors.white : MyTheme.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _filter = f.$1);
                      _load();
                    },
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: MyTheme.hairline),
        Expanded(
          child: _loading && _leads.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _leads.isEmpty
                  ? HmErrorView(message: hmErrorText(_error!), onRetry: _load)
                  : RefreshIndicator(
                      color: MyTheme.navy,
                      onRefresh: _load,
                      child: _leads.isEmpty
                          ? const HmEmptyView(
                              text: "No job leads match this filter.",
                              icon: Icons.explore_outlined,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _leads.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final l = _leads[i];
                                return HmCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          HmPill(l.categoryName),
                                          const SizedBox(width: 6),
                                          if (l.isUrgent)
                                            HmPill.status("urgent", "Urgent"),
                                          const Spacer(),
                                          Text(
                                            l.closesInText.isNotEmpty
                                                ? "Closes in ${l.closesInText}"
                                                : l.createdAtText,
                                            style: AppTheme.body(
                                              size: 11.5,
                                              color: MyTheme.medium_grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (l.imageUrl != null &&
                                              l.imageUrl!.isNotEmpty) ...[
                                            HmNetImage(
                                                url: l.imageUrl, size: 56),
                                            const SizedBox(width: 12),
                                          ],
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  l.title,
                                                  style: AppTheme.body(
                                                    size: 15.5,
                                                    weight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  l.description,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTheme.body(
                                                    size: 13,
                                                    color: MyTheme.dark_grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        "${l.location} (${l.distanceKm.toStringAsFixed(1)} km) · ${l.preferredSchedule}",
                                        style: AppTheme.body(
                                          size: 12,
                                          color: MyTheme.medium_grey,
                                        ),
                                      ),
                                      const Divider(height: 20),
                                      Row(
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Est. Budget",
                                                style: AppTheme.body(
                                                  size: 11,
                                                  color: MyTheme.medium_grey,
                                                ),
                                              ),
                                              Text(
                                                l.budgetMin == l.budgetMax
                                                    ? hmMoney(l.budgetMax)
                                                    : "${hmMoney(l.budgetMin)} - ${hmMoney(l.budgetMax)}",
                                                style: AppTheme.figure(
                                                  15,
                                                  color: MyTheme.navy,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Spacer(),
                                          Text(
                                            "${l.proposalCount}/${l.maxQuotes} quotes",
                                            style: AppTheme.body(
                                              size: 12,
                                              color: MyTheme.medium_grey,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          l.hasApplied
                                              ? HmPill.status(
                                                  "accepted", "Quoted")
                                              : FilledButton(
                                                  style:
                                                      FilledButton.styleFrom(
                                                    backgroundColor:
                                                        MyTheme.navy,
                                                  ),
                                                  onPressed: () =>
                                                      _openQuoteSheet(l),
                                                  child: const Text("Quote"),
                                                ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
        ),
      ],
    );
  }
}

// ---- Tab 2: My Quotes ------------------------------------------------------

class _MyQuotesTab extends StatefulWidget {
  const _MyQuotesTab();

  @override
  State<_MyQuotesTab> createState() => _MyQuotesTabState();
}

class _MyQuotesTabState extends State<_MyQuotesTab>
    with AutomaticKeepAliveClientMixin {
  final _repo = HmRepository();
  final List<HmQuote> _quotes = [];
  bool _loading = true;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _repo.quotes();
      if (!mounted) return;
      setState(() {
        _quotes
          ..clear()
          ..addAll(p.items);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _withdraw(HmQuote q) async {
    try {
      hmToast(await _repo.withdrawQuote(q.id));
      _load();
    } catch (e) {
      hmToastError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _quotes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _quotes.isEmpty) {
      return HmErrorView(message: hmErrorText(_error!), onRetry: _load);
    }
    return RefreshIndicator(
      color: MyTheme.navy,
      onRefresh: _load,
      child: _quotes.isEmpty
          ? const HmEmptyView(
              text: "No submitted quotes yet.",
              icon: Icons.request_quote_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _quotes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final q = _quotes[i];
                return HmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              q.leadTitle,
                              style: AppTheme.body(
                                size: 15,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                          HmPill.status(q.status),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${hmMoney(q.price)} · ${q.whenText}",
                        style: AppTheme.body(
                          size: 13.5,
                          weight: FontWeight.w600,
                          color: MyTheme.navy,
                        ),
                      ),
                      if (q.message.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(q.message, style: AppTheme.body(size: 13)),
                      ],
                      if (q.status == "pending") ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: () => _withdraw(q),
                            child: const Text(
                              "Withdraw quote",
                              style: TextStyle(color: MyTheme.red),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ---- Tab 3: Expert Posts with Bargain Tiers --------------------------------

class _ExpertPostsTab extends StatefulWidget {
  const _ExpertPostsTab();

  @override
  State<_ExpertPostsTab> createState() => _ExpertPostsTabState();
}

class _ExpertPostsTabState extends State<_ExpertPostsTab>
    with AutomaticKeepAliveClientMixin {
  final _repo = HmRepository();
  final List<HmExpertPost> _posts = [];
  bool _loading = true;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _repo.expertPosts();
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(p.items);
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _createPostDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final tierLabelCtrl = TextEditingController(text: "Early Bird (15% Off)");
    final tierPriceCtrl = TextEditingController(text: "15.000");
    final tierQuotaCtrl = TextEditingController(text: "5");
    String? photoPath;
    bool bargainable = true;
    bool busy = false;
    HmMeta? meta;
    try {
      meta = await _repo.meta();
    } catch (_) {}
    if (!mounted) return;
    String? catId = meta?.categories.firstOrNull?.id ?? "ac-cooling";

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(MyTheme.radius_sheet)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 14, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("New Expert Service Post",
                    style: AppTheme.display(size: 18)),
                const SizedBox(height: 12),
                if (meta != null && meta.categories.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: catId,
                    decoration: hmInput("Category"),
                    items: meta.categories
                        .map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setS(() => catId = v),
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                    controller: titleCtrl, decoration: hmInput("Post Title")),
                const SizedBox(height: 10),
                TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: hmInput("Description")),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final p = await hmPickImage(ctx);
                    if (p != null) setS(() => photoPath = p);
                  },
                  icon: const Icon(Icons.photo_outlined),
                  label: Text(
                      photoPath == null ? "Attach Photo" : "Photo selected"),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Include Bargain Tier"),
                  value: bargainable,
                  onChanged: (v) => setS(() => bargainable = v),
                ),
                if (bargainable) ...[
                  TextField(
                      controller: tierLabelCtrl,
                      decoration: hmInput("Tier Label")),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tierPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: hmInput("Tier Price (OMR)"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: tierQuotaCtrl,
                          keyboardType: TextInputType.number,
                          decoration: hmInput("Quota"),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                HmButton(
                  label: "Publish Post",
                  busy: busy,
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) {
                      hmToast("Title is required.");
                      return;
                    }
                    setS(() => busy = true);
                    try {
                      int? imageId;
                      if (photoPath != null) {
                        imageId = (await _repo.upload(photoPath!,
                                type: "post_photo"))
                            .uploadId;
                      }
                      final msg = await _repo.createExpertPost({
                        "category_id": catId,
                        "title": titleCtrl.text.trim(),
                        "description": descCtrl.text.trim(),
                        "image_id": imageId,
                        "is_bargainable": bargainable,
                        if (bargainable)
                          "bargain_tiers": [
                            {
                              "label": tierLabelCtrl.text.trim(),
                              "price":
                                  double.tryParse(tierPriceCtrl.text) ?? 15.0,
                              "total_quota":
                                  int.tryParse(tierQuotaCtrl.text) ?? 5,
                            }
                          ],
                      }, HmApi.newIdempotencyKey());
                      if (ctx.mounted) Navigator.pop(ctx);
                      hmToast(msg);
                      _load();
                    } catch (e) {
                      if (ctx.mounted) setS(() => busy = false);
                      hmToastError(e);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: MyTheme.paper,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MyTheme.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("New deal post"),
        onPressed: _createPostDialog,
      ),
      body: _loading && _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _posts.isEmpty
              ? HmErrorView(message: hmErrorText(_error!), onRetry: _load)
              : RefreshIndicator(
                  color: MyTheme.navy,
                  onRefresh: _load,
                  child: _posts.isEmpty
                      ? const HmEmptyView(
                          text: "No expert posts yet.",
                          icon: Icons.campaign_outlined,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                          itemCount: _posts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final p = _posts[i];
                            return HmCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      HmNetImage(url: p.imageUrl, size: 52),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.title,
                                              style: AppTheme.body(
                                                size: 15,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              p.categoryName,
                                              style: AppTheme.body(
                                                size: 12,
                                                color: MyTheme.medium_grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: MyTheme.red),
                                        onPressed: () async {
                                          try {
                                            hmToast(await _repo
                                                .deleteExpertPost(p.id));
                                            _load();
                                          } catch (e) {
                                            hmToastError(e);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  if (p.bargainTiers.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: p.bargainTiers
                                          .map((t) => HmPill(
                                              "${t.label}: ${hmMoney(t.price)} (${t.remainingQuota}/${t.totalQuota})"))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

