# Hal-Al Mushkila — Customer App Analysis & Seller App Requirements / Gap Document

**Date:** 26 November 2026  
**Analyzed Codebases:**
- Customer App: `dokan-app/lib/screens/hal_al_muskila/*` & `dokan-app/lib/repositories/muskila_repository.dart`
- Seller App: `dokan-seller-app/lib/hal_al_muskila/*` (benchmarked against `dokan-seller-app/lib/cook_habibi/*`)
- Live API Server Tested: `http://10.10.10.189:8000/api/v2`

---

## 1. Executive Summary & Live Backend Audit

An end-to-end code analysis and live API probe (`customer@example.com`) revealed the following state:

1. **Customer App (`dokan-app`) is API-ready and feature-complete**, covering 38 endpoints under `/api/v2/muskila/*` across Instant Hire, Scheduled Hire, Job Board / Quote Requests, Expert Bargain Posts, Direct Bargaining, Live Chat & Offer Negotiation, Escrow Checkout, Live Tracking, and Customer Sign-off / Rating.
2. **Live Backend Status (`http://10.10.10.189:8000/api/v2`):**
   * **Customer endpoints (`/muskila/*`):** Mostly **LIVE (HTTP 200)** — `/muskila/meta`, `/muskila/home`, `/muskila/pros`, `/muskila/pros/{id}`, `/muskila/pros/{id}/bargain-options`, `/muskila/bookings`, `/muskila/bookings/preview`, `/muskila/posts`, `/muskila/services`, `/muskila/quote-requests`, `/muskila/chat/threads` all return valid JSON envelopes.
   * **Known Live Customer API Bug Found:** `GET /api/v2/muskila/notifications` throws **HTTP 500 TypeError**:
     `MuskilaHelper::isoString(): Argument #1 ($carbon) must be of type ?Carbon\Carbon, string given` in `NotificationResource.php:30`.
   * **All Seller endpoints (`/seller/muskila/*`):** **NOT IMPLEMENTED YET on the backend.** Every tested route (`profile`, `dashboard`, `bookings`, `job-leads`, `earnings`, `application`) returns:
     ```json
     {"data":[],"success":false,"status":404,"message":"Invalid Route"}
     ```
3. **Seller App (`dokan-seller-app`) is currently a UI prototype backed by hardcoded mock fallbacks** in `MuskilaSellerApi`. It lacks onboarding/KYC verification, push notification routing, instant request matching, service catalog management, offer/counter-offer negotiation, schedule/location settings, booking cancellation/rejection, and proper API error handling.
4. **Environment Mismatch:** `dokan-app/lib/app_config.dart` uses `10.10.10.189:8000`, whereas `dokan-seller-app/lib/app_config.dart` currently points to `10.10.10.177:8000`.

---

## 2. How `dokan-app` (Customer Side) Works & Expects the Pro/Seller to Behave

From `muskila_repository.dart`, `muskila_models.dart`, and the live JSON from `/muskila/meta` & `/muskila/pros/1`:

| Customer Feature (`dokan-app`) | Live Data / Behavior Observed | What the Seller App (`dokan-seller-app`) Must Supply |
| :--- | :--- | :--- |
| **Categories & Meta** (`/muskila/meta`) | Uses slug IDs (`ac-cooling`, `electrical`, `plumbing`, `home-cleaning`, `moving-transport`, `appliances-repair`, `tech-setup`, `pest-control`) + `sub_categories` (`split-ac-gas-refill`, etc.) + `service_areas` + `dates`/`slots`. | Pro must pick categories/skills from `/muskila/meta` slugs (currently Seller App defaults `category_id: "1"`). |
| **Pro Discovery & Profile** (`/muskila/pros`, `/pros/{id}`) | Shows `photo`, `profession_title`, `experience_years`, `rating`, `reviews_count`, `jobs_completed`, `on_time_percentage`, `distance_km`, `eta_minutes`, `hourly_rate`, `visit_price`, `online`, `verified`, `fully_verified`, **`verifications` (8 checks)**, **`video` (intro video)**, and **`reviews`**. | KYC upload for the 8 checks (`national_id`, `selfie`, `phone`, `address`, `work_permit`, `trade_licence`, `police_clearance`, `skill_test`), avatar/video upload, bio, GPS coordinates (`lat`/`lng`), and schedule slots. |
| **Instant Hire** (`/muskila/instant-requests`) | Customer picks category, enters `notes`, `offered_price` (OMR 2–20), and `lat`/`lng`; expects an immediate online Pro match within ~30 mins. | Online Pros need an incoming Instant Job alert / queue to **Accept** or **Decline** urgent requests in real time. |
| **Services Catalog** (`/muskila/services`) | Returns fixed/starting-price services (`title`, `from_price`, `inclusions`, `estimated_time`, `warranty`, `photo`). Currently `total: 0` on server. | Seller needs CRUD screens to publish/manage fixed-price service packages. |
| **Job Board & Quotes** (`/posts`, `/quote-requests`) | **Two-way board:**<br>1. **User Requests:** Customer posts problem (`budget_min`/`budget_max`, `image_url`, `location`, `schedule_type`) and collects up to 5 quotes (`pro_name`, `initials`, `rating`, `distance_km`, `team_or_worker_detail`, `price`, `message`, `when_text`).<br>2. **Expert Services:** Pros post fixed/bargainable offers with **`bargain_tiers`** (`price`, `total_quota`, `remaining_quota`, `label`) that customers claim (`POST /posts/{id}/claim-tier`). | 1. Richer Quote submission (`price`, `message`, `when_text`, `team_or_worker_detail`, plus view/edit/withdraw quote).<br>2. Ability for Pros to **publish Expert Service Posts with Bargain Tiers**. |
| **Direct Bargaining** (`/pros/{id}/bargain-options`) | Server returns `tiers` (e.g., Economy `-20%`, Popular `-15%`, Fair `-10%`) and `allow_custom: true`, `min_custom_price: 7.5`. | Pro needs settings to toggle `allow_custom` bargaining and set minimum acceptable rate / discount floor. |
| **Inquiries & Offer Negotiation** (`/inquiries`, `/offers/{id}/accept`, `/counter`, `/chat/*`) | Inquiries include structured `problem_nature`, `custom_problem`, and `timing` (`mode`, `urgent_option`, `date`, `slot_id`). Chat polls every 5s. Offers have `offer_id`, `proposed_price`, `is_accepted`. | Seller Chat must display structured inquiry details, poll in real time, attach `date` & `slot_id` to Pro offers, and allow **Accept / Counter** on customer offers. |
| **Bookings & Escrow** (`/bookings/preview`, `/bookings`, `/tracking`, `/release-escrow`, `/cancel`) | Customer pays `agreed_price` + `platform_fee` (e.g. OMR 0.500) into Escrow with `Idempotency-Key`. Steps: `0` Placed → `1` Accepted/Agreed → `2` On the Way (live `eta_minutes`) → `3` In Progress → `4` Completed. **Customer** triggers `release-escrow` with `rating` + `review`. | Seller advances steps `0→4`, can **Reject/Cancel** pending jobs (triggering customer refund), shares live location/ETA on step 2, and waits for customer sign-off before marking escrow released. |

---

## 3. Critical Bugs & Architectural Issues in Current `dokan-seller-app/lib/hal_al_muskila/`

Before adding new screens, these issues in the existing Seller files must be fixed:

1. **Missing `System-Key` Header (`muskila_seller_api.dart:21-27`)**
   * `MuskilaSellerApi._headers` sends `Accept`, `Content-Type`, `App-Language`, and `Authorization`, but **omits `"System-Key": AppConfig.system_key`**. All Dokan `/api/v2` endpoints require `System-Key` (see `cook_habibi/ch_api.dart:59`).
2. **Silent Error Swallowing & Fake Write Success (`muskila_seller_api.dart`)**
   * `updateBookingStep`, `submitQuote`, `sendMessage`, `updateProfile`, and `setOnlineStatus` wrap HTTP calls in `try { ... } catch (_) {}` and **ignore HTTP status codes**, always returning `true` or mutating in-memory mock lists.
   * It does not check Dokan's HTTP-200 error envelope (`json['success'] == false || json['status'] >= 400`) or trigger `401` session refresh/login redirect, nor does it map `422` validation errors like `ChApiException`.
3. **Incorrect Escrow Release Business Logic (`muskila_seller_api.dart:216`)**
   * Currently: `escrowReleased: step == 4 ? true : list[index].escrowReleased`.
   * **Fix:** Marking a job completed (`step = 4`) does **not** release escrow immediately. In `dokan-app`, escrow stays locked (`escrow_released = false`) until the **customer** approves via `POST /muskila/bookings/{id}/release-escrow` (or admin resolves a dispute).
4. **Missing `Idempotency-Key` on Financial & Step Writes**
   * Unlike `ChApi.newIdempotencyKey()`, `MuskilaSellerApi` sends no `Idempotency-Key` on booking step updates, quote submissions, offer actions, or payouts.
5. **Phone Call Button Does Not Place Calls (`muskila_seller_booking_detail.dart:176`)**
   * Tapping the call icon only shows `muskilaToast("Calling ${_booking.customerPhone}...")` instead of using `url_launcher` (`tel:`) or a masked call endpoint (`POST /seller/muskila/bookings/{id}/call`).
6. **Hardcoded Category & Non-Editable Skills (`muskila_seller_profile.dart:166`)**
   * `category_id` defaults to `"1"` instead of `/muskila/meta` slugs (e.g. `"ac-cooling"`), and `_showEditSheet()` passes `skills: p.skills` without allowing the Pro to add/remove skills or select their category/sub-categories.

---

## 4. Complete Gap Analysis: What Needs to Be Built for Seller App

### 4.1 Onboarding, Application Gate & 8-Point KYC Verification (Priority: P0)
Mirroring `dokan-seller-app/lib/cook_habibi/` (`ChSession`, `ChApplicationStatus`, `ChApply`):
* **Pro Registration / Application Form:** Collect name, phone, category/sub-categories, profession title, hourly/visit rates, bio, service area/GPS, and required documents.
* **Application Status Gate in `MuskilaSellerSession.startScreen()`:** Check `GET /seller/muskila/application`.
  * If `pending` or `rejected` (with `rejection_reason` + `missing_checks` + resubmit flow), route to `MuskilaSellerApplicationStatus` instead of opening the main dashboard.
* **KYC & Media Center Screen:** Match the 8 verification keys returned by `/api/v2/muskila/pros/{id}`:
  * `national_id`, `selfie`, `phone`, `address`, `work_permit`, `trade_licence`, `police_clearance`, `skill_test`
  * Document & photo uploader (`POST /seller/muskila/uploads` multipart) for Avatar photo, KYC documents, and Intro Video (`video`).

### 4.2 Push Notifications (FCM) & In-App Notification Center (Priority: P0)
* **Device Token Registration:** Mirror `ChSession.registerPush()` / `removeDevice()`:
  * `POST /seller/muskila/device` (`device_token`, `device_type`) on login/token refresh (wire into `dokan-seller-app/lib/helpers/push_notification_service.dart`).
  * `DELETE /seller/muskila/device` on logout.
* **Push Deep-Linking in `push_notification_service.dart`:** Handle notification types:
  * `muskila_instant_request` → Open incoming Urgent Job popup
  * `muskila_booking` → Refresh bookings & open `MuskilaSellerBookingDetail`
  * `muskila_job_lead` → Open `MuskilaSellerJobBoardScreen`
  * `muskila_chat_message` / `muskila_offer` → Open `MuskilaSellerConversationScreen`
  * `muskila_escrow_released` → Refresh earnings & open `MuskilaSellerEarningsScreen`
* **In-App Notifications Screen & Bell Badge:** Add notification bell icon to `MuskilaSellerMain` app bar + list/read-all screen (`GET /seller/muskila/notifications`, `POST .../read-all`).

### 4.3 Real-Time Instant Match Receiver (Priority: P0)
* Customer triggers `POST /muskila/instant-requests` with `category_id`, `notes`, `offered_price`, and location.
* Seller App needs:
  * Incoming Instant Request Banner / Modal Sheet (showing customer location, distance km, problem description, offered OMR price, and response countdown).
  * Actions: **Accept Job** (`POST /seller/muskila/instant-requests/{id}/accept`), **Decline** (`POST .../decline`), or **Counter Price** if supported.

### 4.4 Booking Lifecycle Upgrades (Priority: P0)
Enhancements to `MuskilaSellerBookingsScreen` & `MuskilaSellerBookingDetail`:
* **Reject / Cancel Booking:** Allow Pro to decline a `pending` booking or cancel a `scheduled` booking with a reason (`POST /seller/muskila/bookings/{id}/reject`, `POST /seller/muskila/bookings/{id}/cancel`), triggering automatic customer escrow refund.
* **Cancelled Tab / Filter & Reason Display:** Add `"Cancelled"` filter alongside `"Active"` and `"Past"` in `MuskilaSellerBookingsScreen` and show `cancel_reason`.
* **Live GPS Location & ETA Updates:** When advancing to Step 2 (`On The Way`), let the Pro send/update live location & `eta_minutes` (`POST /seller/muskila/bookings/{id}/location`) so the Customer's tracking screen (`GET /muskila/bookings/{id}/tracking`) updates accurately.
* **Direct Booking Actions:**
  * **"Chat with Customer"** button using `booking.threadId` (opening `MuskilaSellerConversationScreen`).
  * **"Call Customer"** wired via `url_launcher` (`tel:`) or masked call (`POST /seller/muskila/bookings/{id}/call`).
  * **"Navigate / Open in Maps"** button using `lat` / `lng` or `location_address`.
* **Accurate Escrow & Rating Display:** On Step 4, display `"Awaiting Customer Sign-Off"` when `escrow_released == false`, and show the customer's `user_rating` & `review` once released.

### 4.5 Two-Way Job Board, Quote Management & Expert Bargain Posts (Priority: P1)
Enhancements to `MuskilaSellerJobBoardScreen`:
* **Rich Job Lead Cards (`MuskilaJobLead` model update):** Add `budget_min`, `budget_max`, `image_url` (zoomable customer problem photo), `created_at_text`, `closes_in_text`, `proposal_count`, `max_quotes`, and `status`.
* **Upgraded Quote Submission Form:** Include `price`, `message`, **`when_text` / available date & slot**, and **`team_or_worker_detail`** (matching `MuskilaQuote` fields displayed in `dokan-app/lib/screens/hal_al_muskila/muskila_quotes_screen.dart`).
* **My Submitted Quotes Management:** View status of submitted quotes (`pending`, `accepted`, `rejected`, `expired`), update, or withdraw a quote before acceptance.
* **Expert Service Posts with Bargain Tiers (New Screen / Tab):**
  * Customers have an `"Expert Services"` tab on `MuskilaJobBoardScreen` showing `author_type == "expert"` posts with **`bargain_tiers`** (`price`, `total_quota`, `remaining_quota`, `label`).
  * Seller needs CRUD for **Expert Service Posts** (`POST /seller/muskila/posts`) with optional discounted bargain tiers and quota limits.

### 4.6 Chat, Structured Inquiries & Offer Negotiation (Priority: P1)
Enhancements to `MuskilaSellerChatScreen` & `MuskilaSellerConversationScreen`:
* **Real-Time Polling & Read Receipts:** Add 5-second `Timer.periodic` polling while a conversation is open (matching `MuskilaChatScreen` in `dokan-app`) and call `POST /seller/muskila/chat/threads/{id}/read`.
* **Inquiry Context Banner:** Display `problem_nature`, `custom_problem`, `requested_timing` (`date`, `slot_id`, or `urgent_option`), `original_quote`, `current_agreed_price`, `is_agreed`, and `is_escrow_locked`.
* **Full Offer / Counter-Offer Flow:**
  * When sending a custom offer, let Pro specify **`amount`**, **`date`**, **`slot_id`**, and **`note`** (matching `counterOffer` in `dokan-app`).
  * If a customer sends a counter-offer (`offer_id`), render **Accept Offer** (`POST /seller/muskila/offers/{id}/accept`) and **Counter** (`POST /seller/muskila/offers/{id}/counter`) buttons directly on the message bubble.

### 4.7 Services Catalog, Bargain Pricing Rules, Schedule & Location (Priority: P1)
* **Services Catalog CRUD (`MuskilaService`):** Screen to create/edit/toggle services (`title`, `category_id`, `from_price`, `description`, `inclusions`, `estimated_time`, `warranty`, `photo`) so `GET /muskila/services` on the customer app is populated.
* **Bargain Settings:** Let Pro toggle `allow_custom_bargaining` and set `min_custom_price` / discount tier limits (backing `GET /muskila/pros/{id}/bargain-options`).
* **Working Schedule & Slot Availability (`PUT /seller/muskila/schedule`):** Manage weekly working hours and block/unblock specific `slots` per day (currently only a single `is_online` toggle exists).
* **Service Location & Coverage Radius (`PUT /seller/muskila/location`):** Map/address selector for Pro base `lat`/`lng`, `service_areas` (from `/muskila/meta`), and max `coverage_radius_km` (used by `dokan-app` to compute `distance_km` and `eta_minutes`).
* **Customer Reviews Screen:** View ratings breakdown (`rating`, `reviews_count`, `on_time_percentage`) and individual `MuskilaProReview` comments.

### 4.8 Earnings, Commission Breakdown & Payouts (Priority: P1)
Enhancements to `MuskilaSellerEarningsScreen`:
* **Dedicated API (`GET /seller/muskila/earnings`):** Stop deriving releases from `bookings.where((b) => b.step == 4)`. Return:
  * `available_balance` (`balance_due`), `paid_out`, `pending_escrow` (with count), `total_earnings` (`gross`, `commission`, `net_earning`), `recent_releases` (with commission fee shown), and `recent_payouts` (payout method, reference, timestamp).
* **Payout Request / Bank Details Screen:** Allow Pro to view/update bank/payout details and request withdrawal (if manual payout is enabled).

---

## 5. Required Backend API Endpoints (`/api/v2/seller/muskila/...`)

All endpoints below require `Accept: application/json`, `System-Key: <key>`, `App-Language: en|ar`, and (except `/muskila/apply`) `Authorization: Bearer <token>`.

### P0 — Core Launch Requirements
| Method | Endpoint | Purpose | Key Request / Response Fields |
| :--- | :--- | :--- | :--- |
| `POST` | `/muskila/apply` | Pro onboarding application | Multipart KYC docs, category slugs, bio, rates, location |
| `GET` | `/seller/muskila/application` | Check application & KYC status | `status` (`pending`/`approved`/`rejected`), `rejection_reason`, `missing_checks` |
| `POST` | `/seller/muskila/application/resubmit` | Resubmit rejected application | Updated fields + upload IDs (`Idempotency-Key`) |
| `POST` | `/seller/muskila/device` | Register FCM push token | `{ "device_token", "device_type": "android"\|"ios" }` |
| `DELETE` | `/seller/muskila/device` | Remove FCM push token | Called on sign-out |
| `GET` | `/seller/muskila/dashboard` | Dashboard KPIs & active summary | `available_balance`, `pending_escrow`, `active_bookings`, `rating`, `is_online`, `unread_chats`, `unread_notifications` |
| `GET` | `/seller/muskila/profile` | Fetch Pro profile & KYC checks | Matches `MuskilaPro` + `verifications[8]` + financial totals |
| `PUT` | `/seller/muskila/profile` | Update Pro profile & bargain rules | `name`, `profession_title`, `category_id`, `skills`, `hourly_rate`, `visit_price`, `bio`, `allow_custom_bargain`, `min_custom_price`, `service_areas`, `lat`, `lng` |
| `POST` | `/seller/muskila/availability` | Toggle online/offline | `{ "is_online": true\|false }` |
| `POST` | `/seller/muskila/uploads` | Upload photo / KYC doc / intro video | `multipart/form-data` (`file`, `type`) → `{ "id", "url" }` |
| `GET` | `/seller/muskila/bookings` | List bookings (`?tab=active\|past\|cancelled`) | Paginated `MuskilaSellerBooking` list incl. `thread_id`, `lat`, `lng`, `cancel_reason`, `user_rating` |
| `GET` | `/seller/muskila/bookings/{id}` | Single booking detail | Full booking record + customer contact + timeline |
| `POST` | `/seller/muskila/bookings/{id}/step` | Advance step (`1`..`4`) | `{ "step", "eta_minutes" }` + `Idempotency-Key` |
| `POST` | `/seller/muskila/bookings/{id}/reject` | Reject pending booking | `{ "reason" }` + `Idempotency-Key` (refunds escrow) |
| `POST` | `/seller/muskila/bookings/{id}/cancel` | Cancel scheduled booking | `{ "reason" }` + `Idempotency-Key` (refunds escrow) |
| `POST` | `/seller/muskila/bookings/{id}/location` | Update Pro live GPS & ETA | `{ "lat", "lng", "eta_minutes" }` |
| `POST` | `/seller/muskila/bookings/{id}/call` | Log/get customer call number | `{ "phone" }` |
| `GET` | `/seller/muskila/instant-requests` | List pending instant jobs nearby | Matches waiting for Pro |
| `POST` | `/seller/muskila/instant-requests/{id}/accept` | Accept instant job (`Idempotency-Key`) | Returns created `booking` |
| `POST` | `/seller/muskila/instant-requests/{id}/decline` | Decline instant job | `{ "reason" }` |

### P1 — Job Board, Negotiation, Services & Earnings
| Method | Endpoint | Purpose | Key Request / Response Fields |
| :--- | :--- | :--- | :--- |
| `GET` | `/seller/muskila/job-leads` | List customer quote requests/posts | Filters: `urgent`, `applied`, `category_id`; includes `budget_min`, `budget_max`, `image_url`, `closes_in` |
| `POST` | `/seller/muskila/quotes` | Submit quote on a job lead | `{ "lead_id", "price", "message", "when_text", "team_or_worker_detail" }` + `Idempotency-Key` |
| `GET` | `/seller/muskila/quotes` | List my submitted quotes & statuses | `pending`, `accepted`, `rejected` |
| `DELETE` | `/seller/muskila/quotes/{id}` | Withdraw pending quote | — |
| `GET` / `POST` / `PUT` / `DELETE` | `/seller/muskila/posts` | Manage Expert Service Posts & Bargain Tiers | `title`, `description`, `category_id`, `is_bargainable`, `bargain_tiers[]`, `image_id` |
| `GET` / `POST` / `PUT` / `DELETE` | `/seller/muskila/services` | Manage fixed/starting Services catalog | `title`, `category_id`, `from_price`, `inclusions`, `estimated_time`, `warranty`, `image_id` |
| `GET` | `/seller/muskila/chat/threads` | List negotiation/chat threads | Includes `is_agreed`, `is_escrow_locked`, `current_agreed_price`, `unread_count` |
| `GET` | `/seller/muskila/chat/threads/{id}/messages` | List messages & offers | Includes `offer_id`, `is_offer`, `proposed_price`, `is_accepted`, `sender` |
| `POST` | `/seller/muskila/chat/threads/{id}/messages` | Send message or offer | `{ "message", "is_offer", "proposed_price", "date", "slot_id" }` |
| `POST` | `/seller/muskila/chat/threads/{id}/read` | Mark thread read | — |
| `POST` | `/seller/muskila/offers/{id}/accept` | Accept customer counter-offer | `Idempotency-Key` |
| `POST` | `/seller/muskila/offers/{id}/counter` | Counter customer offer | `{ "amount", "date", "slot_id", "note" }` + `Idempotency-Key` |
| `PUT` | `/seller/muskila/schedule` | Update weekly hours & slots | Day-wise working slots & availability |
| `GET` | `/seller/muskila/reviews` | Fetch customer reviews & rating stats | Paginated `MuskilaProReview` list |
| `GET` | `/seller/muskila/earnings` | Earnings, escrow & payout ledger | `available_balance`, `pending_escrow`, `paid_out`, `commission`, `recent_releases`, `recent_payouts` |
| `GET` | `/seller/muskila/notifications` | Seller in-app notification feed | Paginated notifications |
| `POST` | `/seller/muskila/notifications/read-all` | Mark all notifications read | — |

---

## 6. Recommended Implementation Roadmap

1. **Phase 1 — Backend & API Client Foundation:**
   * Implement P0 `/seller/muskila/*` endpoints on `dokan` backend (plus fix the `NotificationResource.php:30` `isoString` bug on customer side).
   * Align `dokan-seller-app/lib/app_config.dart` host, fix `System-Key`, error envelope parsing, `Idempotency-Key`, and remove silent mock swallowing from `MuskilaSellerApi`.
2. **Phase 2 — Pro Onboarding, Push & Core Booking Flow:**
   * Add Pro application gate & KYC upload screen (`ChSession` pattern).
   * Register FCM device token & handle push routing in `push_notification_service.dart`.
   * Add Instant Request receiver, Booking Reject/Cancel, `url_launcher` call & map navigation, live ETA update, and fix `escrowReleased` logic.
3. **Phase 3 — Marketplace Growth & Negotiation:**
   * Add Services Catalog CRUD, Expert Posts with Bargain Tiers, Quote management, Offer Accept/Counter + 5s chat polling, Schedule Slots, GPS Coverage Radius, Reviews, and Ledger-backed Earnings screen.

