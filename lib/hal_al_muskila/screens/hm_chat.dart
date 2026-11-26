import 'dart:async';

import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_repository.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// Bumped by `muskila_chat` / `muskila_offer` push; open chat for that thread reloads.
final ValueNotifier<String?> hmChatPushThreadId = ValueNotifier(null);

/// List of negotiation & booking chat threads.
class HmChatScreen extends StatefulWidget {
  const HmChatScreen({super.key});

  @override
  State<HmChatScreen> createState() => _HmChatScreenState();
}

class _HmChatScreenState extends State<HmChatScreen> {
  final _repo = HmRepository();
  final List<HmThread> _threads = [];
  bool _loading = true;
  Object? _error;

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
      final p = await _repo.threads();
      if (!mounted) return;
      setState(() {
        _threads
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: hmAppBar(context, "Messages"),
      body: _loading && _threads.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _threads.isEmpty
              ? HmErrorView(message: hmErrorText(_error!), onRetry: _load)
              : RefreshIndicator(
                  color: MyTheme.navy,
                  onRefresh: _load,
                  child: _threads.isEmpty
                      ? const HmEmptyView(
                          text: "No messages yet.",
                          icon: Icons.chat_bubble_outline,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _threads.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final t = _threads[i];
                            return HmCard(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HmThreadChat(
                                      threadId: t.id,
                                      thread: t,
                                      title: t.customerName,
                                      subtitle: t.serviceTitle,
                                    ),
                                  ),
                                );
                                _load();
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: MyTheme.blue_tint,
                                    child: Text(
                                      t.customerName.isNotEmpty
                                          ? t.customerName[0].toUpperCase()
                                          : "C",
                                      style: AppTheme.body(
                                        size: 16,
                                        weight: FontWeight.w700,
                                        color: MyTheme.navy,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                t.customerName,
                                                style: AppTheme.body(
                                                  size: 15,
                                                  weight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              t.lastMessageTime,
                                              style: AppTheme.body(
                                                size: 11,
                                                color: MyTheme.medium_grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                t.serviceTitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.body(
                                                  size: 12,
                                                  weight: FontWeight.w500,
                                                  color: MyTheme.navy,
                                                ),
                                              ),
                                            ),
                                            if (t.isEscrowLocked)
                                              const HmPill(
                                                "Escrow Locked",
                                                bg: Color(0xFFE2F3EC),
                                                fg: MyTheme.green,
                                              )
                                            else if (t.isAgreed)
                                              HmPill(
                                                "Agreed ${hmMoney(t.currentAgreedPrice)}",
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          t.lastMessage,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTheme.body(
                                            size: 13,
                                            color: MyTheme.font_grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (t.unreadCount > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: MyTheme.navy,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "${t.unreadCount}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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

/// Conversation screen mirroring `ChOrderChat` (reversed paginated list, 15s poll,
/// `hmChatPushThreadId`, `_sendKey` idempotency) + Offer Accept/Counter actions.
class HmThreadChat extends StatefulWidget {
  final String threadId;
  final HmThread? thread;
  final String? title;
  final String? subtitle;

  const HmThreadChat({
    super.key,
    required this.threadId,
    this.thread,
    this.title,
    this.subtitle,
  });

  @override
  State<HmThreadChat> createState() => _HmThreadChatState();
}

class _HmThreadChatState extends State<HmThreadChat> {
  static const int _maxLength = 1000;

  final _repo = HmRepository();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  final List<HmMessage> _messages = [];
  int _page = 1;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _chatOpen = true;
  bool _sending = false;
  Object? _error;
  Timer? _poll;

  String? _sendKey;
  String? _sendKeyText;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
    hmChatPushThreadId.addListener(_onPush);
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    hmChatPushThreadId.removeListener(_onPush);
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  void _onPush() {
    if (hmChatPushThreadId.value == widget.threadId) _refresh();
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
      final p = await _repo.messages(widget.threadId);
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

  Future<void> _refresh() async {
    if (_loading) return;
    try {
      final p = await _repo.messages(widget.threadId);
      if (!mounted) return;
      final known = _messages.map((m) => m.id).toSet();
      final fresh = p.items.where((m) => !known.contains(m.id)).toList();
      setState(() {
        _messages.insertAll(0, fresh);
        _chatOpen = p.chatOpen;
      });
      if (p.hasUnread || fresh.any((m) => !m.isMine)) _markRead(true);
    } catch (_) {}
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final p = await _repo.messages(widget.threadId, page: _page + 1);
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
      hmToastError(e);
    }
  }

  void _markRead(bool needed) {
    if (!needed) return;
    _repo.markThreadRead(widget.threadId).catchError((_) {});
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    if (text.length > _maxLength) {
      hmToast("A message can be up to $_maxLength characters.");
      return;
    }
    if (_sendKey == null || _sendKeyText != text) {
      _sendKey = HmApi.newIdempotencyKey();
      _sendKeyText = text;
    }
    setState(() => _sending = true);
    try {
      final msg = await _repo.sendMessage(
        widget.threadId,
        {"message": text},
        _sendKey!,
      );
      _sendKey = null;
      _sendKeyText = null;
      if (!mounted) return;
      _input.clear();
      setState(() {
        _messages.insert(0, msg);
        _sending = false;
      });
    } catch (e) {
      if (e is HmApiException && e.status != 0) {
        _sendKey = null;
        _sendKeyText = null;
      }
      if (mounted) setState(() => _sending = false);
      hmToastError(e);
    }
  }

  Future<void> _showOfferDialog({String? counterOfferId}) async {
    final amountCtrl = TextEditingController(
      text: (widget.thread?.currentAgreedPrice ?? 15.0).toStringAsFixed(3),
    );
    final noteCtrl = TextEditingController();
    HmMeta? meta;
    try {
      meta = await _repo.meta();
    } catch (_) {}
    if (!mounted) return;

    String? date = meta?.dates.firstOrNull?.date;
    String? slotId = meta?.slots.firstOrNull?.id;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(counterOfferId != null ? "Counter Offer" : "Send Offer"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: hmInput("Amount (OMR)"),
                ),
                if (meta != null && meta.dates.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: date,
                    decoration: hmInput("Date"),
                    items: meta.dates
                        .map((d) => DropdownMenuItem(
                            value: d.date, child: Text(d.label)))
                        .toList(),
                    onChanged: (v) => setD(() => date = v),
                  ),
                ],
                if (meta != null && meta.slots.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: slotId,
                    decoration: hmInput("Time Slot"),
                    items: meta.slots
                        .map((s) => DropdownMenuItem(
                            value: s.id, child: Text(s.label)))
                        .toList(),
                    onChanged: (v) => setD(() => slotId = v),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  decoration: hmInput("Note (optional)"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0) {
                  hmToast("Enter a valid amount.");
                  return;
                }
                Navigator.pop(ctx);
                final key = HmApi.newIdempotencyKey();
                try {
                  if (counterOfferId != null) {
                    hmToast(await _repo.counterOffer(
                      counterOfferId,
                      {
                        "amount": amount,
                        "date": date,
                        "slot_id": slotId,
                        "note": noteCtrl.text.trim(),
                      },
                      key,
                    ));
                  } else {
                    await _repo.sendMessage(
                      widget.threadId,
                      {
                        "message": noteCtrl.text.trim().isEmpty
                            ? "Pro Offer: ${hmMoney(amount)}"
                            : noteCtrl.text.trim(),
                        "is_offer": true,
                        "proposed_price": amount,
                        "date": date,
                        "slot_id": slotId,
                      },
                      key,
                    );
                  }
                  _load();
                } catch (e) {
                  hmToastError(e);
                }
              },
              child: const Text("Send"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptOffer(String offerId) async {
    try {
      hmToast(await _repo.acceptOffer(offerId, HmApi.newIdempotencyKey()));
      _load();
    } catch (e) {
      hmToastError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final th = widget.thread;
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: hmAppBar(
        context,
        widget.title ?? "Chat",
        actions: [
          if (_chatOpen)
            IconButton(
              tooltip: "Send Offer",
              icon: const Icon(Icons.local_offer_outlined, color: MyTheme.navy),
              onPressed: () => _showOfferDialog(),
            ),
        ],
      ),
      body: Column(
        children: [
          if (th != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: MyTheme.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          th.serviceTitle,
                          style: AppTheme.body(
                            size: 13,
                            weight: FontWeight.w600,
                          ),
                        ),
                        if (th.requestedTiming.isNotEmpty)
                          Text(
                            th.requestedTiming,
                            style: AppTheme.body(
                              size: 12,
                              color: MyTheme.medium_grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (th.currentAgreedPrice > 0)
                    HmPill(hmMoney(th.currentAgreedPrice)),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _messages.isEmpty
                    ? HmErrorView(message: hmErrorText(_error!), onRetry: _load)
                    : _messages.isEmpty
                        ? const HmEmptyView(
                            text: "No messages yet.",
                            icon: Icons.chat_bubble_outline,
                          )
                        : ListView.builder(
                            controller: _scroll,
                            reverse: true,
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                _messages.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i >= _messages.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }
                              final m = _messages[i];
                              return _MessageBubble(
                                message: m,
                                onAccept: m.offerId != null
                                    ? () => _acceptOffer(m.offerId!)
                                    : null,
                                onCounter: m.offerId != null
                                    ? () => _showOfferDialog(
                                        counterOfferId: m.offerId)
                                    : null,
                              );
                            },
                          ),
          ),
          if (_chatOpen)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: MyTheme.hairline)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.local_offer_outlined,
                          color: MyTheme.navy),
                      onPressed: () => _showOfferDialog(),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _input,
                        maxLength: _maxLength,
                        buildCounter: (_,
                                {required currentLength,
                                required isFocused,
                                maxLength}) =>
                            null,
                        decoration: hmInput("Write a message..."),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: MyTheme.navy,
                        minimumSize: const Size(44, 44),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: _sending ? null : _send,
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: Text(
                "This conversation is closed.",
                textAlign: TextAlign.center,
                style: AppTheme.body(size: 13, color: MyTheme.medium_grey),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final HmMessage message;
  final VoidCallback? onAccept;
  final VoidCallback? onCounter;

  const _MessageBubble({
    required this.message,
    this.onAccept,
    this.onCounter,
  });

  @override
  Widget build(BuildContext context) {
    final m = message;
    final canRespondOffer =
        m.isOffer && !m.isMine && m.offerId != null && m.isAccepted == null;
    return Align(
      alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: m.isOffer
              ? MyTheme.blue_tint
              : (m.isMine ? MyTheme.navy : Colors.white),
          borderRadius: BorderRadius.circular(MyTheme.radius_card),
          border: Border.all(
            color: m.isOffer
                ? MyTheme.navy.withValues(alpha: 0.3)
                : MyTheme.hairline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.isOffer && m.proposedPrice != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_offer_rounded,
                      size: 14, color: MyTheme.navy),
                  const SizedBox(width: 4),
                  Text(
                    "Offer: ${hmMoney(m.proposedPrice)}",
                    style: AppTheme.body(
                      size: 13,
                      weight: FontWeight.w700,
                      color: MyTheme.navy,
                    ),
                  ),
                ],
              ),
              if (m.date != null || m.slotLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    [m.date, m.slotLabel]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(" · "),
                    style: AppTheme.body(size: 11.5, color: MyTheme.dark_grey),
                  ),
                ),
              const SizedBox(height: 4),
            ],
            Text(
              m.text,
              style: AppTheme.body(
                size: 14,
                color: m.isMine && !m.isOffer ? Colors.white : MyTheme.ink,
              ),
            ),
            if (m.isAccepted != null) ...[
              const SizedBox(height: 6),
              HmPill.status(
                m.isAccepted! ? "accepted" : "rejected",
                m.isAccepted! ? "Accepted" : "Countered",
              ),
            ],
            if (canRespondOffer) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: MyTheme.green,
                      minimumSize: const Size(76, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: onAccept,
                    child: const Text("Accept", style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(76, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: onCounter,
                    child: const Text("Counter", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              m.timeText,
              style: AppTheme.body(
                size: 10,
                color: m.isMine && !m.isOffer
                    ? Colors.white70
                    : MyTheme.medium_grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

