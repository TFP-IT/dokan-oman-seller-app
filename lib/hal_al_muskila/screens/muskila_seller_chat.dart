import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_models.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_ui.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

class MuskilaSellerChatScreen extends StatefulWidget {
  const MuskilaSellerChatScreen({super.key});

  @override
  State<MuskilaSellerChatScreen> createState() => _MuskilaSellerChatScreenState();
}

class _MuskilaSellerChatScreenState extends State<MuskilaSellerChatScreen> {
  List<MuskilaSellerThread> _threads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await MuskilaSellerApi.instance.getChatThreads();
    if (mounted) {
      setState(() {
        _threads = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: muskilaAppBar(context, "Messages"),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _threads.isEmpty
              ? const MuskilaEmptyView(text: "No messages yet.", icon: Icons.chat_bubble_outline)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _threads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final th = _threads[i];
                      return MuskilaCard(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MuskilaSellerConversationScreen(thread: th),
                            ),
                          );
                          _load();
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: MyTheme.blue_tint,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                th.customerName.isNotEmpty ? th.customerName[0] : "C",
                                style: AppTheme.body(size: 16, weight: FontWeight.w700, color: MyTheme.navy),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        th.customerName,
                                        style: AppTheme.body(size: 15, weight: FontWeight.w600, color: MyTheme.ink),
                                      ),
                                      Text(
                                        th.lastMessageTime,
                                        style: AppTheme.body(size: 11, color: MyTheme.medium_grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    th.serviceTitle,
                                    style: AppTheme.body(size: 12, weight: FontWeight.w500, color: MyTheme.navy),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    th.lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.body(size: 13, color: MyTheme.font_grey),
                                  ),
                                ],
                              ),
                            ),
                            if (th.unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: MyTheme.navy,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "${th.unreadCount}",
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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

class MuskilaSellerConversationScreen extends StatefulWidget {
  final MuskilaSellerThread thread;

  const MuskilaSellerConversationScreen({super.key, required this.thread});

  @override
  State<MuskilaSellerConversationScreen> createState() => _MuskilaSellerConversationScreenState();
}

class _MuskilaSellerConversationScreenState extends State<MuskilaSellerConversationScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<MuskilaSellerMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await MuskilaSellerApi.instance.getMessages(widget.thread.id);
    if (mounted) {
      setState(() {
        _messages = list;
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await MuskilaSellerApi.instance.sendMessage(threadId: widget.thread.id, text: text);
    _load();
  }

  void _showOfferDialog() {
    final ctrl = TextEditingController(text: "25");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MyTheme.radius_card)),
        title: Text("Send Custom Offer", style: AppTheme.body(size: 16, weight: FontWeight.w600, color: MyTheme.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Amount (OMR):", style: AppTheme.body(size: 13, color: MyTheme.dark_grey)),
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: "OMR ",
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(MyTheme.radius_control)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MyTheme.navy),
            onPressed: () async {
              final amount = double.tryParse(ctrl.text) ?? 25.0;
              Navigator.pop(ctx);
              await MuskilaSellerApi.instance.sendMessage(
                threadId: widget.thread.id,
                text: "Special Quote Offer: ${muskilaMoney(amount)} for the requested service.",
                isOffer: true,
                offerAmount: amount,
              );
              _load();
            },
            child: const Text("Send Offer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.paper,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: AppTheme.lightStatusBar,
        shape: const Border(bottom: BorderSide(color: MyTheme.hairline)),
        iconTheme: const IconThemeData(color: MyTheme.ink),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.thread.customerName,
                style: AppTheme.body(size: 16, weight: FontWeight.w600, color: MyTheme.ink)),
            Text(widget.thread.serviceTitle,
                style: AppTheme.body(size: 12, color: MyTheme.medium_grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.local_offer_outlined, color: MyTheme.amber),
            tooltip: "Send Custom Offer",
            onPressed: _showOfferDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return Align(
                        alignment: m.isFromSeller ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: m.isOffer
                                ? MyTheme.blue_tint
                                : m.isFromSeller
                                    ? MyTheme.navy
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(MyTheme.radius_card),
                            border: Border.all(
                              color: m.isOffer ? MyTheme.navy.withValues(alpha: 0.3) : MyTheme.hairline,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (m.isOffer) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified, size: 14, color: MyTheme.navy),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Pro Offer: ${muskilaMoney(m.offerAmount)}",
                                      style: AppTheme.body(
                                        size: 13,
                                        weight: FontWeight.w700,
                                        color: MyTheme.navy,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                m.text,
                                style: AppTheme.body(
                                  size: 14,
                                  color: m.isFromSeller && !m.isOffer ? Colors.white : MyTheme.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m.time,
                                style: AppTheme.body(
                                  size: 10,
                                  color: m.isFromSeller && !m.isOffer ? Colors.white70 : MyTheme.medium_grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: MyTheme.hairline)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: MyTheme.navy),
                    onPressed: _showOfferDialog,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: "Type reply to customer...",
                        isDense: true,
                        filled: true,
                        fillColor: MyTheme.paper,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: MyTheme.navy, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.send, size: 18, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
