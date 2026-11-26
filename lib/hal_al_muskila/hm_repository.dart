import 'dart:io';

import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_api.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_models.dart';

/// Every Hal Al Mushkila Seller endpoint from HAL_AL_MUSKILA_SELLER_BACKEND_API_SPEC.md.
class HmRepository {
  Map<String, dynamic> _data(dynamic res) => hmMap(hmMap(res)["data"]);

  String _message(dynamic res, String fallback) =>
      hmStr(hmMap(res)["message"]) ?? fallback;

  HmPage<T> _page<T>(dynamic res, T Function(Map<String, dynamic>) parse) {
    final m = hmMap(res);
    final list = m["data"] is List ? m["data"] as List : const [];
    final meta = hmMap(m["meta"]);
    final current = hmInt(meta["current_page"]) ?? 1;
    final last = hmInt(meta["last_page"]) ?? current;
    return HmPage(list.map((e) => parse(hmMap(e))).toList(), current, last);
  }

  // ---- shared meta & uploads ------------------------------------------------

  Future<HmMeta> meta() async =>
      HmMeta.fromJson(_data(await HmApi.get(HmApi.url("muskila/meta"), auth: false)));

  Future<({int uploadId, String url})> upload(
    String filePath, {
    String type = "service_photo",
  }) async {
    final res = await HmApi.multipart(
      HmApi.seller("uploads"),
      fields: {"type": type},
      files: {"file": filePath},
    );
    final d = _data(res);
    final id = hmInt(d["upload_id"] ?? d["id"] ?? hmMap(res)["upload_id"]);
    if (id == null) throw HmApiException(0, "Upload failed. Please try again.");
    return (uploadId: id, url: hmStr(d["url"]) ?? "");
  }

  // ---- device ---------------------------------------------------------------

  Future<void> registerDevice(String token) => HmApi.post(
        HmApi.seller("device"),
        body: {
          "device_token": token,
          "device_type": Platform.isIOS ? "ios" : "android",
        },
      );

  Future<void> removeDevice() => HmApi.delete(HmApi.seller("device"));

  // ---- application gate -----------------------------------------------------

  Future<HmApplication> application({bool signOutOnAuthError = true}) async =>
      HmApplication.fromJson(_data(await HmApi.get(
        HmApi.seller("application"),
        signOutOnAuthError: signOutOnAuthError,
      )));

  Future<HmApplication> resubmit(String idempotencyKey) async {
    final res = await HmApi.post(
      HmApi.seller("application/resubmit"),
      idempotencyKey: idempotencyKey,
    );
    return HmApplication.fromJson(_data(res));
  }

  // ---- dashboard & availability ---------------------------------------------

  Future<HmDashboard> dashboard({bool signOutOnAuthError = true}) async =>
      HmDashboard.fromJson(_data(await HmApi.get(
        HmApi.seller("dashboard"),
        signOutOnAuthError: signOutOnAuthError,
      )));

  Future<String> setOnline(bool online) async {
    final res = await HmApi.post(
      HmApi.seller("availability"),
      body: {"is_online": online},
    );
    return _message(res, online ? "You are now online." : "Availability paused.");
  }

  // ---- instant requests -----------------------------------------------------

  Future<List<HmInstantRequest>> instantRequests() async {
    final res = await HmApi.get(HmApi.seller("instant-requests"));
    return hmMapList(hmMap(res)["data"]).map(HmInstantRequest.fromJson).toList();
  }

  Future<HmBooking> acceptInstant(String id, String idempotencyKey) async {
    final res = await HmApi.post(
      HmApi.seller("instant-requests/$id/accept"),
      idempotencyKey: idempotencyKey,
    );
    final d = _data(res);
    return HmBooking.fromJson(d["booking"] is Map ? hmMap(d["booking"]) : d);
  }

  Future<String> declineInstant(String id, {String reason = ""}) async {
    final res = await HmApi.post(
      HmApi.seller("instant-requests/$id/decline"),
      body: reason.isEmpty ? {} : {"reason": reason},
    );
    return _message(res, "Request declined.");
  }

  // ---- bookings -------------------------------------------------------------

  Future<HmPage<HmBooking>> bookings({String tab = "active", int page = 1}) async =>
      _page(
        await HmApi.get(HmApi.seller("bookings?tab=$tab&page=$page")),
        HmBooking.fromJson,
      );

  Future<HmBooking> booking(String id) async =>
      HmBooking.fromJson(_data(await HmApi.get(HmApi.seller("bookings/$id"))));

  Future<({String message, HmBooking? booking})> bookingAction(
    String id,
    String action,
    String idempotencyKey, {
    Map<String, dynamic>? body,
  }) async {
    final res = await HmApi.post(
      HmApi.seller("bookings/$id/$action"),
      body: body,
      idempotencyKey: idempotencyKey,
    );
    final d = _data(res);
    final bMap = d["booking"] is Map ? hmMap(d["booking"]) : d;
    return (
      message: _message(res, "Booking updated."),
      booking: bMap.isEmpty ? null : HmBooking.fromJson(bMap),
    );
  }

  Future<void> updateBookingLocation(
    String id, {
    required double lat,
    required double lng,
    required int etaMinutes,
  }) =>
      HmApi.post(
        HmApi.seller("bookings/$id/location"),
        body: {"lat": lat, "lng": lng, "eta_minutes": etaMinutes},
      );

  Future<String> callBooking(String id) async =>
      hmStr(_data(await HmApi.post(HmApi.seller("bookings/$id/call")))["phone"]) ??
      "";

  // ---- job leads, quotes & expert posts -------------------------------------

  Future<HmPage<HmJobLead>> jobLeads({String filter = "all", int page = 1}) async =>
      _page(
        await HmApi.get(HmApi.seller("job-leads?filter=$filter&page=$page")),
        HmJobLead.fromJson,
      );

  Future<HmPage<HmQuote>> quotes({int page = 1}) async => _page(
        await HmApi.get(HmApi.seller("quotes?page=$page")),
        HmQuote.fromJson,
      );

  Future<String> submitQuote(
    Map<String, dynamic> body,
    String idempotencyKey,
  ) async =>
      _message(
        await HmApi.post(
          HmApi.seller("quotes"),
          body: body,
          idempotencyKey: idempotencyKey,
        ),
        "Quote submitted to customer.",
      );

  Future<String> updateQuote(String id, Map<String, dynamic> body) async =>
      _message(
        await HmApi.put(HmApi.seller("quotes/$id"), body: body),
        "Quote updated.",
      );

  Future<String> withdrawQuote(String id) async => _message(
        await HmApi.delete(HmApi.seller("quotes/$id")),
        "Quote withdrawn.",
      );

  Future<HmPage<HmExpertPost>> expertPosts({int page = 1}) async => _page(
        await HmApi.get(HmApi.seller("posts?page=$page")),
        HmExpertPost.fromJson,
      );

  Future<String> createExpertPost(
    Map<String, dynamic> body,
    String idempotencyKey,
  ) async =>
      _message(
        await HmApi.post(
          HmApi.seller("posts"),
          body: body,
          idempotencyKey: idempotencyKey,
        ),
        "Post published.",
      );

  Future<String> updateExpertPost(String id, Map<String, dynamic> body) async =>
      _message(
        await HmApi.put(HmApi.seller("posts/$id"), body: body),
        "Post updated.",
      );

  Future<String> deleteExpertPost(String id) async => _message(
        await HmApi.delete(HmApi.seller("posts/$id")),
        "Post deleted.",
      );

  // ---- services catalog -----------------------------------------------------

  Future<HmPage<HmServicePackage>> services({
    String status = "published",
    int page = 1,
  }) async =>
      _page(
        await HmApi.get(HmApi.seller("services?status=$status&page=$page")),
        HmServicePackage.fromJson,
      );

  Future<String> createService(Map<String, dynamic> body) async => _message(
        await HmApi.post(HmApi.seller("services"), body: body),
        "Service saved.",
      );

  Future<String> updateService(String id, Map<String, dynamic> body) async =>
      _message(
        await HmApi.put(HmApi.seller("services/$id"), body: body),
        "Service updated.",
      );

  Future<String> setServicePublished(String id, bool published) async =>
      _message(
        await HmApi.post(
          HmApi.seller("services/$id/status"),
          body: {"published": published},
        ),
        published ? "Service is visible." : "Service is hidden.",
      );

  Future<String> deleteService(String id) async => _message(
        await HmApi.delete(HmApi.seller("services/$id")),
        "Service deleted.",
      );

  // ---- chat & offers --------------------------------------------------------

  Future<HmPage<HmThread>> threads({int page = 1}) async => _page(
        await HmApi.get(HmApi.seller("chat/threads?page=$page")),
        HmThread.fromJson,
      );

  Future<HmMessagePage> messages(String threadId, {int page = 1}) async {
    final res =
        await HmApi.get(HmApi.seller("chat/threads/$threadId/messages?page=$page"));
    final m = hmMap(res);
    final list = m["data"] is List ? m["data"] as List : const [];
    final meta = hmMap(m["meta"]);
    final current = hmInt(meta["current_page"]) ?? 1;
    final last = hmInt(meta["last_page"]) ?? current;
    return HmMessagePage(
      list.map((e) => HmMessage.fromJson(hmMap(e))).toList(),
      current,
      last,
      chatOpen: hmBool(m["chat_open"], true),
      hasUnread: hmBool(m["has_unread"]),
    );
  }

  Future<HmMessage> sendMessage(
    String threadId,
    Map<String, dynamic> body,
    String idempotencyKey,
  ) async {
    final res = await HmApi.post(
      HmApi.seller("chat/threads/$threadId/messages"),
      body: body,
      idempotencyKey: idempotencyKey,
    );
    final d = _data(res);
    return HmMessage.fromJson(d["message"] is Map ? hmMap(d["message"]) : d);
  }

  Future<void> markThreadRead(String threadId) =>
      HmApi.post(HmApi.seller("chat/threads/$threadId/read"));

  Future<String> acceptOffer(String offerId, String idempotencyKey) async =>
      _message(
        await HmApi.post(
          HmApi.seller("offers/$offerId/accept"),
          idempotencyKey: idempotencyKey,
        ),
        "Offer accepted.",
      );

  Future<String> counterOffer(
    String offerId,
    Map<String, dynamic> body,
    String idempotencyKey,
  ) async =>
      _message(
        await HmApi.post(
          HmApi.seller("offers/$offerId/counter"),
          body: body,
          idempotencyKey: idempotencyKey,
        ),
        "Counter offer sent.",
      );

  // ---- profile, schedule, location, reviews, earnings, notifications --------

  Future<HmProfile> profile() async =>
      HmProfile.fromJson(_data(await HmApi.get(HmApi.seller("profile"))));

  Future<HmProfile> updateProfile(Map<String, dynamic> changes) async {
    final res = await HmApi.put(HmApi.seller("profile"), body: changes);
    final d = _data(res);
    return d.isEmpty ? await profile() : HmProfile.fromJson(d);
  }

  Future<String> updateSchedule(Map<String, dynamic> workingSchedule) async =>
      _message(
        await HmApi.put(
          HmApi.seller("schedule"),
          body: {"working_schedule": workingSchedule},
        ),
        "Schedule saved.",
      );

  Future<String> updateLocation(Map<String, dynamic> body) async => _message(
        await HmApi.put(HmApi.seller("location"), body: body),
        "Location saved.",
      );

  Future<HmPage<HmReview>> reviews({int page = 1}) async => _page(
        await HmApi.get(HmApi.seller("reviews?page=$page")),
        HmReview.fromJson,
      );

  Future<HmEarnings> earnings() async =>
      HmEarnings.fromJson(_data(await HmApi.get(HmApi.seller("earnings"))));

  Future<HmPage<HmNotification>> notifications({int page = 1}) async => _page(
        await HmApi.get(HmApi.seller("notifications?page=$page")),
        HmNotification.fromJson,
      );

  Future<void> markAllNotificationsRead() =>
      HmApi.post(HmApi.seller("notifications/read-all"));
}

