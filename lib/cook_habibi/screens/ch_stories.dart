import 'dart:io';

import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_api.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_models.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_repository.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// Stories from the last 7 days; live for 24 hours, max 10 live (guide §8).
class ChStories extends StatefulWidget {
  final int? liveCount;

  const ChStories({super.key, this.liveCount});

  @override
  State<ChStories> createState() => _ChStoriesState();
}

class _ChStoriesState extends State<ChStories> {
  final _repo = ChRepository();
  List<ChStory>? _items;
  int? _liveCount;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _liveCount = widget.liveCount;
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([
        _repo.stories(),
        _repo.dashboard().then<ChDashboard?>((d) => d).catchError((_) => null),
      ]);
      if (!mounted) return;
      setState(() {
        _items = r[0] as List<ChStory>;
        _liveCount = (r[1] as ChDashboard?)?.liveStories ??
            _items!.where((s) => s.isLive).length;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _openEditor({ChStory? story}) async {
    final saved = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => _StoryEditor(story: story)));
    if (saved == true) _load();
  }

  Future<void> _delete(ChStory s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete this story?"),
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
      chToast(await _repo.deleteStory(s.id));
      _load();
    } catch (e) {
      chToastError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final full = (_liveCount ?? 0) >= 10;
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: chAppBar(context, "Stories"),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: full ? MyTheme.grey_153 : MyTheme.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text("New story"),
        onPressed: () {
          if (full) {
            chToast("You can have up to 10 live stories");
            return;
          }
          _openEditor();
        },
      ),
      body: _items == null
          ? (_error != null
              ? ChErrorView(message: chErrorText(_error!), onRetry: _load)
              : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Text("${_liveCount ?? 0} of 10 live · each story lasts 24 hours",
                        style: AppTheme.body(
                            size: 13, color: MyTheme.medium_grey)),
                    const SizedBox(height: 12),
                    if (_items!.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Text("No stories in the last 7 days.",
                            textAlign: TextAlign.center,
                            style: AppTheme.body(
                                size: 14, color: MyTheme.medium_grey)),
                      ),
                    ..._items!.map(_tile),
                  ]),
            ),
    );
  }

  Widget _tile(ChStory s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ChCard(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          ChNetImage(url: s.imageUrl, size: 72, fallback: "📷"),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    s.isLive
                        ? ChPill("Live",
                            bg: const Color(0xFFE2F3EC), fg: MyTheme.green)
                        : const ChPill("Expired"),
                    const SizedBox(width: 8),
                    Text(chDateTime(s.createdAt),
                        style: AppTheme.body(
                            size: 12, color: MyTheme.medium_grey)),
                  ]),
                  const SizedBox(height: 6),
                  Text(s.caption.isEmpty ? "No caption" : s.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(size: 14)),
                  if (s.dishName != null)
                    Text("Dish: ${s.dishName}",
                        style: AppTheme.body(
                            size: 12, color: MyTheme.medium_grey)),
                ]),
          ),
          PopupMenuButton<String>(
            onSelected: (v) =>
                v == "edit" ? _openEditor(story: s) : _delete(s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: "edit", child: Text("Edit caption / dish")),
              PopupMenuItem(value: "delete", child: Text("Delete")),
            ],
          ),
        ]),
      ),
    );
  }
}

class _StoryEditor extends StatefulWidget {
  final ChStory? story;

  const _StoryEditor({this.story});

  @override
  State<_StoryEditor> createState() => _StoryEditorState();
}

class _StoryEditorState extends State<_StoryEditor> {
  final _repo = ChRepository();
  final _caption = TextEditingController();
  String? _localPath;
  int? _uploadId;
  int? _dishId;
  List<ChDish> _dishes = [];
  bool _saving = false;
  String? _key; // one idempotency key per "post" action

  bool get _isEdit => widget.story != null;

  @override
  void initState() {
    super.initState();
    _caption.text = widget.story?.caption ?? "";
    _dishId = widget.story?.dishId;
    _repo.dishes(status: "published").then((p) {
      if (mounted) setState(() => _dishes = p.items);
    }).catchError((_) {});
  }

  Future<void> _pick() async {
    final p = await chPickImage(context);
    if (p != null) {
      setState(() {
        _localPath = p;
        _uploadId = null;
        _key = null;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        chToast(await _repo.updateStory(widget.story!.id,
            caption: _caption.text.trim(), dishId: _dishId));
      } else {
        if (_localPath == null) {
          chToast("Pick a photo first.");
          return;
        }
        _uploadId ??= await _repo.upload(_localPath!);
        _key ??= ChApi.newIdempotencyKey();
        chToast(await _repo.postStory(
            uploadId: _uploadId!,
            caption: _caption.text.trim(),
            dishId: _dishId,
            idempotencyKey: _key!));
      }
      if (mounted) Navigator.pop(context, true);
    } on ChApiException catch (e) {
      if (e.status != 0) _key = null;
      chToast(e.message);
    } catch (e) {
      chToastError(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.story;
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: chAppBar(context, _isEdit ? "Edit story" : "New story"),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AspectRatio(
          aspectRatio: 9 / 12,
          child: InkWell(
            onTap: _isEdit ? null : _pick,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: MyTheme.hairline),
                  borderRadius: BorderRadius.circular(MyTheme.radius_card)),
              clipBehavior: Clip.antiAlias,
              child: _localPath != null
                  ? Image.file(File(_localPath!), fit: BoxFit.cover)
                  : (s?.imageUrl != null
                      ? Image.network(s!.imageUrl!, fit: BoxFit.cover)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Icon(Icons.add_a_photo_outlined,
                                  size: 40, color: MyTheme.navy),
                              SizedBox(height: 8),
                              Text("Tap to add a photo"),
                            ])),
            ),
          ),
        ),
        if (_isEdit)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text("The photo of a posted story can't be changed.",
                style: AppTheme.body(size: 12, color: MyTheme.medium_grey)),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _caption,
          maxLength: 200,
          maxLines: 3,
          decoration: chInput("Caption"),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int?>(
          value: _dishes.any((d) => d.id == _dishId) ? _dishId : null,
          decoration: chInput("Link a dish (optional)"),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text("No dish")),
            ..._dishes.map((d) => DropdownMenuItem<int?>(
                value: d.id, child: Text("${d.emoji} ${d.name}"))),
          ],
          onChanged: (v) => setState(() => _dishId = v),
        ),
        const SizedBox(height: 20),
        ChButton(
            label: _isEdit ? "Save" : "Post story",
            busy: _saving,
            onPressed: _save),
      ]),
    );
  }
}
