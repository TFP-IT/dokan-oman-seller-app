import 'dart:io';

import 'package:active_ecommerce_seller_app/cook_habibi/ch_api.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_models.dart';

/// Every Cook Habibi seller endpoint from the developer guide.
class ChRepository {
  // ---- helpers --------------------------------------------------------------

  Map<String, dynamic> _data(dynamic res) => chMap(chMap(res)["data"]);

  String _message(dynamic res, String fallback) =>
      chStr(chMap(res)["message"]) ?? fallback;

  ChPage<T> _page<T>(dynamic res, T Function(Map<String, dynamic>) parse) {
    final m = chMap(res);
    final list = m["data"] is List ? m["data"] as List : const [];
    final meta = chMap(m["meta"]);
    final current = chInt(meta["current_page"]) ?? 1;
    final last = chInt(meta["last_page"]) ?? current;
    return ChPage(list.map((e) => parse(chMap(e))).toList(), current, last);
  }

  // ---- device (§3.2) --------------------------------------------------------

  Future<void> registerDevice(String token) => ChApi.post(
      ChApi.seller("device"),
      body: {
        "device_token": token,
        "device_type": Platform.isIOS ? "ios" : "android",
      });

  Future<void> removeDevice() => ChApi.delete(ChApi.seller("device"));

  // ---- application (§4) -----------------------------------------------------

  /// Public. [fields] and [files] follow `cook_habibi_api.md` §17.
  Future<String> apply(
      {required Map<String, String> fields,
      Map<String, String> files = const {}}) async {
    final res = await ChApi.multipart(ChApi.url("cook-habibi/apply"),
        fields: fields, files: files, auth: false);
    return _message(res, "Application sent.");
  }

  Future<ChApplication> application() async =>
      ChApplication.fromJson(_data(await ChApi.get(ChApi.seller("application"))));

  Future<ChApplication> resubmit(String idempotencyKey,
      {Map<String, dynamic> body = const {}}) async {
    final res = await ChApi.post(ChApi.seller("application/resubmit"),
        body: body, idempotencyKey: idempotencyKey);
    return ChApplication.fromJson(_data(res));
  }

  // ---- kitchen (§5) ---------------------------------------------------------

  Future<ChProfile> profile() async =>
      ChProfile.fromJson(_data(await ChApi.get(ChApi.seller("profile"))));

  /// Partial update: send only changed fields.
  Future<ChProfile> updateProfile(Map<String, dynamic> changes) async {
    final res = await ChApi.put(ChApi.seller("profile"), body: changes);
    final d = _data(res);
    return d.isEmpty ? await profile() : ChProfile.fromJson(d);
  }

  Future<String> updateSchedule(Map<String, List<String>?> hours) async {
    final res = await ChApi.put(ChApi.seller("schedule"),
        body: {"working_hours": hours});
    return _message(res, "Hours saved.");
  }

  Future<String> setOpen(bool open) async {
    final res = await ChApi.post(ChApi.seller(open ? "open" : "close"));
    return _message(res, open ? "Kitchen open." : "Kitchen closed.");
  }

  /// Image up to 5 MB. Returns the `upload_id`.
  Future<int> upload(String filePath) async {
    final res = await ChApi.multipart(ChApi.seller("uploads"),
        files: {"file": filePath});
    final d = _data(res);
    final id = chInt(d["upload_id"] ?? d["id"] ?? chMap(res)["upload_id"]);
    if (id == null) throw ChApiException(0, "Upload failed. Please try again.");
    return id;
  }

  // ---- orders (§6) ----------------------------------------------------------

  Future<ChPage<ChOrder>> orders(
      {String tab = "active", String? status, int page = 1}) async {
    final q = StringBuffer("orders?tab=$tab&page=$page");
    if (status != null && status.isNotEmpty) q.write("&status=$status");
    return _page(await ChApi.get(ChApi.seller(q.toString())), ChOrder.fromJson);
  }

  Future<ChOrder> order(int id) async =>
      ChOrder.fromJson(_data(await ChApi.get(ChApi.seller("orders/$id"))));

  /// [action] is one of `next_actions`: accept, preparing, ready,
  /// out-for-delivery, handover, reject.
  Future<({String message, ChOrder? order})> orderAction(
      int id, String action, String idempotencyKey,
      {Map<String, dynamic>? body}) async {
    final res = await ChApi.post(ChApi.seller("orders/$id/$action"),
        body: body, idempotencyKey: idempotencyKey);
    final d = _data(res);
    return (
      message: _message(res, "Order updated."),
      order: d.isEmpty ? null : ChOrder.fromJson(d),
    );
  }

  // ---- dishes (§7) ----------------------------------------------------------

  Future<ChPage<ChDish>> dishes({String? status, int page = 1}) async {
    final q = StringBuffer("dishes?page=$page");
    if (status != null) q.write("&status=$status");
    return _page(await ChApi.get(ChApi.seller(q.toString())), ChDish.fromJson);
  }

  Future<ChDish> dish(int id) async =>
      ChDish.fromJson(_data(await ChApi.get(ChApi.seller("dishes/$id"))));

  Future<String> createDish(Map<String, dynamic> body) async =>
      _message(await ChApi.post(ChApi.seller("dishes"), body: body),
          "Dish saved.");

  Future<String> updateDish(int id, Map<String, dynamic> changes) async =>
      _message(await ChApi.put(ChApi.seller("dishes/$id"), body: changes),
          "Dish saved.");

  Future<String> setDishPublished(int id, bool published) async => _message(
      await ChApi.post(ChApi.seller("dishes/$id/status"),
          body: {"published": published}),
      published ? "Dish is visible." : "Dish is hidden.");

  Future<String> setDishCapacity(int id, int capacity) async => _message(
      await ChApi.put(ChApi.seller("dishes/$id/capacity"),
          body: {"daily_capacity": capacity}),
      "Portions saved.");

  Future<String> deleteDish(int id) async =>
      _message(await ChApi.delete(ChApi.seller("dishes/$id")), "Dish deleted.");

  // ---- stories (§8) ---------------------------------------------------------

  Future<List<ChStory>> stories() async {
    final res = await ChApi.get(ChApi.seller("stories"));
    final d = chMap(res)["data"];
    return d is List ? d.map((e) => ChStory.fromJson(chMap(e))).toList() : [];
  }

  Future<String> postStory(
          {required int uploadId,
          String? caption,
          int? dishId,
          required String idempotencyKey}) async =>
      _message(
          await ChApi.post(ChApi.seller("stories"),
              body: {
                "upload_id": uploadId,
                if (caption != null && caption.isNotEmpty) "caption": caption,
                if (dishId != null) "dish_id": dishId,
              },
              idempotencyKey: idempotencyKey),
          "Story posted.");

  Future<String> updateStory(int id, {String? caption, int? dishId}) async =>
      _message(
          await ChApi.put(ChApi.seller("stories/$id"), body: {
            if (caption != null) "caption": caption,
            if (dishId != null) "dish_id": dishId,
          }),
          "Story saved.");

  Future<String> deleteStory(int id) async => _message(
      await ChApi.delete(ChApi.seller("stories/$id")), "Story deleted.");

  // ---- order chat (§9b) -----------------------------------------------------

  /// Newest first. `chat_open` is false once the order is finished.
  Future<ChMessagePage> messages(int orderId, {int page = 1}) async {
    final m = chMap(
        await ChApi.get(ChApi.seller("orders/$orderId/messages?page=$page")));
    final list = m["data"] is List ? m["data"] as List : const [];
    final meta = chMap(m["meta"]);
    final current = chInt(meta["current_page"]) ?? 1;
    final last = chInt(meta["last_page"]) ?? current;
    return ChMessagePage(
      list.map((e) => ChMessage.fromJson(chMap(e))).toList(),
      current,
      last,
      chatOpen: chBool(m["chat_open"] ?? meta["chat_open"], true),
      hasUnread: chBool(m["has_unread"] ?? meta["has_unread"]),
    );
  }

  /// 1 to 1000 characters. Returns the sent message when the server sends it.
  Future<ChMessage?> sendMessage(
      int orderId, String text, String idempotencyKey) async {
    final res = await ChApi.post(ChApi.seller("orders/$orderId/messages"),
        body: {"message": text}, idempotencyKey: idempotencyKey);
    final d = _data(res);
    return d.isEmpty ? null : ChMessage.fromJson(d);
  }

  Future<void> markMessagesRead(int orderId) =>
      ChApi.post(ChApi.seller("orders/$orderId/messages/read"));

  // ---- money (§9) -----------------------------------------------------------

  Future<ChDashboard> dashboard() async =>
      ChDashboard.fromJson(_data(await ChApi.get(ChApi.seller("dashboard"))));

  Future<ChEarnings> earnings() async =>
      ChEarnings.fromJson(_data(await ChApi.get(ChApi.seller("earnings"))));
}
