import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_api.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_models.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_repository.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_ui.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/screens/ch_dish_form.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dish list with tabs by status (guide §7).
class ChDishes extends StatelessWidget {
  const ChDishes({super.key});

  static const _tabs = [
    ("published", "Published"),
    ("hidden", "Hidden"),
    ("pending_approval", "Waiting approval"),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: MyTheme.paper,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            iconTheme: const IconThemeData(color: MyTheme.ink),
            title: Text("Dishes",
                style: AppTheme.body(
                    size: 18, weight: FontWeight.w600, color: MyTheme.ink)),
            bottom: TabBar(
              isScrollable: true,
              labelColor: MyTheme.navy,
              indicatorColor: MyTheme.navy,
              tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: MyTheme.navy,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text("New dish"),
            onPressed: () async {
              final saved = await Navigator.push<bool>(context,
                  MaterialPageRoute(builder: (_) => const ChDishForm()));
              if (saved == true) _DishListState.refreshAll();
            },
          ),
          body: TabBarView(
              children: _tabs.map((t) => _DishList(status: t.$1)).toList()),
        );
      }),
    );
  }
}

class _DishList extends StatefulWidget {
  final String status;

  const _DishList({required this.status});

  @override
  State<_DishList> createState() => _DishListState();
}

class _DishListState extends State<_DishList>
    with AutomaticKeepAliveClientMixin {
  static final Set<_DishListState> _live = {};

  static void refreshAll() {
    for (final s in _live.toList()) {
      s._refresh();
    }
  }

  final _repo = ChRepository();
  final _scroll = ScrollController();
  final List<ChDish> _items = [];
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
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final p = await _repo.dishes(status: widget.status, page: _page);
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

  Future<void> _togglePublished(ChDish d) async {
    try {
      chToast(await _repo.setDishPublished(d.id, !d.published));
      refreshAll();
    } catch (e) {
      chToastError(e);
    }
  }

  Future<void> _capacity(ChDish d) async {
    final c = TextEditingController(text: d.dailyCapacity?.toString() ?? "");
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Today's portions"),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: chInput("Portions available today"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, int.tryParse(c.text)),
              child: const Text("Save")),
        ],
      ),
    );
    if (value == null) return;
    try {
      chToast(await _repo.setDishCapacity(d.id, value));
      _refresh();
    } catch (e) {
      chToastError(e);
    }
  }

  Future<void> _delete(ChDish d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete ${d.name}?"),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: MyTheme.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Delete")),
        ],
      ),
    );
    if (ok != true) return;
    try {
      chToast(await _repo.deleteDish(d.id));
      refreshAll();
    } on ChApiException catch (e) {
      if (e.status == 422 && d.published) {
        // a dish with orders cannot be deleted: offer hide instead
        if (!mounted) return;
        final hide = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(
                "${e.message}\n\nYou can hide it so customers don't see it."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("Close")),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("Hide dish")),
            ],
          ),
        );
        if (hide == true) _togglePublished(d);
      } else {
        chToast(e.message);
      }
    } catch (e) {
      chToastError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty && _error != null) {
      return ChErrorView(message: chErrorText(_error!), onRetry: _refresh);
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _items.isEmpty
          ? ChEmptyView(
              text: widget.status == "pending_approval"
                  ? "No dishes waiting for approval."
                  : "No dishes here yet.",
              icon: Icons.restaurant_menu_outlined)
          : ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _items.length + (_hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i >= _items.length) {
                  return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(child: CircularProgressIndicator()));
                }
                return _tile(_items[i]);
              },
            ),
    );
  }

  Widget _tile(ChDish d) {
    return ChCard(
      onTap: () async {
        final saved = await Navigator.push<bool>(context,
            MaterialPageRoute(builder: (_) => ChDishForm(dishId: d.id)));
        if (saved == true) refreshAll();
      },
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        ChNetImage(url: d.thumbnailUrl, fallback: d.emoji),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body(
                    size: 15, weight: FontWeight.w600, color: MyTheme.ink)),
            const SizedBox(height: 2),
            Text(
                "${chMoney(d.price)}"
                "${d.discountPercent > 0 ? "  ·  -${d.discountPercent.toStringAsFixed(0)}%" : ""}",
                style: AppTheme.body(size: 13)),
            const SizedBox(height: 2),
            Text(
                d.dailyCapacity == null
                    ? "No portion limit"
                    : "${d.dailyCapacity} portions today",
                style: AppTheme.body(size: 12, color: MyTheme.medium_grey)),
            if (d.pendingApproval)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text("Customers can't see it until admin approves.",
                    style: AppTheme.body(size: 12, color: MyTheme.amber_ink)),
              ),
          ]),
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case "toggle":
                _togglePublished(d);
                break;
              case "capacity":
                _capacity(d);
                break;
              case "delete":
                _delete(d);
                break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
                value: "toggle", child: Text(d.published ? "Hide" : "Show")),
            const PopupMenuItem(
                value: "capacity", child: Text("Today's portions")),
            const PopupMenuItem(value: "delete", child: Text("Delete")),
          ],
        ),
      ]),
    );
  }
}
