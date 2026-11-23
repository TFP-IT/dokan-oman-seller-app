import 'package:active_ecommerce_seller_app/cook_habibi/ch_api.dart';

/// Picks the first value among [keys] that looks like an image URL. The API
/// takes upload ids on write; on read it may send a URL string or an object
/// with a `url`.
String? chImageUrl(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    final v = m[k];
    if (v is String && (v.startsWith("http") || v.startsWith("/"))) return v;
    if (v is Map && v["url"] is String) return v["url"];
  }
  return null;
}

// ---- application (§4) -------------------------------------------------------

class ChApplication {
  final int? id;
  final String kitchenName;
  final String status; // pending | rejected | approved
  final DateTime? appliedAt;
  final String? rejectionReason;
  final bool canResubmit;
  final List<String> missingChecks;

  ChApplication({
    this.id,
    this.kitchenName = "",
    this.status = "pending",
    this.appliedAt,
    this.rejectionReason,
    this.canResubmit = false,
    this.missingChecks = const [],
  });

  bool get isApproved => status == "approved";
  bool get isRejected => status == "rejected";
  bool get isPending => status == "pending";

  factory ChApplication.fromJson(Map<String, dynamic> j) => ChApplication(
        id: chInt(j["id"]),
        kitchenName: chStr(j["kitchen_name"]) ?? "",
        status: chStr(j["status"]) ?? "pending",
        appliedAt: chDate(j["applied_at"]),
        rejectionReason: chStr(j["rejection_reason"]),
        canResubmit: chBool(j["can_resubmit"]),
        missingChecks: chStrList(j["missing_checks"]),
      );
}

// ---- kitchen profile (§5) ---------------------------------------------------

class ChProfile {
  final Map<String, dynamic> raw;

  ChProfile(this.raw);

  factory ChProfile.fromJson(Map<String, dynamic> j) => ChProfile(j);

  String get kitchenName => chStr(raw["kitchen_name"]) ?? "";
  String get cookName => chStr(raw["cook_name"]) ?? "";
  String get emoji => chStr(raw["emoji"]) ?? "";
  String get status => chStr(raw["status"]) ?? "";
  bool get isSuspended => status == "suspended" || chBool(raw["is_suspended"]);
  bool get isAcceptingOrders => chBool(raw["is_accepting_orders"]);
  String get area => chStr(raw["area"]) ?? "";
  String get bio => chStr(raw["bio"]) ?? "";
  double? get rating => chDouble(raw["rating"]);
  String? get coverUrl =>
      chImageUrl(raw, ["cover_image_url", "cover_image", "cover"]);
  String? get ownerUrl =>
      chImageUrl(raw, ["owner_image_url", "owner_image", "owner"]);

  /// `{"mon": ["10:00","22:00"], ...}`; a missing or empty day is closed.
  Map<String, List<String>> get workingHours {
    final out = <String, List<String>>{};
    final w = raw["working_hours"] ?? raw["schedule"];
    if (w is Map) {
      w.forEach((k, v) {
        final list = chStrList(v);
        if (list.length >= 2) out[k.toString()] = [list[0], list[1]];
      });
    }
    return out;
  }
}

// ---- dashboard + earnings (§9) ----------------------------------------------

class ChDashboard {
  final int ordersToday;
  final double salesToday;
  final int activeOrders;
  final int completedOrders;
  final double? rating;
  final int reviewsCount;
  final int liveStories;
  final bool isOpen;
  final double balanceDue;
  final String currency;

  ChDashboard({
    this.ordersToday = 0,
    this.salesToday = 0,
    this.activeOrders = 0,
    this.completedOrders = 0,
    this.rating,
    this.reviewsCount = 0,
    this.liveStories = 0,
    this.isOpen = false,
    this.balanceDue = 0,
    this.currency = "OMR",
  });

  factory ChDashboard.fromJson(Map<String, dynamic> j) => ChDashboard(
        ordersToday: chInt(j["orders_today"]) ?? 0,
        salesToday: chDouble(j["sales_today"]) ?? 0,
        activeOrders: chInt(j["active_orders"]) ?? 0,
        completedOrders: chInt(j["completed_orders"]) ?? 0,
        rating: chDouble(j["rating"]),
        reviewsCount: chInt(j["reviews_count"]) ?? 0,
        liveStories: chInt(j["live_stories"]) ?? 0,
        isOpen: chBool(j["is_open"]),
        balanceDue: chDouble(j["balance_due"]) ?? 0,
        currency: chStr(j["currency"]) ?? "OMR",
      );
}

class ChRelease {
  final String code;
  final double yourEarning;
  final double commission;
  final DateTime? releasedAt;

  ChRelease(this.code, this.yourEarning, this.commission, this.releasedAt);

  factory ChRelease.fromJson(Map<String, dynamic> j) => ChRelease(
        chStr(j["code"]) ?? "",
        chDouble(j["your_earning"]) ?? 0,
        chDouble(j["commission"]) ?? 0,
        chDate(j["released_at"]),
      );
}

class ChPayment {
  final double amount;
  final String method;
  final String reference;
  final DateTime? paidAt;

  ChPayment(this.amount, this.method, this.reference, this.paidAt);

  factory ChPayment.fromJson(Map<String, dynamic> j) => ChPayment(
        chDouble(j["amount"]) ?? 0,
        chStr(j["method"]) ?? "",
        chStr(j["reference"]) ?? "",
        chDate(j["paid_at"]),
      );
}

class ChEarnings {
  final double balanceDue;
  final double paidOut;
  final int pendingOrders;
  final double pendingCustomerTotal;
  final int releasedOrders;
  final double releasedEarning;
  final double releasedCommission;
  final List<ChRelease> recentReleases;
  final List<ChPayment> recentPayments;
  final String currency;

  ChEarnings({
    this.balanceDue = 0,
    this.paidOut = 0,
    this.pendingOrders = 0,
    this.pendingCustomerTotal = 0,
    this.releasedOrders = 0,
    this.releasedEarning = 0,
    this.releasedCommission = 0,
    this.recentReleases = const [],
    this.recentPayments = const [],
    this.currency = "OMR",
  });

  factory ChEarnings.fromJson(Map<String, dynamic> j) {
    final pending = chMap(j["pending"]);
    final released = chMap(j["released"]);
    return ChEarnings(
      balanceDue: chDouble(j["balance_due"]) ?? 0,
      paidOut: chDouble(j["paid_out"]) ?? 0,
      pendingOrders: chInt(pending["orders"]) ?? 0,
      pendingCustomerTotal: chDouble(pending["customer_total"]) ?? 0,
      releasedOrders: chInt(released["orders"]) ?? 0,
      releasedEarning: chDouble(released["your_earning"]) ?? 0,
      releasedCommission: chDouble(released["commission"]) ?? 0,
      recentReleases: (j["recent_releases"] is List)
          ? (j["recent_releases"] as List)
              .map((e) => ChRelease.fromJson(chMap(e)))
              .toList()
          : [],
      recentPayments: (j["recent_payments"] is List)
          ? (j["recent_payments"] as List)
              .map((e) => ChPayment.fromJson(chMap(e)))
              .toList()
          : [],
      currency: chStr(j["currency"]) ?? "OMR",
    );
  }
}

// ---- orders (§6) ------------------------------------------------------------

class ChOrderAmounts {
  final double food;
  final double deliveryFee;
  final double customerPaid;
  final double? yourEarning; // null until released
  final String? escrowStatus;

  ChOrderAmounts(this.food, this.deliveryFee, this.customerPaid,
      this.yourEarning, this.escrowStatus);

  factory ChOrderAmounts.fromJson(Map<String, dynamic> j) => ChOrderAmounts(
        chDouble(j["food"]) ?? 0,
        chDouble(j["delivery_fee"]) ?? 0,
        chDouble(j["customer_paid"]) ?? 0,
        chDouble(j["your_earning"]),
        chStr(j["escrow_status"]),
      );
}

class ChOrder {
  final int id;
  final String code;
  final String status;
  final String statusTitle;
  final String fulfilment; // delivery | pickup
  final int? dishId;
  final String dishName;
  final String dishEmoji;
  final int qty;
  final String? note;
  final String? slot;
  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final ChOrderAmounts amounts;
  final DateTime? acceptDeadline;
  final List<String> nextActions;
  final String? cancelReason;
  final DateTime? createdAt;
  final String currency;

  ChOrder({
    required this.id,
    required this.code,
    required this.status,
    required this.statusTitle,
    required this.fulfilment,
    this.dishId,
    this.dishName = "",
    this.dishEmoji = "",
    this.qty = 1,
    this.note,
    this.slot,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.amounts,
    this.acceptDeadline,
    this.nextActions = const [],
    this.cancelReason,
    this.createdAt,
    this.currency = "OMR",
  });

  bool get isPickup => fulfilment == "pickup";

  factory ChOrder.fromJson(Map<String, dynamic> j) {
    final dish = chMap(j["dish"]);
    final customer = chMap(j["customer"]);
    final address = customer["address"];
    return ChOrder(
      id: chInt(j["id"]) ?? 0,
      code: chStr(j["code"]) ?? "",
      status: chStr(j["status"]) ?? "",
      statusTitle: chStr(j["status_title"]) ?? chStr(j["status"]) ?? "",
      fulfilment: chStr(j["fulfilment"]) ?? "delivery",
      dishId: chInt(dish["id"]),
      dishName: chStr(dish["name"]) ?? "",
      dishEmoji: chStr(dish["emoji"]) ?? "",
      qty: chInt(j["qty"]) ?? 1,
      note: chStr(j["note"]),
      slot: chStr(j["slot"]),
      customerName: chStr(customer["name"]),
      customerPhone: chStr(customer["phone"]),
      customerAddress: address is Map
          ? (address["text"] ?? address["address"] ?? address.values.join(", "))
              ?.toString()
          : chStr(address),
      amounts: ChOrderAmounts.fromJson(chMap(j["amounts"])),
      acceptDeadline: chDate(j["accept_deadline"]),
      nextActions: chStrList(j["next_actions"]),
      cancelReason: chStr(j["cancel_reason"]),
      createdAt: chDate(j["created_at"]),
      currency: chStr(j["currency"]) ?? "OMR",
    );
  }
}

// ---- dishes (§7) ------------------------------------------------------------

class ChDish {
  final Map<String, dynamic> raw;

  ChDish(this.raw);

  factory ChDish.fromJson(Map<String, dynamic> j) => ChDish(j);

  int get id => chInt(raw["id"]) ?? 0;
  String get name => chStr(raw["name"]) ?? "";
  String get description => chStr(raw["description"]) ?? "";
  double get price => chDouble(raw["price"]) ?? 0;
  double get discountPercent => chDouble(raw["discount_percent"]) ?? 0;
  String get emoji => chStr(raw["emoji"]) ?? "";
  int get serves => chInt(raw["serves"]) ?? 1;
  List<String> get dietary => chStrList(raw["dietary"]);
  List<String> get allergens => chStrList(raw["allergens"]);
  bool get isFamilyMeal => chBool(raw["is_family_meal"]);
  bool get preOrderOnly => chBool(raw["pre_order_only"]);
  String get badge => chStr(raw["badge"]) ?? "";
  bool get published => chBool(raw["published"]);
  String get status =>
      chStr(raw["status"]) ?? (published ? "published" : "hidden");
  bool get pendingApproval =>
      status == "pending_approval" || chBool(raw["pending_approval"]);
  int? get dailyCapacity => chInt(raw["daily_capacity"]);
  int? get sort => chInt(raw["sort"]);
  String? get thumbnailUrl =>
      chImageUrl(raw, ["thumbnail_url", "thumbnail", "image"]);
  int? get thumbnailUploadId =>
      chInt(raw["thumbnail_id"] ?? raw["thumbnail_upload_id"]);
}

// ---- stories (§8) -----------------------------------------------------------

class ChStory {
  final int id;
  final String caption;
  final int? dishId;
  final String? dishName;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  ChStory({
    required this.id,
    this.caption = "",
    this.dishId,
    this.dishName,
    this.imageUrl,
    this.createdAt,
    this.expiresAt,
  });

  bool get isLive {
    final end = expiresAt ?? createdAt?.add(const Duration(hours: 24));
    return end != null && end.isAfter(DateTime.now());
  }

  factory ChStory.fromJson(Map<String, dynamic> j) {
    final dish = chMap(j["dish"]);
    return ChStory(
      id: chInt(j["id"]) ?? 0,
      caption: chStr(j["caption"]) ?? "",
      dishId: chInt(j["dish_id"]) ?? chInt(dish["id"]),
      dishName: chStr(dish["name"]),
      imageUrl:
          chImageUrl(j, ["image_url", "image", "photo_url", "photo", "url"]),
      createdAt: chDate(j["created_at"]),
      expiresAt: chDate(j["expires_at"]),
    );
  }
}
