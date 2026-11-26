import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:active_ecommerce_seller_app/app_config.dart';
import 'package:active_ecommerce_seller_app/helpers/auth_helper.dart';
import 'package:active_ecommerce_seller_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_seller_app/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:one_context/one_context.dart';

/// Error from a Hal Al Mushkila Seller call. [message] is safe to show to the user.
class HmApiException implements Exception {
  final int status;
  final String message;
  final Map<String, List<String>> errors;

  HmApiException(this.status, this.message, [this.errors = const {}]);

  String? fieldError(String field) => errors[field]?.firstOrNull;

  @override
  String toString() => message;
}

/// One page of a paginated list.
class HmPage<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;

  HmPage(this.items, this.currentPage, this.lastPage);

  bool get hasMore => currentPage < lastPage;
}

/// Low-level HTTP client for `{base}/seller/muskila/...` (mirrors `ChApi`).
class HmApi {
  static const String _prefix = "seller/muskila";
  static const Duration _timeout = Duration(seconds: 30);

  static String url(String path) {
    if (path.startsWith("/")) path = path.substring(1);
    return "${AppConfig.BASE_URL}/$path";
  }

  static String seller(String path) {
    if (path.startsWith("/")) path = path.substring(1);
    return url("$_prefix/$path");
  }

  static Map<String, String> headers({
    bool auth = true,
    bool json = true,
    String? idempotencyKey,
  }) {
    return {
      "Accept": "application/json",
      "System-Key": AppConfig.system_key,
      "App-Language": app_language.$ ?? AppConfig.default_language,
      if (json) "Content-Type": "application/json",
      if (auth) "Authorization": "Bearer ${access_token.$}",
      if (idempotencyKey != null) "Idempotency-Key": idempotencyKey,
    };
  }

  /// Random UUID v4. Create once per user action and reuse on retries.
  static String newIdempotencyKey() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
    final s = List.generate(16, h).join();
    return "${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}";
  }

  static Future<dynamic> get(
    String fullUrl, {
    bool auth = true,
    bool signOutOnAuthError = true,
  }) =>
      _send(
        () => http
            .get(Uri.parse(fullUrl), headers: headers(auth: auth))
            .timeout(_timeout),
        signOutOnAuthError: signOutOnAuthError,
      );

  static Future<dynamic> post(
    String fullUrl, {
    Object? body,
    bool auth = true,
    String? idempotencyKey,
  }) =>
      _send(
        () => http
            .post(
              Uri.parse(fullUrl),
              headers: headers(auth: auth, idempotencyKey: idempotencyKey),
              body: jsonEncode(body ?? {}),
            )
            .timeout(_timeout),
      );

  static Future<dynamic> put(String fullUrl, {Object? body}) => _send(
        () => http
            .put(
              Uri.parse(fullUrl),
              headers: headers(),
              body: jsonEncode(body ?? {}),
            )
            .timeout(_timeout),
      );

  static Future<dynamic> delete(String fullUrl, {Object? body}) => _send(
        () => http
            .delete(
              Uri.parse(fullUrl),
              headers: headers(),
              body: body == null ? null : jsonEncode(body),
            )
            .timeout(_timeout),
      );

  /// `multipart/form-data` upload. [files] maps field name -> local path.
  static Future<dynamic> multipart(
    String fullUrl, {
    Map<String, String> fields = const {},
    Map<String, String> files = const {},
    bool auth = true,
  }) {
    return _send(() async {
      final req = http.MultipartRequest("POST", Uri.parse(fullUrl));
      req.headers.addAll(headers(auth: auth, json: false));
      req.fields.addAll(fields);
      for (final e in files.entries) {
        req.files.add(await http.MultipartFile.fromPath(e.key, e.value));
      }
      final streamed = await req.send().timeout(const Duration(seconds: 90));
      return http.Response.fromStream(streamed);
    });
  }

  static Future<dynamic> _send(
    Future<http.Response> Function() call, {
    bool signOutOnAuthError = true,
  }) async {
    http.Response res;
    var attempt = 0;
    while (true) {
      try {
        res = await call();
      } on SocketException {
        throw HmApiException(0, "No internet connection. Please try again.");
      } on TimeoutException {
        throw HmApiException(0, "The server took too long. Please try again.");
      } on http.ClientException {
        throw HmApiException(0, "Could not reach the server. Please try again.");
      }
      if (res.statusCode == 409 && attempt < 3) {
        attempt++;
        await Future.delayed(const Duration(milliseconds: 2500));
        continue;
      }
      break;
    }
    return _handle(res, signOutOnAuthError);
  }

  static dynamic _handle(http.Response res, bool signOutOnAuthError) {
    dynamic body;
    try {
      body = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      body = null;
    }
    final map = body is Map<String, dynamic> ? body : <String, dynamic>{};
    final bodyStatus = hmInt(map["status"]);
    final effectiveStatus =
        (bodyStatus != null && bodyStatus >= 400) ? bodyStatus : res.statusCode;

    final ok = res.statusCode >= 200 &&
        res.statusCode < 300 &&
        map["result"] != false &&
        map["success"] != false &&
        (bodyStatus == null || bodyStatus < 400);

    if (ok) return map;

    final errors = <String, List<String>>{};
    if (map["errors"] is Map) {
      (map["errors"] as Map).forEach((k, v) {
        errors[k.toString()] =
            v is List ? v.map((e) => e.toString()).toList() : [v.toString()];
      });
    }
    final message =
        _messageFrom(map["message"]) ?? _fallbackMessage(effectiveStatus);

    final tokenProblem = effectiveStatus == 401 ||
        (effectiveStatus == 403 &&
            message.toLowerCase().contains("sign in again"));
    if (tokenProblem && signOutOnAuthError) _signOutLocally();

    throw HmApiException(effectiveStatus, message, errors);
  }

  static String? _messageFrom(dynamic m) {
    if (m == null) return null;
    if (m is List) return m.map((e) => e.toString()).join("\n");
    final s = m.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _fallbackMessage(int status) {
    switch (status) {
      case 401:
        return "Your session has ended. Please sign in again.";
      case 403:
        return "You can't do this with this account.";
      case 404:
        return "Not found.";
      case 409:
        return "Still working on your last request. Please try again.";
      case 422:
        return "This can't be done right now.";
      case 429:
        return "Too many attempts, try again in a minute.";
      case 503:
        return "The server is down. Please try again later.";
      default:
        return "Something went wrong. Please try again.";
    }
  }

  static bool _signingOut = false;

  static void _signOutLocally() {
    if (_signingOut) return;
    _signingOut = true;
    AuthHelper().clearUserData();
    final ctx = OneContext().context;
    if (ctx != null) {
      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => Login()),
        (route) => false,
      );
    }
    Future.delayed(const Duration(seconds: 2), () => _signingOut = false);
  }
}

// ---- JSON parsing helpers (mirrors ch_api.dart) ----------------------------

int? hmInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? hmDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool hmBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase();
  return s == "true" || s == "1" || s == "yes";
}

String? hmStr(dynamic v) => v?.toString();

DateTime? hmDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

List<String> hmStrList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

Map<String, dynamic> hmMap(dynamic v) =>
    v is Map<String, dynamic>
        ? v
        : (v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{});

List<Map<String, dynamic>> hmMapList(dynamic v) =>
    v is List ? v.whereType<Map>().map(hmMap).toList() : const [];

