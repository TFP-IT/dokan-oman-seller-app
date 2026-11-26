import 'package:active_ecommerce_seller_app/hal_al_muskila/hm_api.dart';

// ---- Shared Meta (/api/v2/muskila/meta) ------------------------------------

class HmMetaCategory {
  final String id;
  final String name;
  final List<String> suggestions;

  HmMetaCategory({
    required this.id,
    required this.name,
    required this.suggestions,
  });

  factory HmMetaCategory.fromJson(Map<String, dynamic> j) => HmMetaCategory(
        id: hmStr(j["id"]) ?? "",
        name: hmStr(j["name"]) ?? "",
        suggestions: hmStrList(j["suggestions"]),
      );
}

class HmScheduleSlot {
  final String id;
  final String label;

  HmScheduleSlot({required this.id, required this.label});

  factory HmScheduleSlot.fromJson(Map<String, dynamic> j) => HmScheduleSlot(
        id: hmStr(j["id"]) ?? "",
        label: hmStr(j["label"]) ?? "",
      );
}

class HmScheduleDate {
  final String date;
  final String label;

  HmScheduleDate({required this.date, required this.label});

  factory HmScheduleDate.fromJson(Map<String, dynamic> j) => HmScheduleDate(
        date: hmStr(j["date"]) ?? "",
        label: hmStr(j["label"]) ?? "",
      );
}

class HmMeta {
  final List<HmMetaCategory> categories;
  final List<String> serviceAreas;
  final List<HmScheduleDate> dates;
  final List<HmScheduleSlot> slots;
  final double defaultLat;
  final double defaultLng;

  HmMeta({
    required this.categories,
    required this.serviceAreas,
    required this.dates,
    required this.slots,
    required this.defaultLat,
    required this.defaultLng,
  });

  factory HmMeta.fromJson(Map<String, dynamic> j) {
    final loc = hmMap(j["default_location"]);
    final sch = hmMap(j["schedule"]);
    return HmMeta(
      categories: hmMapList(j["categories"])
          .map(HmMetaCategory.fromJson)
          .where((c) => c.id.isNotEmpty)
          .toList(),
      serviceAreas: hmStrList(j["service_areas"]),
      dates: hmMapList(sch["dates"]).map(HmScheduleDate.fromJson).toList(),
      slots: hmMapList(sch["slots"]).map(HmScheduleSlot.fromJson).toList(),
      defaultLat: hmDouble(loc["lat"]) ?? 23.5932,
      defaultLng: hmDouble(loc["lng"]) ?? 58.4137,
    );
  }
}

// ---- Application Gate (/seller/muskila/application) ------------------------

class HmApplication {
  final int? id;
  final String proName;
  final String status; // pending | approved | rejected
  final DateTime? appliedAt;
  final String? rejectionReason;
  final bool canResubmit;
  final List<String> missingChecks;

  HmApplication({
    this.id,
    required this.proName,
    required this.status,
    this.appliedAt,
    this.rejectionReason,
    required this.canResubmit,
    required this.missingChecks,
  });

  bool get isApproved => status == "approved";
  bool get isPending => status == "pending";
  bool get isRejected => status == "rejected";

  factory HmApplication.fromJson(Map<String, dynamic> j) => HmApplication(
        id: hmInt(j["id"]),
        proName: hmStr(j["pro_name"]) ?? hmStr(j["name"]) ?? "Your profile",
        status: hmStr(j["status"]) ?? "",
        appliedAt: hmDate(j["applied_at"]),
        rejectionReason: hmStr(j["rejection_reason"]),
        canResubmit: hmBool(j["can_resubmit"]),
        missingChecks: hmStrList(j["missing_checks"]),
      );
}

// ---- Dashboard (/seller/muskila/dashboard) ---------------------------------

class HmDashboard {
  final String currency;
  final double earningsToday;
  final double balanceDue;
  final double pendingEscrow;
  final int pendingEscrowCount;
  final int bookingsToday;
  final int activeBookings;
  final int completedJobs;
  final int jobLeadsCount;
  final double? rating;
  final int reviewsCount;
  final bool isOnline;
  final bool isSuspended;
  final int unreadChats;
  final int unreadNotifications;
  final int pendingInstantCount;

  HmDashboard({
    required this.currency,
    required this.earningsToday,
    required this.balanceDue,
    required this.pendingEscrow,
    required this.pendingEscrowCount,
    required this.bookingsToday,
    required this.activeBookings,
    required this.completedJobs,
    required this.jobLeadsCount,
    this.rating,
    required this.reviewsCount,
    required this.isOnline,
    required this.isSuspended,
    required this.unreadChats,
    required this.unreadNotifications,
    required this.pendingInstantCount,
  });

  factory HmDashboard.fromJson(Map<String, dynamic> j) => HmDashboard(
        currency: hmStr(j["currency"]) ?? "OMR",
        earningsToday: hmDouble(j["earnings_today"]) ?? 0,
        balanceDue: hmDouble(j["balance_due"]) ?? 0,
        pendingEscrow: hmDouble(j["pending_escrow"]) ?? 0,
        pendingEscrowCount: hmInt(j["pending_escrow_count"]) ?? 0,
        bookingsToday: hmInt(j["bookings_today"]) ?? 0,
        activeBookings: hmInt(j["active_bookings"]) ?? 0,
        completedJobs: hmInt(j["completed_jobs"]) ?? 0,
        jobLeadsCount: hmInt(j["job_leads_count"]) ?? 0,
        rating: hmDouble(j["rating"]),
        reviewsCount: hmInt(j["reviews_count"]) ?? 0,
        isOnline: hmBool(j["is_online"]),
        isSuspended: hmBool(j["is_suspended"]),
        unreadChats: hmInt(j["unread_chats"]) ?? 0,
        unreadNotifications: hmInt(j["unread_notifications"]) ?? 0,
        pendingInstantCount: hmInt(j["pending_instant_count"]) ?? 0,
      );
}

// ---- Profile & KYC (/seller/muskila/profile) -------------------------------

class HmVerificationCheck {
  final String key;
  final String label;
  final bool verified;

  HmVerificationCheck({
    required this.key,
    required this.label,
    required this.verified,
  });

  factory HmVerificationCheck.fromJson(Map<String, dynamic> j) =>
      HmVerificationCheck(
        key: hmStr(j["key"]) ?? "",
        label: hmStr(j["label"]) ?? "",
        verified: hmBool(j["verified"]),
      );
}

class HmProfile {
  final Map<String, dynamic> raw;
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photo;
  final String? videoUrl;
  final String categoryId;
  final String professionTitle;
  final int experienceYears;
  final String bio;
  final List<String> skills;
  final double visitPrice;
  final double hourlyRate;
  final double rating;
  final int reviewsCount;
  final int jobsCompleted;
  final double onTimePercentage;
  final bool isOnline;
  final bool isVerified;
  final bool fullyVerified;
  final bool isSuspended;
  final bool allowCustomBargain;
  final double minCustomPrice;
  final List<String> serviceAreas;
  final double? lat;
  final double? lng;
  final int radiusKm;
  final String locationLabel;
  final List<HmVerificationCheck> verifications;
  final Map<String, dynamic> workingSchedule;

  HmProfile({
    required this.raw,
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photo,
    this.videoUrl,
    required this.categoryId,
    required this.professionTitle,
    required this.experienceYears,
    required this.bio,
    required this.skills,
    required this.visitPrice,
    required this.hourlyRate,
    required this.rating,
    required this.reviewsCount,
    required this.jobsCompleted,
    required this.onTimePercentage,
    required this.isOnline,
    required this.isVerified,
    required this.fullyVerified,
    required this.isSuspended,
    required this.allowCustomBargain,
    required this.minCustomPrice,
    required this.serviceAreas,
    this.lat,
    this.lng,
    required this.radiusKm,
    required this.locationLabel,
    required this.verifications,
    required this.workingSchedule,
  });

  factory HmProfile.fromJson(Map<String, dynamic> j) {
    final video = hmMap(j["video"]);
    return HmProfile(
      raw: j,
      id: hmStr(j["id"]) ?? "",
      name: hmStr(j["name"]) ?? "",
      email: hmStr(j["email"]) ?? "",
      phone: hmStr(j["phone"]) ?? "",
      photo: hmStr(j["photo"]) ?? hmStr(j["avatar"]),
      videoUrl: hmStr(video["url"]) ?? hmStr(j["video_url"]),
      categoryId: hmStr(j["category_id"]) ?? "",
      professionTitle: hmStr(j["profession_title"]) ?? "",
      experienceYears: hmInt(j["experience_years"]) ?? 0,
      bio: hmStr(j["bio"]) ?? "",
      skills: hmStrList(j["skills"]),
      visitPrice: hmDouble(j["visit_price"]) ?? 0,
      hourlyRate: hmDouble(j["hourly_rate"]) ?? 0,
      rating: hmDouble(j["rating"]) ?? 0,
      reviewsCount: hmInt(j["reviews_count"]) ?? 0,
      jobsCompleted: hmInt(j["jobs_completed"]) ?? 0,
      onTimePercentage: hmDouble(j["on_time_percentage"]) ?? 100,
      isOnline: hmBool(j["is_online"]),
      isVerified: hmBool(j["is_verified"] ?? j["verified"]),
      fullyVerified: hmBool(j["fully_verified"]),
      isSuspended: hmBool(j["is_suspended"]),
      allowCustomBargain: hmBool(j["allow_custom_bargain"], true),
      minCustomPrice: hmDouble(j["min_custom_price"]) ?? 0,
      serviceAreas: hmStrList(j["service_areas"]),
      lat: hmDouble(j["lat"] ?? j["latitude"]),
      lng: hmDouble(j["lng"] ?? j["longitude"]),
      radiusKm: hmInt(j["radius_km"]) ?? 15,
      locationLabel: hmStr(j["location_label"]) ?? "",
      verifications:
          hmMapList(j["verifications"]).map(HmVerificationCheck.fromJson).toList(),
      workingSchedule: hmMap(j["working_schedule"]),
    );
  }
}

// ---- Instant Requests (/seller/muskila/instant-requests) -------------------

class HmInstantRequest {
  final String id;
  final String categoryId;
  final String categoryName;
  final String customerName;
  final String locationText;
  final double? lat;
  final double? lng;
  final double distanceKm;
  final String notes;
  final double offeredPrice;
  final DateTime? expiresAt;

  HmInstantRequest({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.customerName,
    required this.locationText,
    this.lat,
    this.lng,
    required this.distanceKm,
    required this.notes,
    required this.offeredPrice,
    this.expiresAt,
  });

  factory HmInstantRequest.fromJson(Map<String, dynamic> j) => HmInstantRequest(
        id: hmStr(j["id"]) ?? "",
        categoryId: hmStr(j["category_id"]) ?? "",
        categoryName: hmStr(j["category_name"]) ?? "",
        customerName: hmStr(j["customer_name"]) ?? "Customer",
        locationText: hmStr(j["location_text"]) ?? "",
        lat: hmDouble(j["lat"]),
        lng: hmDouble(j["lng"]),
        distanceKm: hmDouble(j["distance_km"]) ?? 0,
        notes: hmStr(j["notes"]) ?? "",
        offeredPrice: hmDouble(j["offered_price"]) ?? 0,
        expiresAt: hmDate(j["expires_at"]),
      );
}

// ---- Bookings (/seller/muskila/bookings) -----------------------------------

class HmBooking {
  final String id;
  final String bookingNumber;
  final String source;
  final String status; // pending | scheduled | active | completed | cancelled
  final String statusTitle;
  final int step; // 0..4
  final String serviceTitle;
  final String categoryName;
  final String customerName;
  final String customerPhone;
  final String customerAvatar;
  final String scheduledDateText;
  final String scheduledTimeSlot;
  final String locationAddress;
  final double? lat;
  final double? lng;
  final String notes;
  final int etaMinutes;
  final double price;
  final double platformFee;
  final double escrowAmount;
  final double? yourEarning;
  final String escrowStatus;
  final bool escrowReleased;
  final double? userRating;
  final String? userReview;
  final String? cancelReason;
  final String? threadId;
  final DateTime? acceptDeadline;
  final List<String> nextActions;
  final DateTime? createdAt;
  final String currency;

  HmBooking({
    required this.id,
    required this.bookingNumber,
    required this.source,
    required this.status,
    required this.statusTitle,
    required this.step,
    required this.serviceTitle,
    required this.categoryName,
    required this.customerName,
    required this.customerPhone,
    required this.customerAvatar,
    required this.scheduledDateText,
    required this.scheduledTimeSlot,
    required this.locationAddress,
    this.lat,
    this.lng,
    required this.notes,
    required this.etaMinutes,
    required this.price,
    required this.platformFee,
    required this.escrowAmount,
    this.yourEarning,
    required this.escrowStatus,
    required this.escrowReleased,
    this.userRating,
    this.userReview,
    this.cancelReason,
    this.threadId,
    this.acceptDeadline,
    required this.nextActions,
    this.createdAt,
    this.currency = "OMR",
  });

  factory HmBooking.fromJson(Map<String, dynamic> j) => HmBooking(
        id: hmStr(j["id"]) ?? "",
        bookingNumber: hmStr(j["booking_number"]) ?? "#${j["id"] ?? ""}",
        source: hmStr(j["source"]) ?? "direct",
        status: hmStr(j["status"]) ?? "pending",
        statusTitle: hmStr(j["status_title"]) ?? hmStr(j["status"]) ?? "Pending",
        step: (hmInt(j["step"]) ?? 0).clamp(0, 4),
        serviceTitle: hmStr(j["service_title"]) ?? "",
        categoryName: hmStr(j["category_name"]) ?? "",
        customerName: hmStr(j["customer_name"]) ?? "Customer",
        customerPhone: hmStr(j["customer_phone"]) ?? "",
        customerAvatar: hmStr(j["customer_avatar"]) ?? "",
        scheduledDateText:
            hmStr(j["scheduled_date_text"]) ?? hmStr(j["scheduled_date"]) ?? "",
        scheduledTimeSlot: hmStr(j["scheduled_time_slot"]) ?? "",
        locationAddress: hmStr(j["location_address"]) ?? "",
        lat: hmDouble(j["lat"]),
        lng: hmDouble(j["lng"]),
        notes: hmStr(j["notes"]) ?? "",
        etaMinutes: hmInt(j["eta_minutes"]) ?? 0,
        price: hmDouble(j["price"]) ?? 0,
        platformFee: hmDouble(j["platform_fee"]) ?? 0,
        escrowAmount: hmDouble(j["escrow_amount"]) ?? hmDouble(j["price"]) ?? 0,
        yourEarning: hmDouble(j["your_earning"]),
        escrowStatus: hmStr(j["escrow_status"]) ?? "held",
        escrowReleased: hmBool(j["escrow_released"]),
        userRating: hmDouble(j["user_rating"]),
        userReview: hmStr(j["user_review"]),
        cancelReason: hmStr(j["cancel_reason"]),
        threadId: hmStr(j["thread_id"]),
        acceptDeadline: hmDate(j["accept_deadline"]),
        nextActions: hmStrList(j["next_actions"]),
        createdAt: hmDate(j["created_at"]),
        currency: hmStr(j["currency"]) ?? "OMR",
      );
}

// ---- Job Board, Quotes & Expert Posts --------------------------------------

class HmJobLead {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final String customerName;
  final String location;
  final double distanceKm;
  final String preferredSchedule;
  final double budgetMin;
  final double budgetMax;
  final String? imageUrl;
  final bool isUrgent;
  final int proposalCount;
  final int maxQuotes;
  final bool hasApplied;
  final String closesInText;
  final String createdAtText;

  HmJobLead({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.customerName,
    required this.location,
    required this.distanceKm,
    required this.preferredSchedule,
    required this.budgetMin,
    required this.budgetMax,
    this.imageUrl,
    required this.isUrgent,
    required this.proposalCount,
    required this.maxQuotes,
    required this.hasApplied,
    required this.closesInText,
    required this.createdAtText,
  });

  factory HmJobLead.fromJson(Map<String, dynamic> j) => HmJobLead(
        id: hmStr(j["id"]) ?? "",
        title: hmStr(j["title"]) ?? "",
        description: hmStr(j["description"]) ?? "",
        categoryId: hmStr(j["category_id"]) ?? "",
        categoryName: hmStr(j["category_name"]) ?? "",
        customerName: hmStr(j["customer_name"]) ?? "Customer",
        location: hmStr(j["location"]) ?? "",
        distanceKm: hmDouble(j["distance_km"]) ?? 0,
        preferredSchedule: hmStr(j["preferred_schedule"]) ?? "",
        budgetMin: hmDouble(j["budget_min"] ?? j["budget"]) ?? 0,
        budgetMax: hmDouble(j["budget_max"] ?? j["budget"]) ?? 0,
        imageUrl: hmStr(j["image_url"]),
        isUrgent: hmBool(j["is_urgent"]),
        proposalCount: hmInt(j["proposal_count"]) ?? 0,
        maxQuotes: hmInt(j["max_quotes"]) ?? 5,
        hasApplied: hmBool(j["has_applied"]),
        closesInText: hmStr(j["closes_in_text"]) ?? "",
        createdAtText: hmStr(j["created_at_text"]) ?? hmStr(j["created_at"]) ?? "",
      );
}

class HmQuote {
  final String id;
  final String leadId;
  final String leadTitle;
  final double price;
  final String message;
  final String whenText;
  final String teamOrWorkerDetail;
  final String status; // pending | accepted | rejected | expired

  HmQuote({
    required this.id,
    required this.leadId,
    required this.leadTitle,
    required this.price,
    required this.message,
    required this.whenText,
    required this.teamOrWorkerDetail,
    required this.status,
  });

  factory HmQuote.fromJson(Map<String, dynamic> j) => HmQuote(
        id: hmStr(j["id"]) ?? "",
        leadId: hmStr(j["lead_id"]) ?? "",
        leadTitle: hmStr(j["lead_title"]) ?? "",
        price: hmDouble(j["price"]) ?? 0,
        message: hmStr(j["message"]) ?? "",
        whenText: hmStr(j["when_text"]) ?? "",
        teamOrWorkerDetail: hmStr(j["team_or_worker_detail"]) ?? "",
        status: hmStr(j["status"]) ?? "pending",
      );
}

class HmBargainTier {
  final String id;
  final String label;
  final double price;
  final int totalQuota;
  final int remainingQuota;

  HmBargainTier({
    this.id = "",
    required this.label,
    required this.price,
    required this.totalQuota,
    required this.remainingQuota,
  });

  factory HmBargainTier.fromJson(Map<String, dynamic> j) => HmBargainTier(
        id: hmStr(j["id"]) ?? "",
        label: hmStr(j["label"]) ?? "",
        price: hmDouble(j["price"]) ?? 0,
        totalQuota: hmInt(j["total_quota"]) ?? 0,
        remainingQuota: hmInt(j["remaining_quota"]) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "label": label,
        "price": price,
        "total_quota": totalQuota,
      };
}

class HmExpertPost {
  final String id;
  final String categoryId;
  final String categoryName;
  final String title;
  final String description;
  final String location;
  final String preferredSchedule;
  final String? imageUrl;
  final bool isBargainable;
  final List<HmBargainTier> bargainTiers;
  final String status;

  HmExpertPost({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.description,
    required this.location,
    required this.preferredSchedule,
    this.imageUrl,
    required this.isBargainable,
    required this.bargainTiers,
    required this.status,
  });

  factory HmExpertPost.fromJson(Map<String, dynamic> j) => HmExpertPost(
        id: hmStr(j["id"]) ?? "",
        categoryId: hmStr(j["category_id"]) ?? "",
        categoryName: hmStr(j["category_name"]) ?? "",
        title: hmStr(j["title"]) ?? "",
        description: hmStr(j["description"]) ?? "",
        location: hmStr(j["location"]) ?? "",
        preferredSchedule: hmStr(j["preferred_schedule"]) ?? "",
        imageUrl: hmStr(j["image_url"]),
        isBargainable: hmBool(j["is_bargainable"]),
        bargainTiers:
            hmMapList(j["bargain_tiers"]).map(HmBargainTier.fromJson).toList(),
        status: hmStr(j["status"]) ?? "open",
      );
}

// ---- Services Catalog (/seller/muskila/services) --------------------------

class HmServicePackage {
  final String id;
  final String categoryId;
  final String categoryName;
  final String title;
  final double fromPrice;
  final String estimatedTime;
  final String warranty;
  final String description;
  final List<String> inclusions;
  final String? photo;
  final bool published;
  final int bookingsCount;
  final double rating;

  HmServicePackage({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.fromPrice,
    required this.estimatedTime,
    required this.warranty,
    required this.description,
    required this.inclusions,
    this.photo,
    required this.published,
    required this.bookingsCount,
    required this.rating,
  });

  factory HmServicePackage.fromJson(Map<String, dynamic> j) => HmServicePackage(
        id: hmStr(j["id"]) ?? "",
        categoryId: hmStr(j["category_id"]) ?? "",
        categoryName: hmStr(j["category_name"]) ?? "",
        title: hmStr(j["title"]) ?? "",
        fromPrice: hmDouble(j["from_price"]) ?? 0,
        estimatedTime: hmStr(j["estimated_time"]) ?? "",
        warranty: hmStr(j["warranty"]) ?? "",
        description: hmStr(j["description"]) ?? "",
        inclusions: hmStrList(j["inclusions"]),
        photo: hmStr(j["photo"]),
        published: hmBool(j["published"], true),
        bookingsCount: hmInt(j["bookings_count"]) ?? 0,
        rating: hmDouble(j["rating"]) ?? 0,
      );
}

// ---- Chat & Offers (/seller/muskila/chat/*) --------------------------------

class HmThread {
  final String id;
  final String customerName;
  final String customerAvatar;
  final String serviceTitle;
  final double originalQuote;
  final double currentAgreedPrice;
  final bool isAgreed;
  final bool isEscrowLocked;
  final String problemNature;
  final String requestedTiming;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;

  HmThread({
    required this.id,
    required this.customerName,
    required this.customerAvatar,
    required this.serviceTitle,
    required this.originalQuote,
    required this.currentAgreedPrice,
    required this.isAgreed,
    required this.isEscrowLocked,
    required this.problemNature,
    required this.requestedTiming,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  factory HmThread.fromJson(Map<String, dynamic> j) => HmThread(
        id: hmStr(j["id"]) ?? "",
        customerName: hmStr(j["customer_name"]) ?? "Customer",
        customerAvatar: hmStr(j["customer_avatar"]) ?? "",
        serviceTitle: hmStr(j["service_title"]) ?? "",
        originalQuote: hmDouble(j["original_quote"]) ?? 0,
        currentAgreedPrice: hmDouble(j["current_agreed_price"]) ?? 0,
        isAgreed: hmBool(j["is_agreed"]),
        isEscrowLocked: hmBool(j["is_escrow_locked"]),
        problemNature: hmStr(j["problem_nature"]) ?? "",
        requestedTiming: hmStr(j["requested_timing"]) ?? "",
        lastMessage: hmStr(j["last_message"]) ?? "",
        lastMessageTime: hmStr(j["last_message_time"]) ?? "",
        unreadCount: hmInt(j["unread_count"]) ?? 0,
      );
}

class HmMessage {
  final String id;
  final String sender; // "pro" | "user"
  final String text;
  final String timeText;
  final bool isOffer;
  final double? proposedPrice;
  final String? offerId;
  final bool? isAccepted;
  final String? date;
  final String? slotLabel;

  bool get isMine => sender == "pro";

  HmMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timeText,
    required this.isOffer,
    this.proposedPrice,
    this.offerId,
    this.isAccepted,
    this.date,
    this.slotLabel,
  });

  factory HmMessage.fromJson(Map<String, dynamic> j) => HmMessage(
        id: hmStr(j["id"]) ?? "",
        sender: hmStr(j["sender"]) ?? (hmBool(j["is_from_seller"]) ? "pro" : "user"),
        text: hmStr(j["text"]) ?? "",
        timeText: hmStr(j["time_text"]) ?? hmStr(j["time"]) ?? "",
        isOffer: hmBool(j["is_offer"]),
        proposedPrice: hmDouble(j["proposed_price"] ?? j["offer_amount"]),
        offerId: hmStr(j["offer_id"]),
        isAccepted: j["is_accepted"] == null ? null : hmBool(j["is_accepted"]),
        date: hmStr(j["date"]),
        slotLabel: hmStr(j["slot_label"]),
      );
}

class HmMessagePage extends HmPage<HmMessage> {
  final bool chatOpen;
  final bool hasUnread;

  HmMessagePage(
    super.items,
    super.currentPage,
    super.lastPage, {
    required this.chatOpen,
    required this.hasUnread,
  });
}

// ---- Earnings, Reviews & Notifications -------------------------------------

class HmRelease {
  final String code;
  final String serviceTitle;
  final double yourEarning;
  final double commission;
  final DateTime? releasedAt;

  HmRelease({
    required this.code,
    required this.serviceTitle,
    required this.yourEarning,
    required this.commission,
    this.releasedAt,
  });

  factory HmRelease.fromJson(Map<String, dynamic> j) => HmRelease(
        code: hmStr(j["code"]) ?? "",
        serviceTitle: hmStr(j["service_title"]) ?? "",
        yourEarning: hmDouble(j["your_earning"]) ?? 0,
        commission: hmDouble(j["commission"]) ?? 0,
        releasedAt: hmDate(j["released_at"]),
      );
}

class HmPayout {
  final double amount;
  final String method;
  final String reference;
  final DateTime? paidAt;

  HmPayout({
    required this.amount,
    required this.method,
    required this.reference,
    this.paidAt,
  });

  factory HmPayout.fromJson(Map<String, dynamic> j) => HmPayout(
        amount: hmDouble(j["amount"]) ?? 0,
        method: hmStr(j["method"]) ?? "",
        reference: hmStr(j["reference"]) ?? "",
        paidAt: hmDate(j["paid_at"]),
      );
}

class HmEarnings {
  final String currency;
  final double balanceDue;
  final double paidOut;
  final int pendingBookings;
  final double pendingCustomerTotal;
  final int releasedBookings;
  final double releasedEarning;
  final double releasedCommission;
  final List<HmRelease> recentReleases;
  final List<HmPayout> recentPayments;

  HmEarnings({
    required this.currency,
    required this.balanceDue,
    required this.paidOut,
    required this.pendingBookings,
    required this.pendingCustomerTotal,
    required this.releasedBookings,
    required this.releasedEarning,
    required this.releasedCommission,
    required this.recentReleases,
    required this.recentPayments,
  });

  factory HmEarnings.fromJson(Map<String, dynamic> j) {
    final p = hmMap(j["pending"]);
    final r = hmMap(j["released"]);
    return HmEarnings(
      currency: hmStr(j["currency"]) ?? "OMR",
      balanceDue: hmDouble(j["balance_due"]) ?? 0,
      paidOut: hmDouble(j["paid_out"]) ?? 0,
      pendingBookings: hmInt(p["bookings"]) ?? 0,
      pendingCustomerTotal: hmDouble(p["customer_total"]) ?? 0,
      releasedBookings: hmInt(r["bookings"]) ?? 0,
      releasedEarning: hmDouble(r["your_earning"]) ?? 0,
      releasedCommission: hmDouble(r["commission"]) ?? 0,
      recentReleases:
          hmMapList(j["recent_releases"]).map(HmRelease.fromJson).toList(),
      recentPayments:
          hmMapList(j["recent_payments"]).map(HmPayout.fromJson).toList(),
    );
  }
}

class HmReview {
  final String reviewerName;
  final String dateText;
  final double rating;
  final String comment;
  final String bookingNumber;

  HmReview({
    required this.reviewerName,
    required this.dateText,
    required this.rating,
    required this.comment,
    required this.bookingNumber,
  });

  factory HmReview.fromJson(Map<String, dynamic> j) => HmReview(
        reviewerName: hmStr(j["reviewer_name"]) ?? "Customer",
        dateText: hmStr(j["date_text"]) ?? "",
        rating: hmDouble(j["rating"]) ?? 5,
        comment: hmStr(j["comment"]) ?? "",
        bookingNumber: hmStr(j["booking_number"]) ?? "",
      );
}

class HmNotification {
  final String id;
  final String title;
  final String body;
  final String timeText;
  final bool unread;
  final String type;

  HmNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeText,
    required this.unread,
    required this.type,
  });

  factory HmNotification.fromJson(Map<String, dynamic> j) => HmNotification(
        id: hmStr(j["id"]) ?? "",
        title: hmStr(j["title"]) ?? "",
        body: hmStr(j["body"]) ?? "",
        timeText: hmStr(j["time_text"]) ?? "",
        unread: hmBool(j["unread"]),
        type: hmStr(j["type"]) ?? "",
      );
}

