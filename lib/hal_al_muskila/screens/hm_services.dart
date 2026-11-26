import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_ui.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/screens/hm_service_form.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// Services catalog with Published / Hidden / Waiting approval tabs (mirrors `ChDishes`).
class HmServicesScreen extends StatelessWidget {
  const HmServicesScreen({super.key});

  static const _tabs = [
    ("published", "Published"),
    ("hidden", "Hidden"),
    ("pending_approval", "Waiting approval"),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: MyTheme.paper,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: AppTheme.lightStatusBar,
          iconTheme: const IconThemeData(color: MyTheme.ink),
          title: Text(
            "Services Catalog",
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
            tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: MyTheme.navy,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text("New service"),
          onPressed: () async {
            final saved = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const HmServiceForm()),
            );
            if (saved == true) _ServiceListState.refreshAll();
          },
        ),
        body: TabBarView(
          children: _tabs.map((t) => _ServiceList(status: t.$1)).toList(),
        ),
      ),
    );
  }
}

class _ServiceList extends StatefulWidget {
  final String status;

  const _ServiceList({required this.status});

  @override
  State<_ServiceList> createState() => _ServiceListState();
}

class _ServiceListState extends State<_ServiceList>
    with AutomaticKeepAliveClientMixin {
  static final Set<_ServiceListState> _live = {};

  static void refreshAll() {
    for (final s in _live.toList()) {
      s._refresh();
    }
  }

  final _repo = HmRepository();
  final _scroll = ScrollController();
  final List<HmServicePackage> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _live.add(this);
    _refresh();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _live.remove(this);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _page = 1;
    _hasMore = true;
    _error = null;
    await _fetch(reset: true);
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    _page++;
    await _fetch();
  }

  Future<void> _fetch({bool reset = false}) async {
    setState(() => _loading = true);
    try {
      final p = await _repo.services(status: widget.status, page: _page);
      if (!mounted) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(p.items);
        _hasMore = p.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(HmServicePackage s, bool published) async {
    try {
      hmToast(await _repo.setServicePublished(s.id, published));
      refreshAll();
    } catch (e) {
      hmToastError(e);
    }
  }

  Future<void> _delete(HmServicePackage s) async {
    try {
      hmToast(await _repo.deleteService(s.id));
      refreshAll();
    } catch (e) {
      hmToastError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return HmErrorView(message: hmErrorText(_error!), onRetry: _refresh);
    }
    return RefreshIndicator(
      color: MyTheme.navy,
      onRefresh: _refresh,
      child: _items.isEmpty
          ? HmEmptyView(
              text: "No ${widget.status.replaceAll('_', ' ')} services.",
              icon: Icons.handyman_outlined,
            )
          : ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _items.length + (_hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                if (i >= _items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final s = _items[i];
                return HmCard(
                  onTap: () async {
                    final saved = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HmServiceForm(service: s),
                      ),
                    );
                    if (saved == true) refreshAll();
                  },
                  child: Row(
                    children: [
                      HmNetImage(url: s.photo, size: 56),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: AppTheme.body(
                                size: 15,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "From ${hmMoney(s.fromPrice)} · ${s.estimatedTime}",
                              style: AppTheme.body(
                                size: 13,
                                color: MyTheme.navy,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: s.published,
                        onChanged: (v) => _toggle(s, v),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: MyTheme.red),
                        onPressed: () => _delete(s),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

