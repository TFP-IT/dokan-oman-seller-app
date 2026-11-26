String mStr(dynamic v, [String fallback = '']) => v?.toString() ?? fallback;

double mNum(dynamic v, [double fallback = 0.0]) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? fallback;
}

int mInt(dynamic v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

bool mBool(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

Map<String, dynamic> mMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> mMaps(dynamic v) =>
    v is List ? v.whereType<Map>().map(mMap).toList() : const [];

List<String> mStrings(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

/// Profile of the Service Pro / Specialist in Hal Al Mushkila
class MuskilaSellerProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatar;
  final String categoryId;
  final String categoryName;
  final String professionTitle;
  final double hourlyRate;
  final double visitPrice;
  final int experienceYears;
  final double rating;
  final int reviewsCount;
  final int jobsCompleted;
  final bool isOnline;
  final bool isVerified;
  final String bio;
  final List<String> skills;
  final double totalEarnings;
  final double pendingEscrow;
  final double availableBalance;

  const MuskilaSellerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatar,
    required this.categoryId,
    required this.categoryName,
    required this.professionTitle,
    required this.hourlyRate,
    required this.visitPrice,
    required this.experienceYears,
    required this.rating,
    required this.reviewsCount,
    required this.jobsCompleted,
    required this.isOnline,
    required this.isVerified,
    required this.bio,
    required this.skills,
    required this.totalEarnings,
    required this.pendingEscrow,
    required this.availableBalance,
  });

  factory MuskilaSellerProfile.fromJson(Map<String, dynamic> j) =>
      MuskilaSellerProfile(
        id: mStr(j['id']),
        name: mStr(j['name'], 'Professional Pro'),
        email: mStr(j['email']),
        phone: mStr(j['phone']),
        avatar: mStr(j['avatar']),
        categoryId: mStr(j['category_id'], '1'),
        categoryName: mStr(j['category_name'], 'Home Repair & Maintenance'),
        professionTitle: mStr(j['profession_title'], 'Master Technician'),
        hourlyRate: mNum(j['hourly_rate'], 15.0),
        visitPrice: mNum(j['visit_price'], 5.0),
        experienceYears: mInt(j['experience_years'], 5),
        rating: mNum(j['rating'], 4.9),
        reviewsCount: mInt(j['reviews_count'], 48),
        jobsCompleted: mInt(j['jobs_completed'], 126),
        isOnline: mBool(j['is_online']),
        isVerified: mBool(j['is_verified']),
        bio: mStr(j['bio'],
            'Certified expert technician providing top quality on-demand maintenance and home services.'),
        skills: mStrings(j['skills']).isNotEmpty
            ? mStrings(j['skills'])
            : ['Electrical', 'Plumbing', 'AC Repair', 'Appliance Fix'],
        totalEarnings: mNum(j['total_earnings'], 1845.50),
        pendingEscrow: mNum(j['pending_escrow'], 125.00),
        availableBalance: mNum(j['available_balance'], 420.00),
      );

  MuskilaSellerProfile copyWith({
    String? name,
    String? professionTitle,
    String? categoryName,
    double? hourlyRate,
    double? visitPrice,
    int? experienceYears,
    bool? isOnline,
    String? bio,
    List<String>? skills,
  }) =>
      MuskilaSellerProfile(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone,
        avatar: avatar,
        categoryId: categoryId,
        categoryName: categoryName ?? this.categoryName,
        professionTitle: professionTitle ?? this.professionTitle,
        hourlyRate: hourlyRate ?? this.hourlyRate,
        visitPrice: visitPrice ?? this.visitPrice,
        experienceYears: experienceYears ?? this.experienceYears,
        rating: rating,
        reviewsCount: reviewsCount,
        jobsCompleted: jobsCompleted,
        isOnline: isOnline ?? this.isOnline,
        isVerified: isVerified,
        bio: bio ?? this.bio,
        skills: skills ?? this.skills,
        totalEarnings: totalEarnings,
        pendingEscrow: pendingEscrow,
        availableBalance: availableBalance,
      );
}

/// A service order/booking booked by a customer with escrow
class MuskilaSellerBooking {
  final String id;
  final String bookingNumber;
  final String customerName;
  final String customerPhone;
  final String customerAvatar;
  final String serviceTitle;
  final String categoryName;
  final String scheduledDate;
  final String scheduledTimeSlot;
  final String locationAddress;
  final String notes;
  final double price;
  final double escrowAmount;
  final int step; // 0: Pending, 1: Accepted, 2: On The Way, 3: In Progress, 4: Completed
  final String status; // 'pending', 'scheduled', 'in_progress', 'completed', 'cancelled'
  final bool escrowReleased;

  const MuskilaSellerBooking({
    required this.id,
    required this.bookingNumber,
    required this.customerName,
    required this.customerPhone,
    required this.customerAvatar,
    required this.serviceTitle,
    required this.categoryName,
    required this.scheduledDate,
    required this.scheduledTimeSlot,
    required this.locationAddress,
    this.notes = '',
    required this.price,
    required this.escrowAmount,
    this.step = 0,
    required this.status,
    this.escrowReleased = false,
  });

  factory MuskilaSellerBooking.fromJson(Map<String, dynamic> j) =>
      MuskilaSellerBooking(
        id: mStr(j['id']),
        bookingNumber: mStr(j['booking_number'], 'BK-${j['id'] ?? '1001'}'),
        customerName: mStr(j['customer_name'], 'Customer'),
        customerPhone: mStr(j['customer_phone'], '+968 9123 4567'),
        customerAvatar: mStr(j['customer_avatar']),
        serviceTitle: mStr(j['service_title'], 'General Service'),
        categoryName: mStr(j['category_name'], 'Maintenance'),
        scheduledDate: mStr(j['scheduled_date'], 'Today'),
        scheduledTimeSlot: mStr(j['scheduled_time_slot'], '10:00 AM - 12:00 PM'),
        locationAddress: mStr(j['location_address'], 'Muscat, Oman'),
        notes: mStr(j['notes']),
        price: mNum(j['price'], 25.0),
        escrowAmount: mNum(j['escrow_amount'], 25.0),
        step: mInt(j['step'], 0).clamp(0, 4),
        status: mStr(j['status'], 'pending'),
        escrowReleased: mBool(j['escrow_released']),
      );

  MuskilaSellerBooking copyWith({
    int? step,
    String? status,
    bool? escrowReleased,
  }) =>
      MuskilaSellerBooking(
        id: id,
        bookingNumber: bookingNumber,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAvatar: customerAvatar,
        serviceTitle: serviceTitle,
        categoryName: categoryName,
        scheduledDate: scheduledDate,
        scheduledTimeSlot: scheduledTimeSlot,
        locationAddress: locationAddress,
        notes: notes,
        price: price,
        escrowAmount: escrowAmount,
        step: step ?? this.step,
        status: status ?? this.status,
        escrowReleased: escrowReleased ?? this.escrowReleased,
      );
}

/// A customer job post on the Hal Al Mushkila job board
class MuskilaJobLead {
  final String id;
  final String title;
  final String categoryName;
  final String customerName;
  final String location;
  final String preferredSchedule;
  final String description;
  final double budget;
  final int proposalCount;
  final bool isUrgent;
  final String createdAt;
  final bool hasApplied;

  const MuskilaJobLead({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.customerName,
    required this.location,
    required this.preferredSchedule,
    required this.description,
    required this.budget,
    required this.proposalCount,
    this.isUrgent = false,
    required this.createdAt,
    this.hasApplied = false,
  });

  factory MuskilaJobLead.fromJson(Map<String, dynamic> j) => MuskilaJobLead(
        id: mStr(j['id']),
        title: mStr(j['title']),
        categoryName: mStr(j['category_name'], 'General'),
        customerName: mStr(j['customer_name'], 'Customer'),
        location: mStr(j['location'], 'Muscat'),
        preferredSchedule: mStr(j['preferred_schedule'], 'Immediate'),
        description: mStr(j['description']),
        budget: mNum(j['budget'], 30.0),
        proposalCount: mInt(j['proposal_count'], 0),
        isUrgent: mBool(j['is_urgent']),
        createdAt: mStr(j['created_at'], 'Just now'),
        hasApplied: mBool(j['has_applied']),
      );

  MuskilaJobLead copyWith({bool? hasApplied, int? proposalCount}) =>
      MuskilaJobLead(
        id: id,
        title: title,
        categoryName: categoryName,
        customerName: customerName,
        location: location,
        preferredSchedule: preferredSchedule,
        description: description,
        budget: budget,
        proposalCount: proposalCount ?? this.proposalCount,
        isUrgent: isUrgent,
        createdAt: createdAt,
        hasApplied: hasApplied ?? this.hasApplied,
      );
}

/// Negotiation thread between customer and pro
class MuskilaSellerThread {
  final String id;
  final String customerName;
  final String customerAvatar;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final String serviceTitle;
  final double? agreedPrice;

  const MuskilaSellerThread({
    required this.id,
    required this.customerName,
    required this.customerAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    required this.serviceTitle,
    this.agreedPrice,
  });

  factory MuskilaSellerThread.fromJson(Map<String, dynamic> j) =>
      MuskilaSellerThread(
        id: mStr(j['id']),
        customerName: mStr(j['customer_name'], 'Customer'),
        customerAvatar: mStr(j['customer_avatar']),
        lastMessage: mStr(j['last_message']),
        lastMessageTime: mStr(j['last_message_time'], 'Today'),
        unreadCount: mInt(j['unread_count'], 0),
        serviceTitle: mStr(j['service_title'], 'Service Discussion'),
        agreedPrice: j['agreed_price'] != null ? mNum(j['agreed_price']) : null,
      );
}

/// Chat message in negotiation thread
class MuskilaSellerMessage {
  final String id;
  final String threadId;
  final bool isFromSeller;
  final String text;
  final String time;
  final bool isOffer;
  final double? offerAmount;

  const MuskilaSellerMessage({
    required this.id,
    required this.threadId,
    required this.isFromSeller,
    required this.text,
    required this.time,
    this.isOffer = false,
    this.offerAmount,
  });

  factory MuskilaSellerMessage.fromJson(Map<String, dynamic> j) =>
      MuskilaSellerMessage(
        id: mStr(j['id']),
        threadId: mStr(j['thread_id']),
        isFromSeller: mBool(j['is_from_seller']),
        text: mStr(j['text']),
        time: mStr(j['time'], 'Now'),
        isOffer: mBool(j['is_offer']),
        offerAmount: j['offer_amount'] != null ? mNum(j['offer_amount']) : null,
      );
}
