# Hal-Al Mushkila Seller App (`dokan-seller-app`) — Cook Habibi-Aligned Design & API Guide

**Strict Architectural & UI Reference:** `dokan-seller-app/lib/cook_habibi/` (`ChApi`, `ChModels`, `ChRepository`, `ChSession`, `ChUi`, `ChMain`, `ChKitchenHome`, `ChOrders`, `ChOrderDetail`, `ChOrderChat`, `ChDishes`, `ChDishForm`, `ChStories`, `ChKitchenProfile`, `ChEarningsScreen`, `ChApplicationStatus`)  
**Customer App Contract:** `dokan-app/docs/HAL_AL_MUSKILA_CUSTOMER_APP_API_ANALYSIS.md` (`/api/v2/muskila/*`)  
**Seller API Prefix:** `{AppConfig.BASE_URL}/seller/muskila/...` (plus shared `GET /muskila/meta`)

> **Onboarding Policy (Identical to Cook Habibi):**  
> Pro registration / onboarding **does NOT exist inside the mobile app**. Pros apply / are created on the **Admin / Web Dashboard**. On launch, `HmSession.startScreen()` calls `GET /seller/muskila/application` and routes `pending` / `rejected` accounts to `HmApplicationStatus` until approved.

---

## 1. API Client, Headers, Errors & Idempotency (`hm_api.dart` ↔ `ch_api.dart`)

Mirror `ChApi` (`lib/cook_habibi/ch_api.dart`) 1-to-1:

### 1.1 Headers on Every Request
| Header | Value | Notes |
|---|---|---|
| `Accept` | `application/json` | Always sent. |
| `System-Key` | `AppConfig.system_key` (`123456`) | Required on every `/api/v2` call. |
| `App-Language` | `app_language.$ ?? AppConfig.default_language` | `en` or `ar`. |
| `Content-Type` | `application/json` | Omit on `multipart/form-data` uploads. |
| `Authorization` | `Bearer ${access_token.$}` | Required on all `/seller/muskila/*` endpoints. |
| `Idempotency-Key` | `HmApi.newIdempotencyKey()` (UUID v4) | Sent on booking step actions, instant accept, reject/cancel, quote submit, offer accept/counter, chat message send, expert post publish, and application resubmit. |

### 1.2 Error & Pagination Handling
* `HmApiException(int status, String message, Map<String, List<String>> errors)` with `fieldError(String field)`.
* Check both HTTP status (`>= 400`) **and** Dokan's HTTP-200 error body (`json["status"] >= 400 || json["success"] == false || json["result"] == false`).
* `401` / `403` (unless `signOutOnAuthError: false` in `HmSession.startScreen` / `getStatus`): clear user session and route to `Login()`.
* `409`: request with same `Idempotency-Key` still running — keep key and retry after 2–3s.
* `422`: show `message` and bind `errors` onto form inputs via `fieldError()`.
* Never catch write errors silently or mutate local mock state on API failure.
* Paginated responses use `HmPage<T>(items, currentPage, lastPage)` (`hasMore => currentPage < lastPage`).

---

## 2. File Structure (`lib/hal_al_muskila/` ↔ `lib/cook_habibi/`)

| Hal Al Mushkila File | Cook Habibi Counterpart | Responsibility |
|---|---|---|
| `hm_api.dart` | `ch_api.dart` | HTTP `get`/`post`/`put`/`delete`/`multipart`, UUID v4 `Idempotency-Key`, `HmApiException`, `HmPage<T>` |
| `hm_models.dart` | `ch_models.dart` | Safe parsers (`hmStr`, `hmInt`, `hmDouble`, `hmBool`, `hmDate`, `hmMap`), all Seller & Customer-synced models |
| `hm_repository.dart` | `ch_repository.dart` | Typed repository methods (`_data`, `_message`, `_page`) for all `/seller/muskila/*` endpoints |
| `hm_session.dart` | `ch_session.dart` | `startScreen()` gate, `registerPush()`, `signOut()`, `getStatus()` for `ServiceChooser` |
| `hm_ui.dart` | `ch_ui.dart` | `hmMoney()`, `hmDateTime()`, `hmToast()`, `hmToastError()`, `hmErrorText()`, `hmPickImage()`, `HmCard`, `HmErrorView`, `HmEmptyView`, `HmPill.status()`, `HmButton`, `hmAppBar()`, `hmInput()`, `HmNetImage` |
| `screens/hm_application_status.dart` | `ch_application_status.dart` | Pending / Rejected gate + 8 KYC checks + Resubmit |
| `screens/hm_main.dart` | `ch_main.dart` | Single clean shell: solid `MyTheme.navy` AppBar + `ServiceChooser` switcher + `HmHome` |
| `screens/hm_home.dart` | `ch_kitchen_home.dart` | Navy Hero + Online Switch + Instant Alert + Shortcuts Card + Money Card + Settings Card |
| `screens/hm_instant_requests_sheet.dart` | *(HM-specific)* | Incoming `/muskila/instant-requests` urgent job modal (Accept / Decline) |
| `screens/hm_bookings.dart` | `ch_orders.dart` | Tabbed bookings (`Active`, `Scheduled`, `Completed`, `Cancelled`) + `hmBookingsRefreshTick` |
| `screens/hm_booking_detail.dart` | `ch_order_detail.dart` | `next_actions`-driven action buttons, `Chat with customer`, Call, Maps, Live ETA/GPS, Escrow status |
| `screens/hm_chat.dart` | `ch_order_chat.dart` | Thread list + `ChOrderChat`-style reversed paginated chat + 15s polling + `hmChatPushThreadId` + Offer Accept/Counter |
| `screens/hm_job_board.dart` | `ch_orders.dart` + `ch_stories.dart` | Tabbed Job Leads (Send Quote), My Quotes (Edit/Withdraw), Expert Bargain Posts |
| `screens/hm_services.dart` | `ch_dishes.dart` | Tabbed Services (`Published`, `Hidden`, `Waiting approval`) + `_ServiceListState.refreshAll()` |
| `screens/hm_service_form.dart` | `ch_dish_form.dart` | Create / Edit fixed service package (`from_price`, `inclusions`, `estimated_time`, `warranty`, photo) |
| `screens/hm_profile.dart` | `ch_kitchen_profile.dart` | Partial-diff `PUT /profile` + `/muskila/meta` category/skills + bargain floor + `HmScheduleScreen` + `HmLocationScreen` + `HmKycScreen` |
| `screens/hm_reviews.dart` | *(HM-specific)* | Customer ratings & review list (`GET /seller/muskila/reviews`) |
| `screens/hm_earnings.dart` | `ch_earnings.dart` | Solid `MyTheme.navy` balance card + Pending/Released boxes + Recent releases/payments |
| `screens/hm_notifications.dart` | *(HM-specific)* | In-app notifications list + Mark all read |

---

## 3. UI Design Tokens (`hm_ui.dart` ↔ `ch_ui.dart`)

* **Background:** `MyTheme.paper` everywhere.
* **Cards (`HmCard`):** `Material(color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MyTheme.radius_card), side: BorderSide(color: MyTheme.hairline)))`.
* **Buttons (`HmButton`):** `48px` height, full width, `MyTheme.radius_control`, solid `MyTheme.navy` or `outlined: true`, `20x20` spinner when `busy == true`.
* **Status Pills (`HmPill.status`):**
  * `placed` / `pending` / `urgent` → `MyTheme.amber_soft` + `MyTheme.amber_ink`
  * `completed` / `released` / `approved` → `Color(0xFFE2F3EC)` + `MyTheme.green`
  * `cancelled` / `rejected` / `refunded` → `Color(0xFFFBE7E4)` + `MyTheme.red`
  * `active` / `scheduled` / default → `MyTheme.blue_tint` + `MyTheme.navy`
* **Money Formatting:** `hmMoney(v, currency)` → `"OMR 25.000"` (always 3 decimals).
* **Sub-screen AppBar (`hmAppBar`):** White, flat (`elevation: 0`), `1px MyTheme.hairline` bottom border, `MyTheme.ink` title & back arrow (`AppTheme.lightStatusBar`).
* **Image Picker (`hmPickImage`):** Camera / Gallery bottom sheet, `imageQuality: 80`, `maxWidth: 1600`, **5 MB** limit check.

---

## 4. Session, `ServiceChooser` & Push Notifications (`hm_session.dart` + `push_notification_service.dart`)

### 4.1 `HmSession` (`ch_session.dart` Pattern)
1. **`startScreen()`:**
   * Calls `GET /seller/muskila/application` with `signOutOnAuthError: false`.
   * If `app.id != null && !app.isApproved` → returns `HmApplicationStatus(initial: app)`.
   * Otherwise returns `const HmMain()`.
2. **`getStatus()`** (for `ServiceChooser` card):
   * Checks `GET /seller/muskila/application`: `pending` → `"Application under review"` (`MyTheme.amber_ink`); `rejected` → `"Application needs changes"` (`MyTheme.red`).
   * Checks `GET /seller/muskila/dashboard`: `is_online` → `"Online, X active booking(s)"` (`MyTheme.green`) or `"Offline"` (`MyTheme.dark_grey`).
   * Returns `null` silently on error so non-Pro sellers see no noise.
3. **`registerPush()` & `signOut()`:**
   * Calls `POST /seller/muskila/device` (`device_token`, `device_type`) on startup & `onTokenRefresh`.
   * Calls `DELETE /seller/muskila/device` before clearing `access_token` on sign-out.

### 4.2 Push Notification Wiring (`push_notification_service.dart`)
Mirror `_isCookOrder` / `_isCookChat` / `_openCookOrder` / `_openCookChat`:
* Foreground `onMessage`:
  * `data['type'] == 'muskila_booking'` or `'muskila_instant_request'` → `hmBookingsRefreshTick.value++`
  * `data['type'] == 'muskila_chat'` or `'muskila_offer'` → `hmChatPushThreadId.value = null; hmChatPushThreadId.value = threadId;`
* Tap / `onMessageOpenedApp` / `getInitialMessage`:
  * `muskila_instant_request` → Open `HmInstantRequestsSheet`
  * `muskila_booking` → Open `HmBookingDetail(bookingId: data['booking_id'])`
  * `muskila_chat` / `muskila_offer` → Open `HmThreadChat(threadId: data['thread_id'])`
  * `muskila_job_lead` → Open `HmJobBoardScreen()`
  * `muskila_escrow` → Open `HmEarningsScreen()`

---

## 5. Screen-by-Screen Design & API Integration

---

### Screen 1: `HmApplicationStatus` (`ch_application_status.dart` Clone)
* **Layout:** White flat AppBar (`leading: Icons.apps_rounded` -> `ServiceChooser`, `title: "Your application"`, `action: "Sign out"`).
* **Cards:**
  * `HmCard`: Pro/Business Name (`AppTheme.display(20)`), `HmPill` (`"Under review"` / `"Not approved"`), `"Applied <date>"`.
  * If `isPending`: `HmCard` explaining review + `"Waiting for: ..."` mapping the 8 KYC checks from `dokan-app` (`national_id`, `selfie`, `phone`, `address`, `work_permit`, `trade_licence`, `police_clearance`, `skill_test`).
  * If `isRejected`: `HmCard` with `"Reason"`, Outlined `HmButton("Fix my profile details")` → `HmProfileScreen`, Solid `HmButton("Send for review again")` (when `canResubmit == true`, uses `Idempotency-Key`).
* **APIs:** `GET /seller/muskila/application`, `POST /seller/muskila/application/resubmit`.

---

### Screen 2: `HmMain` & `HmHome` (`hm_main.dart` + `hm_home.dart`)
> **Design Alignment Note:** Hal Al Mushkila's service workflow (Bookings, Job Leads/Quotes, Services, Live Offer Chat, Instant Match) differs from Cook Habibi's kitchen/dish workflow. Therefore, `HmMain` keeps Hal Al Mushkila's **4-tab `NavigationBar`** (`Home`, `Bookings`, `Job Board`, `Profile` — as already designed in `muskila_seller_main.dart`) for quick field access, while adopting **Cook Habibi's visual & engineering standards**: solid `MyTheme.navy` AppBar/Hero, flat `MyTheme.paper` background, `HmCard` (`1px MyTheme.hairline`), `HmPill.status`, `HmButton`, `ServiceChooser` switcher (`Icons.apps_rounded`), and `HmErrorView` / `HmEmptyView`.

* **`HmMain` AppBar (`MyTheme.navy`, `ChMain` Style):**
  * Leading: `Icons.apps_rounded` (`ServiceChooser.open`)
  * Title: `"Hal Al Mushkila"` (white, 18px w600)
  * Actions: Notifications icon (unread dot) → `HmNotificationsScreen`, Messages icon (unread badge) → `HmChatScreen`, Day & Date column (`CustomDateTime.getDayName` / `getDate`).
* **`HmHome` (`RefreshIndicator` + `ListView`, `ChKitchenHome` Design Language):**
  1. **Solid Navy Hero (`Container(color: MyTheme.navy)`):**
     * Top tappable row (→ `HmEarningsScreen`): `"Hello, ${profile.name}"`, `"Earnings today"` (or `"Available balance"`) + `AppTheme.figure(48–64, Colors.white)` + `"OMR"` + `48x48` `MyTheme.amber` circle (`Icons.arrow_forward_rounded`).
     * Bottom 3 stat columns (`AppTheme.figure(28–32, Colors.white)`): `"Active jobs"` (→ Bookings tab), `"New leads"` (→ Job Board tab), `"Rating"` (→ `HmReviewsScreen`).
  2. **Error / Suspended Cards:** Inline `HmCard` retry on error; `MyTheme.amber_soft` banner if `profile.isSuspended`.
  3. **Instant Request Alert (when `dash.pendingInstantCount > 0`):** `MyTheme.amber_soft` `HmCard` → opens `HmInstantRequestsSheet`.
  4. **Online / Availability Card (`_openCard` clone):** `10px` green/red dot, `"Online for jobs"` / `"Offline for jobs"`, `Switch` calling `POST /seller/muskila/availability`.
  5. **`Shortcuts` Card (`_surface` card, 4 tiles in a row with `MyTheme.blue_tint` `48x48` boxes):**
     * `Bookings` → Tab 1 (`HmBookingsScreen`)
     * `Job Board` → Tab 2 (`HmJobBoardScreen`)
     * `Services` → `HmServicesScreen`
     * `Earnings` → `HmEarningsScreen`
  6. **Active Bookings & New Leads Previews:** Top 2–3 cards (`HmCard`) with `"See all"` switching tabs.
  7. **`Money` Card (`_surface` grouped rows with `Divider(indent: 16, endIndent: 16)`):**
     * `Balance due` → `hmMoney(dash.balanceDue)` → `HmEarningsScreen`
     * `Locked in escrow` → `${hmMoney(dash.pendingEscrow)}` → `HmEarningsScreen`
     * `Completed jobs` → `"${dash.completedJobs} jobs"` → Bookings tab (`Completed`)
     * `Reviews` → `"${dash.reviewsCount} reviews"` → `HmReviewsScreen`
  8. **`Settings` Card (`_surface` grouped rows):**
     * `Specialist profile` (`"Details, photo, category, rates & bargain floor"`) → Tab 3 (`HmProfileScreen`)
     * `Working hours & slots` (`"Set the days and slots you work"`) → `HmScheduleScreen`
     * `Service area & GPS` (`"Coverage areas, map pin & radius"`) → `HmLocationScreen`
     * `KYC verification` (`"8 verification checks & intro video"`) → `HmKycScreen`
* **APIs:** `GET /seller/muskila/dashboard`, `GET /seller/muskila/profile`, `POST /seller/muskila/availability`.

---

### Screen 3: `HmInstantRequestsSheet` (Pairs with `dokan-app` `POST /muskila/instant-requests`)
* **UI:** Rounded bottom sheet (`MyTheme.radius_sheet`) showing urgent `HmPill.status("urgent", "INSTANT REQUEST")`, countdown timer, customer location (`distance_km`), problem notes, offered OMR price (`AppTheme.figure(28)`), `HmButton("Accept Instant Job")` (`Idempotency-Key`), `HmButton("Decline", outlined: true, color: MyTheme.red)`.
* **APIs:** `GET /seller/muskila/instant-requests`, `POST .../accept`, `POST .../decline`.

---

### Screen 4: `HmBookingsScreen` & `HmBookingDetail` (`ch_orders.dart` + `ch_order_detail.dart` Clone)
* **`HmBookingsScreen`:**
  * White AppBar + `TabBar`: `Active` / `Scheduled` / `Completed` / `Cancelled`.
  * Paginated `_BookingList` (`HmPage<HmBooking>`), `AutomaticKeepAliveClientMixin`, `hmBookingsRefreshTick` listener, 1-second timer for accept countdowns.
  * `_BookingTile` (`HmCard`): `#BK-1001`, `HmPill.status`, Escrow badge, `hmMoney`, `serviceTitle`, `customerName • scheduledDateText`.
* **`HmBookingDetail` (`next_actions`-driven, identical to `ChOrderDetail`):**
  * **Card 1 (Summary):** `HmPill.status`, source pill (`Instant`/`Direct`/`Quote`/`Offer`/`Bargain`), accept countdown, `serviceTitle`, `scheduledDateText` & `scheduledTimeSlot`, `MyTheme.amber_soft` note box.
  * **Card 2 (Customer):** `person_outline`, `phone_outlined` (tap copies + `url_launcher` `tel:` via `POST .../call`), `place_outlined` (tap opens Google Maps `lat,lng`).
  * **Card 3 (Amounts & Escrow):** `Service fee`, `Platform fee`, `Customer paid`, `Your earning` (`"After release"` until `escrow_released == true`, then green `hmMoney`), `Payment: ${escrow_status}`, `user_rating` & review when released.
  * **Cancel Reason Card (if cancelled):** Red text inside `HmCard`.
  * **Chat Button:** Outlined `HmButton("Chat with customer")` → pushes `HmThreadChat(threadId: booking.threadId, bookingId: booking.id)` (`ChOrderChat` pattern!).
  * **Dynamic Action Buttons (ONLY `booking.nextActions`, each using `_keys.putIfAbsent(action, HmApi.newIdempotencyKey)`):**
    - `accept` → `HmButton("Accept booking")`
    - `on-the-way` → ETA picker dialog (`10/15/20/30 mins`) + sends GPS → `POST .../on-the-way`
    - `start-work` → `HmButton("Start work")`
    - `complete` → `HmButton("Mark job completed")` *(moves to `step = 4`, waits for customer `/release-escrow`)*
    - `reject` / `cancel` → Outlined red `HmButton` with reason dialog (`refunds customer`).
  * **Live Tracking Heartbeat:** When `step == 2`, periodically posts `POST /seller/muskila/bookings/{id}/location` (`lat`, `lng`, `eta_minutes`) so `dokan-app`'s 15s tracking poll updates live.
* **APIs:** `GET /seller/muskila/bookings`, `GET /seller/muskila/bookings/{id}`, `POST /seller/muskila/bookings/{id}/{action}`, `POST /seller/muskila/bookings/{id}/location`, `POST /seller/muskila/bookings/{id}/call`.

---

### Screen 5: `HmChatScreen` & `HmThreadChat` (`ch_order_chat.dart` Clone + Offer Negotiation)
Mirror `ChOrderChat` (`ch_order_chat.dart`) **1-to-1** for reliability, plus `dokan-app` Offer cards:
* **Thread List (`HmChatScreen`):** `HmCard` list with customer avatar, `serviceTitle`, `Agreed: OMR X` / `Escrow Locked` pill, last message, unread count pill.
* **Conversation (`HmThreadChat`):**
  * **Reversed `ListView` (`newest first` at index 0)**, `page + 1` scroll-up pagination, **15-second `Timer.periodic` polling** + `ValueNotifier<String?> hmChatPushThreadId` listener + auto `markThreadRead`.
  * **Pinned Inquiry / Price Header (`HmCard`):** `Original Quote`, `Current Agreed Price`, customer `problem_nature`, `requested_timing`, `Escrow Locked` status.
  * **Message Bubbles:**
    - `isMine` (`sender == "pro"`): `MyTheme.navy` bubble, white text.
    - Customer (`sender == "user"`): white bubble with `MyTheme.hairline` border.
    - **Offer Bubble (`is_offer == true`):** `MyTheme.blue_tint` card showing `proposed_price` (OMR), `date` & `slot`, `is_accepted` status; if customer sent a counter-offer (`!isMine && offerId != null && isAccepted == null`), shows **`Accept`** & **`Counter`** buttons directly on the card!
  * **Composer Bar (`_maxLength = 1000`):** `+` button opens **Send Custom Offer** dialog (`amount`, `date`, `slot_id` from `/meta`, `note`); Send button uses `_sendKey` / `_sendKeyText` `Idempotency-Key` so retries never duplicate messages; disabled when `!chatOpen`.
* **APIs:** `GET /seller/muskila/chat/threads`, `GET .../messages`, `POST .../messages`, `POST .../read`, `POST /seller/muskila/offers/{id}/accept`, `POST /seller/muskila/offers/{id}/counter`.

---

### Screen 6: `HmJobBoardScreen` (Leads, My Quotes & Expert Bargain Posts)
* **3 Tabs (White AppBar + `MyTheme.navy` `TabBar`):**
  1. **Job Leads:** Filter chips (`All`, `Urgent`, `Unquoted`). `HmCard` with `budget_min`–`budget_max`, `closes_in_text`, `quotes_received / max_quotes`, problem photo thumbnail, `"Send Quote"` sheet (`price`, `date`/`slot_id`, `when_text`, `team_or_worker_detail`, `message` + `Idempotency-Key`).
  2. **My Quotes:** Sent quotes with status (`Pending`/`Accepted`/`Rejected`/`Expired`), Edit & Withdraw (`PUT`/`DELETE /quotes/{id}`).
  3. **Expert Posts (`ChStories`-style CRUD):** Pro's own `author_type == "expert"` posts with photo (`POST /uploads`), `is_bargainable`, and `bargain_tiers[]` (`label`, `price`, `total_quota`, live `remaining_quota` synced with `dokan-app`'s `claim-tier`).
* **APIs:** `GET /seller/muskila/job-leads`, `GET/POST/PUT/DELETE /seller/muskila/quotes`, `GET/POST/PUT/DELETE /seller/muskila/posts`, `POST /seller/muskila/uploads`.

---

### Screen 7: `HmServicesScreen` & `HmServiceForm` (`ch_dishes.dart` + `ch_dish_form.dart` Clone)
* **Tabs:** `Published`, `Hidden`, `Waiting approval` + `FloatingActionButton.extended("New service")` + `_ServiceListState.refreshAll()`.
* **Form Fields (matching `dokan-app`'s `MuskilaService`):** Photo (`POST /uploads` -> `upload_id`), Category slug (`/muskila/meta`), `title`, `from_price`, `estimated_time`, `warranty`, `description`, `inclusions[]`, `published` switch. (Delete returns `422` if bookings exist → offer Hide instead).
* **APIs:** `GET/POST/PUT/DELETE /seller/muskila/services`, `POST /seller/muskila/services/{id}/status`.

---

### Screen 8: `HmProfileScreen`, `HmScheduleScreen`, `HmLocationScreen`, `HmKycScreen`, `HmReviewsScreen`
* **`HmProfileScreen` (`ChKitchenProfile` clone):**
  * Partial-diff save: compares `_valueOf(k)` vs `_originalOf(k)` and sends **only changed fields** to `PUT /seller/muskila/profile`, displaying `422` `fieldError()` per input.
  * Edits: Avatar & Intro Video (`POST /uploads`), `name`, `profession_title`, `category_id` & `skills[]` (from `/muskila/meta`), `visit_price`, `hourly_rate`, `experience_years`, `bio`, `allow_custom_bargain` switch, `min_custom_price` (OMR floor for `dokan-app`'s `bargain-options`).
* **`HmScheduleScreen` (`ChScheduleScreen` clone):** Day-wise toggles (`Sat`–`Fri`) + slot selection from `meta.schedule.slots` (`PUT /seller/muskila/schedule`).
* **`HmLocationScreen`:** `service_areas[]` (from `/meta`), `lat`, `lng`, `coverage_radius_km` (`PUT /seller/muskila/location`).
* **`HmKycScreen`:** Status + document upload for the 8 checks (`national_id`, `selfie`, `phone`, `address`, `work_permit`, `trade_licence`, `police_clearance`, `skill_test`).
* **`HmReviewsScreen`:** Rating summary + paginated `HmCard` reviews (`GET /seller/muskila/reviews`).

---

### Screen 9: `HmEarningsScreen` (`ch_earnings.dart` Exact Clone)
* **UI:**
  1. Solid `MyTheme.navy` card (`"Balance due to you"`, `hmMoney(e.balanceDue)` in `34pt`, `"Paid out so far: ..."`, `"Payouts are made by the admin office."`).
  2. 2-col `HmCard` row: `Pending` (`"${e.pendingBookings} jobs"`, `"Customers paid ... Your share is known after release."`) and `Released` (`hmMoney(e.releasedEarning)`, `"${e.releasedBookings} jobs · commission ..."`).
  3. `Recent releases` list (`HmCard` rows with code, date, `+OMR`, `fee OMR`).
  4. `Recent payments` list (`HmCard` rows with method, reference, date, `OMR`).
* **API:** `GET /seller/muskila/earnings`.

---

### Screen 10: `HmNotificationsScreen`
* Flat white `hmAppBar` + `"Mark all read"` action + paginated `HmCard` feed.
* **APIs:** `GET /seller/muskila/notifications`, `POST /seller/muskila/notifications/read-all`.

---

## 6. Complete Backend API Checklist (`/api/v2/seller/muskila/...`)

| Priority | Group | Method & Endpoint | Key Payload / Response |
| :---: | :--- | :--- | :--- |
| **P0** | Meta | `GET /muskila/meta` | *(Already live)* Categories, sub-categories, service areas, schedule slots |
| **P0** | Gate | `GET /seller/muskila/application` | `{ id, pro_name, status, applied_at, rejection_reason, can_resubmit, missing_checks[] }` |
| **P0** | Gate | `POST /seller/muskila/application/resubmit` | `Idempotency-Key` → updated `application` |
| **P0** | Push | `POST / DELETE /seller/muskila/device` | `{ device_token, device_type }` |
| **P0** | Uploads | `POST /seller/muskila/uploads` | `multipart/form-data` (`file`, `type`) → `{ upload_id, url }` |
| **P0** | Dashboard | `GET /seller/muskila/dashboard` | `currency`, `balance_due`, `earnings_today`, `pending_escrow`, `bookings_today`, `active_bookings`, `completed_jobs`, `rating`, `reviews_count`, `is_online`, `unread_chats`, `unread_notifications`, `pending_instant_count` |
| **P0** | Availability | `POST /seller/muskila/availability` | `{ is_online: bool }` |
| **P0** | Instant Hire | `GET /seller/muskila/instant-requests` | Pending urgent requests near Pro |
| **P0** | Instant Hire | `POST /seller/muskila/instant-requests/{id}/accept\|decline` | `Idempotency-Key` → `{ booking }` |
| **P0** | Bookings | `GET /seller/muskila/bookings?tab=&page=` | Paginated `HmPage<HmBooking>` |
| **P0** | Bookings | `GET /seller/muskila/bookings/{id}` | Single `HmBooking` (`next_actions[]`, `amounts`, `escrow_released`, `thread_id`, `lat`, `lng`) |
| **P0** | Bookings | `POST /seller/muskila/bookings/{id}/{action}` | `accept\|on-the-way\|start-work\|complete\|reject\|cancel` + `Idempotency-Key` |
| **P0** | Tracking | `POST /seller/muskila/bookings/{id}/location` | `{ lat, lng, eta_minutes }` |
| **P0** | Call | `POST /seller/muskila/bookings/{id}/call` | `{ phone }` |
| **P1** | Job Board | `GET /seller/muskila/job-leads?filter=&page=` | Paginated `HmPage<HmJobLead>` |
| **P1** | Quotes | `GET / POST /seller/muskila/quotes` & `PUT / DELETE .../quotes/{id}` | `{ lead_id, price, message, when_text, date?, slot_id?, team_or_worker_detail }` |
| **P1** | Expert Posts | `GET / POST / PUT / DELETE /seller/muskila/posts` | `{ title, description, category_id, image_id, is_bargainable, bargain_tiers[] }` |
| **P1** | Services | `GET / POST / PUT / DELETE /seller/muskila/services` & `POST .../status` | `{ title, category_id, from_price, description, inclusions[], estimated_time, warranty, image_id, published }` |
| **P1** | Chat & Offers | `GET /seller/muskila/chat/threads` | Paginated `HmPage<HmThread>` |
| **P1** | Chat & Offers | `GET / POST /seller/muskila/chat/threads/{id}/messages` | Reversed `HmMessagePage` (`chat_open`, `has_unread`, `items[]`) + `Idempotency-Key` |
| **P1** | Chat & Offers | `POST /seller/muskila/chat/threads/{id}/read` | Marks messages read |
| **P1** | Chat & Offers | `POST /seller/muskila/offers/{id}/accept\|counter` | `Idempotency-Key`, `{ amount, date, slot_id, note }` |
| **P1** | Profile | `GET / PUT /seller/muskila/profile` | Partial diff fields + `is_suspended`, `verifications[8]`, bargain rules |
| **P1** | Schedule | `PUT /seller/muskila/schedule` | Weekly day/slot map |
| **P1** | Location | `PUT /seller/muskila/location` | `{ lat, lng, location_label, service_areas[], radius_km }` |
| **P1** | Reviews | `GET /seller/muskila/reviews?page=` | Paginated `HmPage<HmReview>` |
| **P1** | Earnings | `GET /seller/muskila/earnings` | `balance_due`, `paid_out`, `pending`, `released`, `recent_releases[]`, `recent_payouts[]` |
| **P1** | Notifications | `GET /seller/muskila/notifications` & `POST .../read-all` | Paginated `HmPage<HmNotification>` |
