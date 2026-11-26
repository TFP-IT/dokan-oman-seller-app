import 'dart:convert';
import 'package:active_ecommerce_seller_app/app_config.dart';
import 'package:active_ecommerce_seller_app/hal_al_muskila/muskila_seller_models.dart';
import 'package:active_ecommerce_seller_app/helpers/shared_value_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MuskilaSellerApi {
  static final MuskilaSellerApi instance = MuskilaSellerApi._();
  MuskilaSellerApi._();

  static const _timeout = Duration(seconds: 12);

  // In-memory cache & state for live updates
  MuskilaSellerProfile? _profile;
  List<MuskilaSellerBooking>? _bookings;
  List<MuskilaJobLead>? _leads;
  List<MuskilaSellerThread>? _threads;
  final Map<String, List<MuskilaSellerMessage>> _messagesMap = {};

  Map<String, String> get _headers => {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "App-Language": app_language.$ ?? "en",
        if (access_token.$ != null && access_token.$!.isNotEmpty)
          "Authorization": "Bearer ${access_token.$}",
      };

  // ---------------- Profile & Availability ----------------

  Future<MuskilaSellerProfile> getProfile() async {
    if (_profile != null) return _profile!;
    try {
      final uri = Uri.parse("${AppConfig.BASE_URL}/seller/muskila/profile");
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['data'] != null) {
          _profile = MuskilaSellerProfile.fromJson(mMap(j['data']));
          return _profile!;
        }
      }
    } catch (e) {
      debugPrint("MuskilaSellerApi: getProfile error: $e");
    }

    // Default Profile
    _profile ??= MuskilaSellerProfile(
      id: "pro_101",
      name: "Ahmed Al-Mamari",
      email: "ahmed.pro@dokan.om",
      phone: "+968 9876 5432",
      avatar: "",
      categoryId: "1",
      categoryName: "Home Maintenance & AC Repair",
      professionTitle: "Certified HVAC & Electrical Specialist",
      hourlyRate: 18.0,
      visitPrice: 5.0,
      experienceYears: 6,
      rating: 4.9,
      reviewsCount: 52,
      jobsCompleted: 142,
      isOnline: true,
      isVerified: true,
      bio: "Licensed expert in air conditioning servicing, domestic electrical systems, and plumbing installations across Muscat.",
      skills: ["Split AC Maintenance", "Central HVAC", "Wiring & Fusebox", "Water Pump Repair"],
      totalEarnings: 2150.00,
      pendingEscrow: 175.00,
      availableBalance: 520.00,
    );
    return _profile!;
  }

  Future<bool> setOnlineStatus(bool online) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(isOnline: online);
    }
    try {
      final uri = Uri.parse("${AppConfig.BASE_URL}/seller/muskila/availability");
      await http
          .post(uri, headers: _headers, body: jsonEncode({"is_online": online}))
          .timeout(_timeout);
      return true;
    } catch (_) {
      return true; // Local update succeeded
    }
  }

  Future<MuskilaSellerProfile> updateProfile({
    required String name,
    required String professionTitle,
    required double hourlyRate,
    required double visitPrice,
    required String bio,
    required List<String> skills,
  }) async {
    _profile = (_profile ?? await getProfile()).copyWith(
      name: name,
      professionTitle: professionTitle,
      hourlyRate: hourlyRate,
      visitPrice: visitPrice,
      bio: bio,
      skills: skills,
    );

    try {
      final uri = Uri.parse("${AppConfig.BASE_URL}/seller/muskila/profile");
      await http
          .put(uri,
              headers: _headers,
              body: jsonEncode({
                "name": name,
                "profession_title": professionTitle,
                "hourly_rate": hourlyRate,
                "visit_price": visitPrice,
                "bio": bio,
                "skills": skills,
              }))
          .timeout(_timeout);
    } catch (_) {}

    return _profile!;
  }

  // ---------------- Bookings / Service Orders ----------------

  Future<List<MuskilaSellerBooking>> getBookings({bool refresh = false}) async {
    if (!refresh && _bookings != null) return _bookings!;

    try {
      final uri = Uri.parse("${AppConfig.BASE_URL}/seller/muskila/bookings");
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['data'] is List) {
          _bookings = mMaps(j['data']).map(MuskilaSellerBooking.fromJson).toList();
          return _bookings!;
        }
      }
    } catch (e) {
      debugPrint("MuskilaSellerApi: getBookings error: $e");
    }

    _bookings ??= [
      const MuskilaSellerBooking(
        id: "bk_1",
        bookingNumber: "BK-8841",
        customerName: "Salim Al-Harthy",
        customerPhone: "+968 9123 4567",
        customerAvatar: "",
        serviceTitle: "Split AC Gas Refill & Filter Clean",
        categoryName: "AC Maintenance",
        scheduledDate: "Today",
        scheduledTimeSlot: "02:00 PM - 04:00 PM",
        locationAddress: "Villa 42, Way 2814, Al Ghubrah North, Muscat",
        notes: "AC is blowing warm air in the master bedroom. Please bring R410A gas.",
        price: 28.00,
        escrowAmount: 28.00,
        step: 1, // Accepted
        status: "scheduled",
        escrowReleased: false,
      ),
      const MuskilaSellerBooking(
        id: "bk_2",
        bookingNumber: "BK-8835",
        customerName: "Fatima Al-Balushi",
        customerPhone: "+968 9234 5678",
        customerAvatar: "",
        serviceTitle: "Kitchen Sink Leak & Pipe Replacement",
        categoryName: "Plumbing",
        scheduledDate: "Today",
        scheduledTimeSlot: "05:00 PM - 07:00 PM",
        locationAddress: "Azaiba Beach Road, Building 14, Apt 302",
        notes: "Under-sink pipe joint is dripping. Water valve turned off.",
        price: 20.00,
        escrowAmount: 20.00,
        step: 0, // Pending Acceptance
        status: "pending",
        escrowReleased: false,
      ),
      const MuskilaSellerBooking(
        id: "bk_3",
        bookingNumber: "BK-8790",
        customerName: "Khalfan Al-Riyami",
        customerPhone: "+968 9345 6789",
        customerAvatar: "",
        serviceTitle: "Main Circuit Breaker Tripping Diagnostic",
        categoryName: "Electrical",
        scheduledDate: "Yesterday",
        scheduledTimeSlot: "11:00 AM - 01:00 PM",
        locationAddress: "Mawaleh South, Street 18, Muscat",
        notes: "Replaced faulty 32A MCB breaker. All circuits verified.",
        price: 35.00,
        escrowAmount: 35.00,
        step: 4, // Completed
        status: "completed",
        escrowReleased: true,
      ),
    ];

    return _bookings!;
  }

  Future<MuskilaSellerBooking> updateBookingStep(String bookingId, int step) async {
    final list = await getBookings();
    final index = list.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      String status = list[index].status;
      if (step == 1) status = "scheduled";
      if (step == 2 || step == 3) status = "in_progress";
      if (step == 4) status = "completed";

      final updated = list[index].copyWith(
        step: step,
        status: status,
        escrowReleased: step == 4 ? true : list[index].escrowReleased,
      );
      list[index] = updated;

      try {
        final uri = Uri.parse("${AppConfig.BASE_URL}/seller/muskila/bookings/$bookingId/step");
        await http
            .post(uri, headers: _headers, body: jsonEncode({"step": step, "status": status}))
            .timeout(_timeout);
      } catch (_) {}

      return updated;
    }
    throw Exception("Booking not found");
  }

  // ---------------- Job Board / Leads ----------------

  Future<List<MuskilaJobLead>> getJobLeads({bool refresh = false}) async {
    if (!refresh && _leads != null) return _leads!;

    try {
      final uri = Uri.parse("${AppConfig.BASE_URL}/seller/muskila/job-leads");
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['data'] is List) {
          _leads = mMaps(j['data']).map(MuskilaJobLead.fromJson).toList();
          return _leads!;
        }
      }
    } catch (e) {
      debugPrint("MuskilaSellerApi: getJobLeads error: $e");
    }

    _leads ??= [
      const MuskilaJobLead(
        id: "lead_1",
        title: "Complete 2-Ton Inverter AC Installation",
        categoryName: "AC Maintenance",
        customerName: "Mohammed Al-Zadjali",
        location: "Al Khoudh, Seeb",
        preferredSchedule: "Tomorrow Morning",
        description: "New OGeneral 2 ton split AC ready in box. Need wall bracket mounted, piping connected, vacuum pumped and tested.",
        budget: 35.00,
        proposalCount: 2,
        isUrgent: true,
        createdAt: "10 mins ago",
        hasApplied: false,
      ),
      const MuskilaJobLead(
        id: "lead_2",
        title: "Water Pump Pressure Switch Repair",
        categoryName: "Plumbing & Pumps",
        customerName: "Rashid Al-Kindi",
        location: "Bawshar, Muscat",
        preferredSchedule: "Flexible this weekend",
        description: "Roof tank booster pump won't turn off automatically. Pressure switch may need calibration or replacement.",
        budget: 25.00,
        proposalCount: 4,
        isUrgent: false,
        createdAt: "1 hour ago",
        hasApplied: false,
      ),
      const MuskilaJobLead(
        id: "lead_3",
        title: "Living Room Chandelier & LED Spotlight Wiring",
        categoryName: "Electrical",
        customerName: "Tariq Al-Habsi",
        location: "Al Hail South",
        preferredSchedule: "Thursday Afternoon",
        description: "Install 1 crystal chandelier (approx 8kg) and replace 6 dimmable warm-white ceiling spotlights.",
        budget: 40.00,
        proposalCount: 1,
        isUrgent: false,
        createdAt: "3 hours ago",
        hasApplied: false,
      ),
    ];

    return _leads!;
  }

  Future<bool> submitQuote({
    required String leadId,
    required double price,
    required String message,
  }) async {
    final leads = await getJobLeads();
    final index = leads.indexWhere((l) => l.id == leadId);
    if (index != -1) {
      leads[index] = leads[index].copyWith(
        hasApplied: true,
        proposalCount: leads[index].proposalCount + 1,
      );
    }

    try {
      final uri = Uri.parse("${AppConfig.BASE_URL}/seller/muskila/quotes");
      await http
          .post(uri,
              headers: _headers,
              body: jsonEncode({"lead_id": leadId, "price": price, "message": message}))
          .timeout(_timeout);
    } catch (_) {}

    return true;
  }

  // ---------------- Chat & Negotiations ----------------

  Future<List<MuskilaSellerThread>> getChatThreads() async {
    if (_threads != null) return _threads!;

    try {
      final uri = Uri.parse("${AppConfig.BASE_URL}/seller/muskila/chat/threads");
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['data'] is List) {
          _threads = mMaps(j['data']).map(MuskilaSellerThread.fromJson).toList();
          return _threads!;
        }
      }
    } catch (e) {
      debugPrint("MuskilaSellerApi: getChatThreads error: $e");
    }

    _threads ??= [
      const MuskilaSellerThread(
        id: "th_1",
        customerName: "Salim Al-Harthy",
        customerAvatar: "",
        lastMessage: "I will be home at 2 PM. See you then!",
        lastMessageTime: "12:45 PM",
        unreadCount: 1,
        serviceTitle: "Split AC Gas Refill & Filter Clean",
        agreedPrice: 28.00,
      ),
      const MuskilaSellerThread(
        id: "th_2",
        customerName: "Fatima Al-Balushi",
        customerAvatar: "",
        lastMessage: "Can you make it OMR 18 for the pipe fix?",
        lastMessageTime: "11:15 AM",
        unreadCount: 0,
        serviceTitle: "Kitchen Sink Leak & Pipe Replacement",
        agreedPrice: 20.00,
      ),
    ];

    return _threads!;
  }

  Future<List<MuskilaSellerMessage>> getMessages(String threadId) async {
    if (_messagesMap.containsKey(threadId)) {
      return _messagesMap[threadId]!;
    }

    try {
      final uri =
          Uri.parse("${AppConfig.BASE_URL}/seller/muskila/chat/threads/$threadId/messages");
      final res = await http.get(uri, headers: _headers).timeout(_timeout);
      if (res.statusCode == 200) {
        final j = jsonDecode(res.body);
        if (j['data'] is List) {
          final list = mMaps(j['data']).map(MuskilaSellerMessage.fromJson).toList();
          _messagesMap[threadId] = list;
          return list;
        }
      }
    } catch (_) {}

    final initial = [
      MuskilaSellerMessage(
        id: "msg_1",
        threadId: threadId,
        isFromSeller: false,
        text: "Hello Ahmed, are you available for AC maintenance today?",
        time: "12:10 PM",
      ),
      MuskilaSellerMessage(
        id: "msg_2",
        threadId: threadId,
        isFromSeller: true,
        text: "Hello! Yes, I have an open slot between 2:00 PM and 4:00 PM in Al Ghubrah.",
        time: "12:15 PM",
      ),
      MuskilaSellerMessage(
        id: "msg_3",
        threadId: threadId,
        isFromSeller: false,
        text: "Sounds great. What will the total cost be for gas refill and cleaning?",
        time: "12:20 PM",
      ),
      MuskilaSellerMessage(
        id: "msg_4",
        threadId: threadId,
        isFromSeller: true,
        text: "Official quote with full coil wash and R410A top-up is OMR 28.00 with 30-day warranty.",
        time: "12:25 PM",
        isOffer: true,
        offerAmount: 28.00,
      ),
      MuskilaSellerMessage(
        id: "msg_5",
        threadId: threadId,
        isFromSeller: false,
        text: "I will be home at 2 PM. See you then!",
        time: "12:45 PM",
      ),
    ];

    _messagesMap[threadId] = initial;
    return initial;
  }

  Future<MuskilaSellerMessage> sendMessage({
    required String threadId,
    required String text,
    bool isOffer = false,
    double? offerAmount,
  }) async {
    final msg = MuskilaSellerMessage(
      id: "msg_${DateTime.now().millisecondsSinceEpoch}",
      threadId: threadId,
      isFromSeller: true,
      text: text,
      time: "Just now",
      isOffer: isOffer,
      offerAmount: offerAmount,
    );

    _messagesMap[threadId] ??= [];
    _messagesMap[threadId]!.add(msg);

    try {
      final uri =
          Uri.parse("${AppConfig.BASE_URL}/seller/muskila/chat/threads/$threadId/messages");
      await http
          .post(uri,
              headers: _headers,
              body: jsonEncode({
                "text": text,
                "is_offer": isOffer,
                "offer_amount": offerAmount,
              }))
          .timeout(_timeout);
    } catch (_) {}

    return msg;
  }
}
