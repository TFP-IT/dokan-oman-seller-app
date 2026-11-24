import 'dart:async';

import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_api.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_models.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_repository.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// Bumped by a `cook_habibi_chat` push; the open chat for that order reloads.
final ValueNotifier<int?> chChatPushOrderId = ValueNotifier(null);

/// Chat with the customer for one order (guide §9b).
class ChOrderChat extends StatefulWidget {
  final int orderId;
  final String? title;

  const ChOrderChat({super.key, required this.orderId, this.title});

  @override
  State<ChOrderChat> createState() => _ChOrderChatState();
}

class _ChOrderChatState extends State<ChOrderChat> {
  static const int _maxLength = 1000;

  final _repo = ChRepository();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  /// Newest first (index 0 sits at the bottom of the reversed list).
  final List<ChMessage> _messages = [];
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _chatOpen = true;
  bool _sending = false;
  Object? _error;
  Timer? _poll;

  /// Kept until the send succeeds, so a retry is not sent twice.
  String? _sendKey;
  String? _sendKeyText;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
    chChatPushOrderId.addListener(_onPush);
    // pushes are best-effort, so also check for new messages now and then
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    chChatPushOrderId.removeListener(_onPush);
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  void _onPush() {
    if (chChatPushOrderId.value == widget.orderId) _refresh();
  }

  void _onScroll() {
    if (_hasMore &&
        !_loadingMore &&
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await _repo.messages(widget.orderId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(p.items);
        _page = p.currentPage;
        _hasMore = p.hasMore;
        _chatOpen = p.chatOpen;
        _loading = false;
      });
      _markRead(p.hasUnread || p.items.any((m) => !m.isMine));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// Reloads the first page and merges it in, keeping older pages.
  Future<void> _refresh({bool showError = false}) async {
    if (_loading) return;
    try {
      final p = await _repo.messages(widget.orderId);
      if (!mounted) return;
      final known = _messages.map((m) => m.id).toSet();
      final fresh = p.items.where((m) => !known.contains(m.id)).toList();
      setState(() {
        _messages.insertAll(0, fresh);
        _chatOpen = p.chatOpen;
      });
      if (p.hasUnread || fresh.any((m) => !m.isMine)) _markRead(true);
    } catch (e) {
      // quiet for polls/pushes: the next poll tries again
      if (showError && mounted) chToastError(e);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final p = await _repo.messages(widget.orderId, page: _page + 1);
      if (!mounted) return;
      final known = _messages.map((m) => m.id).toSet();
      setState(() {
        _messages.addAll(p.items.where((m) => !known.contains(m.id)));
        _page = p.currentPage;
        _hasMore = p.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      chToastError(e);
    }
  }

  void _markRead(bool needed) {
    if (!needed) return;
    _repo.markMessagesRead(widget.orderId).catchError((_) {});
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    if (text.length > _maxLength) {
      chToast("A message can be up to $_maxLength characters.");
      return;
    }
    if (_sendKey == null || _sendKeyText != text) {
      _sendKey = ChApi.newIdempotencyKey();
      _sendKeyText = text;
    }
    setState(() => _sending = true);
    try {
      final sent = await _repo.sendMessage(widget.orderId, text, _sendKey!);
      if (!mounted) return;
      _sendKey = null;
      _sendKeyText = null;
      _input.clear();
      setState(() {
        _sending = false;
        if (sent != null && !_messages.any((m) => m.id == sent.id)) {
          _messages.insert(0, sent);
        }
      });
      if (sent == null) await _refresh();
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } on ChApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      // a 422 usually means the order just finished: show it read-only
      if (e.status == 422) _refresh();
      chToast(e.fieldError("message") ?? e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      chToastError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: chAppBar(context, widget.title ?? "Chat with customer"),
      body: Column(
        children: [
          Expanded(child: _body()),
          if (!_loading && _error == null)
            _chatOpen ? _composer() : _closedBar(),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ChErrorView(message: chErrorText(_error!), onRetry: _load);
    }
    if (_messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _refresh(showError: true),
        child: ChEmptyView(
          text:
              _chatOpen
                  ? "No messages yet. Say hello to your customer."
                  : "No messages for this order.",
          icon: Icons.chat_bubble_outline_rounded,
        ),
      );
    }
    // reversed list: pulling down at the top (oldest loaded) refreshes
    return RefreshIndicator(
      onRefresh: () => _refresh(showError: true),
      child: ListView.builder(
        controller: _scroll,
        reverse: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        itemCount: _messages.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _messages.length) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _bubble(_messages[i]);
        },
      ),
    );
  }

  Widget _bubble(ChMessage m) {
    final mine = m.isMine;
    return Align(
      alignment:
          mine
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration: BoxDecoration(
            color: mine ? MyTheme.navy : Colors.white,
            border: mine ? null : Border.all(color: MyTheme.hairline),
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(16),
              topEnd: const Radius.circular(16),
              bottomStart: Radius.circular(mine ? 16 : 4),
              bottomEnd: Radius.circular(mine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              SelectableText(
                m.text,
                style: AppTheme.body(
                  size: 14,
                  color: mine ? Colors.white : MyTheme.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                chDateTime(m.createdAt),
                style: AppTheme.body(
                  size: 11,
                  color:
                      mine
                          ? Colors.white.withValues(alpha: 0.7)
                          : MyTheme.medium_grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: MyTheme.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: _maxLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: chInput(
                    "",
                    hint: "Write a message",
                  ).copyWith(labelText: null, counterText: ""),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                style: IconButton.styleFrom(backgroundColor: MyTheme.navy),
                icon:
                    _sending
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _closedBar() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            "This order is finished. The chat is read-only.",
            textAlign: TextAlign.center,
            style: AppTheme.body(size: 13, color: MyTheme.medium_grey),
          ),
        ),
      ),
    );
  }
}
