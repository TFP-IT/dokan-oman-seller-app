# Hal-Al Mushkila Seller App — Backend API Specification (`/api/v2/seller/muskila/...`)

**Prepared For:** Backend Engineering Team (`dokan` Laravel API)  
**Aligned With:**
- Seller App Design: `dokan-seller-app/docs/HAL_AL_MUSKILA_SELLER_APP_DESIGN_AND_API.md`
- Customer App Live API: `/api/v2/muskila/*` (`10.10.10.189:8000`)
- Seller Architecture Standard: `Cook Habibi` (`/api/v2/seller/cook-habibi/*`)

> **Onboarding Note:** Pro registration / onboarding happens on the **Admin / Web Dashboard**, NOT in the mobile app. The mobile app only checks application/KYC status (`GET /seller/muskila/application`) and gates access until approved.

---

## 1. Global Conventions, Headers & Envelopes

* **Base URL:** `{DOMAIN}/api/v2/seller/muskila`
* **Required Request Headers:**
  ```http
  Accept: application/json
  System-Key: <system_key>
  App-Language: en | ar
  Authorization: Bearer <seller_access_token>
  Content-Type: application/json          (omit for multipart/form-data)
  Idempotency-Key: <uuid-v4>              (required on state-mutating POSTs marked below)
  ```
* **Success Envelope (Single Resource / Action):**
  ```json
  { "result": true, "success": true, "status": 200, "message": "Booking updated.", "data": { } }
  ```
* **Paginated List Envelope (20 per page, `?page=1`):**
  ```json
  {
    "result": true,
    "success": true,
    "status": 200,
    "data": [ ],
    "links": { "first": "...", "last": "...", "prev": null, "next": null },
    "meta": { "current_page": 1, "last_page": 1, "per_page": 20, "total": 0 }
  }
  ```
* **Error Envelope (`401`, `403`, `404`, `409`, `422`):**
  ```json
  {
    "result": false,
    "success": false,
    "status": 422,
    "message": "Validation failed.",
    "errors": { "min_custom_price": ["Must be at least 1.000 OMR."] }
  }
  ```
  * **`401`**: Unauthenticated / expired token.
  * **`403`**: Authenticated, but user is not a Hal-Al Mushkila Pro or profile is suspended.
  * **`409`**: Same `Idempotency-Key` request is currently in-flight.
  * **`422`**: Validation or business-rule violation.
  * **Idempotency Replay:** If the same `Idempotency-Key` succeeded earlier, return the original response with header `Idempotent-Replayed: true`.

---

## 2. Shared Meta & Media Uploads

### 2.1 Shared Metadata *(Already Live on Customer Route)*
* `GET /api/v2/muskila/meta` — Reused by Seller App to populate `categories` (`ac-cooling`, `electrical`, etc.), `sub_categories`, `service_areas`, and `schedule.slots`.

### 2.2 Upload Image / Document / Video (`P0`)
* **Endpoint:** `POST /api/v2/seller/muskila/uploads`
* **Content-Type:** `multipart/form-data`
* **Fields:** `file` (max 5 MB for images; video/KYC doc limit per server config), `type` (`avatar` | `video` | `kyc_doc` | `service_photo` | `post_photo`)
* **Response (`201`):**
  ```json
  {
    "result": true, "success": true, "status": 201,
    "data": { "upload_id": 142, "url": "https://.../uploads/142.jpg" }
  }
  ```

---

## 3. Application Gate & Push Device (`P0`)

### 3.1 Check Application Status
* **Endpoint:** `GET /api/v2/seller/muskila/application`
* **Response (`200`):**
  ```json
  {
    "result": true, "success": true, "status": 200,
    "data": {
      "id": 12,
      "pro_name": "Ahmed AC Services",
      "status": "pending",
      "applied_at": "2026-11-26T10:00:00+04:00",
      "rejection_reason": null,
      "can_resubmit": false,
      "missing_checks": ["national_id", "work_permit", "trade_licence"]
    }
  }
  ```
  * `status`: `"pending"` | `"approved"` | `"rejected"`.
  * `missing_checks` keys match `/api/v2/muskila/pros/{id}`: `national_id`, `selfie`, `phone`, `address`, `work_permit`, `trade_licence`, `police_clearance`, `skill_test`.

### 3.2 Resubmit Rejected Application
* **Endpoint:** `POST /api/v2/seller/muskila/application/resubmit` *(Requires `Idempotency-Key`)*
* **Body:** `{}` (or updated document upload IDs)
* **Response (`200`):** Returns updated `application` object with `status: "pending"`.

### 3.3 Register / Remove FCM Push Token
* **Register:** `POST /api/v2/seller/muskila/device`
  * **Body:** `{ "device_token": "<FCM>", "device_type": "android" | "ios" }`
* **Remove (Sign-out):** `DELETE /api/v2/seller/muskila/device`

---

## 4. Dashboard & Online Availability (`P0`)

### 4.1 Get Pro Dashboard
* **Endpoint:** `GET /api/v2/seller/muskila/dashboard`
* **Response (`200`):**
  ```json
  {
    "result": true, "success": true, "status": 200,
    "data": {
      "currency": "OMR",
      "earnings_today": 35.000,
      "balance_due": 420.000,
      "pending_escrow": 125.000,
      "pending_escrow_count": 3,
      "bookings_today": 2,
      "active_bookings": 2,
      "completed_jobs": 24,
      "job_leads_count": 5,
      "rating": 4.8,
      "reviews_count": 12,
      "is_online": true,
      "is_suspended": false,
      "unread_chats": 1,
      "unread_notifications": 2,
      "pending_instant_count": 1
    }
  }
  ```

### 4.2 Toggle Online / Offline
* **Endpoint:** `POST /api/v2/seller/muskila/availability`
* **Body:** `{ "is_online": true }`
* **Business Rule:** Controls `online` flag returned in Customer App's `GET /muskila/pros` and determines eligibility for `POST /muskila/instant-requests`.
* **Response (`200`):** `{ "result": true, "success": true, "status": 200, "message": "You are now online.", "data": { "is_online": true } }`

---

## 5. Instant Match Requests (`P0`)
*(Pairs directly with Customer App's `POST /api/v2/muskila/instant-requests`)*

### 5.1 List Pending Instant Requests
* **Endpoint:** `GET /api/v2/seller/muskila/instant-requests`
* **Response (`200`):**
  ```json
  {
    "result": true, "success": true, "status": 200,
    "data": [
      {
        "id": "inst_45",
        "category_id": "ac-cooling",
        "category_name": "AC & Cooling",
        "customer_name": "Salim Al-Harthy",
        "location_text": "Al Ghubrah, Muscat",
        "lat": 23.5932,
        "lng": 58.4137,
        "distance_km": 1.8,
        "notes": "AC leaking water urgently",
        "offered_price": 10.000,
        "expires_at": "2026-11-26T15:05:00+04:00"
      }
    ]
  }
  ```

### 5.2 Accept / Decline Instant Request
* **Accept:** `POST /api/v2/seller/muskila/instant-requests/{id}/accept` *(Requires `Idempotency-Key`)*
  * **Business Rule:** Locks request atomically (first Pro to accept wins; return `422` if already taken/expired) and returns created `{ "booking": { ... } }`.
* **Decline:** `POST /api/v2/seller/muskila/instant-requests/{id}/decline`
  * **Body:** `{ "reason": "Busy right now" }` (optional)

---

## 6. Bookings, Tracking, Reject/Cancel & Call (`P0`)
*(Synchronized with Customer App's `GET /muskila/bookings`, `/tracking`, `/release-escrow`, `/cancel`)*

### 6.1 List Bookings
* **Endpoint:** `GET /api/v2/seller/muskila/bookings?tab=active|scheduled|completed|cancelled&page=1`
* **Response (`200`, Paginated):** Each item matches:
  ```json
  {
    "id": "101",
    "booking_number": "BK-8841",
    "source": "instant",
    "status": "active",
    "status_title": "On The Way",
    "step": 2,
    "service_title": "Split AC Maintenance",
    "category_name": "AC & Cooling",
    "customer_name": "Salim Al-Harthy",
    "customer_phone": "+968 9123 4567",
    "customer_avatar": "",
    "scheduled_date_text": "Today",
    "scheduled_time_slot": "02:00 PM - 04:00 PM",
    "location_address": "Villa 42, Al Ghubrah, Muscat",
    "lat": 23.5932,
    "lng": 58.4137,
    "notes": "Master bedroom AC",
    "eta_minutes": 12,
    "price": 15.000,
    "platform_fee": 0.500,
    "escrow_amount": 15.000,
    "your_earning": null,
    "escrow_status": "held",
    "escrow_released": false,
    "user_rating": null,
    "user_review": null,
    "cancel_reason": null,
    "thread_id": "th_12",
    "accept_deadline": "2026-11-26T15:15:00+04:00",
    "next_actions": ["start-work"],
    "created_at": "2026-11-26T14:40:00+04:00"
  }
  ```

### 6.2 Booking Detail
* **Endpoint:** `GET /api/v2/seller/muskila/bookings/{id}`
* **Response (`200`):** Single `booking` object in `data`.

### 6.3 Booking Step Actions *(All require `Idempotency-Key`)*
Only actions present in `next_actions` are permitted (`422` otherwise):

| Action | Endpoint | Request Body | State Transition & Business Rule |
| :--- | :--- | :--- | :--- |
| `accept` | `POST .../bookings/{id}/accept` | `{}` | `step` `0 → 1` (`scheduled` or `active`) |
| `on-the-way` | `POST .../bookings/{id}/on-the-way` | `{ "eta_minutes": 15, "lat": 23.58, "lng": 58.38 }` | `step` `1 → 2` (`active`). Updates ETA for Customer `/tracking`. |
| `start-work` | `POST .../bookings/{id}/start-work` | `{}` | `step` `2 → 3` (`active`). |
| `complete` | `POST .../bookings/{id}/complete` | `{}` | `step` `3 → 4` (`completed`). **IMPORTANT:** Do **NOT** set `escrow_released = true` here! Escrow stays `held` until Customer calls `POST /muskila/bookings/{id}/release-escrow` (or Admin releases). |
| `reject` | `POST .../bookings/{id}/reject` | `{ "reason": "..." }` | Allowed at `step == 0`. Marks `cancelled` and **refunds Customer wallet**. |
| `cancel` | `POST .../bookings/{id}/cancel` | `{ "reason": "..." }` | Allowed at `step == 1`. Marks `cancelled` and **refunds Customer wallet**. |

### 6.4 Live GPS / ETA Update
* **Endpoint:** `POST /api/v2/seller/muskila/bookings/{id}/location`
* **Body:** `{ "lat": 23.5880, "lng": 58.3829, "eta_minutes": 8 }`
* **Response (`200`):** `{ "eta_minutes": 8 }` (Fed directly to Customer's `GET /muskila/bookings/{id}/tracking`).

### 6.5 Call Customer
* **Endpoint:** `POST /api/v2/seller/muskila/bookings/{id}/call`
* **Response (`200`):** `{ "data": { "phone": "+968 9123 4567" } }`

---

## 7. Job Leads, Quotes & Expert Bargain Posts (`P1`)

### 7.1 List Customer Job Leads
* **Endpoint:** `GET /api/v2/seller/muskila/job-leads?filter=all|urgent|unquoted&page=1`
* **Response (`200`, Paginated):**
  ```json
  {
    "id": "post_88",
    "title": "Split AC Gas Refill",
    "description": "Not cooling since morning.",
    "category_id": "ac-cooling",
    "category_name": "AC & Cooling",
    "customer_name": "Mohammed Al-Zadjali",
    "location": "Al Khoudh, Seeb",
    "distance_km": 3.2,
    "preferred_schedule": "Today",
    "budget_min": 10.000,
    "budget_max": 25.000,
    "image_url": "https://.../issue.jpg",
    "is_urgent": true,
    "proposal_count": 2,
    "max_quotes": 5,
    "has_applied": false,
    "closes_in_text": "1h 20m",
    "created_at_text": "10 mins ago"
  }
  ```

### 7.2 Submit / List / Edit / Withdraw Quotes
* **List My Quotes:** `GET /api/v2/seller/muskila/quotes?page=1`
* **Submit Quote:** `POST /api/v2/seller/muskila/quotes` *(Requires `Idempotency-Key`)*
  * **Body:**
    ```json
    {
      "lead_id": "post_88",
      "price": 18.000,
      "message": "Can visit today with R410A gas and 30-day warranty.",
      "when_text": "Today, 02:00 PM - 04:00 PM",
      "date": "2026-11-26",
      "slot_id": "slot_2",
      "team_or_worker_detail": "Master Tech + 1 Helper"
    }
    ```
  * *(Feeds directly into Customer App's `GET /muskila/quote-requests/{id}` `MuskilaQuote` list!)*
* **Update / Withdraw Quote:** `PUT /api/v2/seller/muskila/quotes/{id}` & `DELETE /api/v2/seller/muskila/quotes/{id}` (allowed while `status == "pending"`).

### 7.3 Expert Service Posts with Bargain Tiers
*(Feeds Customer App's `GET /muskila/posts?author_type=expert` and `POST /muskila/posts/{id}/claim-tier`)*
* **List My Posts:** `GET /api/v2/seller/muskila/posts?page=1`
* **Create Post:** `POST /api/v2/seller/muskila/posts` *(Requires `Idempotency-Key`)*
  * **Body:**
    ```json
    {
      "category_id": "ac-cooling",
      "title": "Seasonal Dual Split AC Deep Service",
      "description": "Full indoor + outdoor pressure wash & gas check.",
      "location": "Muscat",
      "preferred_schedule": "Same Day",
      "image_id": 142,
      "is_bargainable": true,
      "bargain_tiers": [
        { "label": "Early Bird (20% Off)", "price": 16.000, "total_quota": 5 },
        { "label": "Standard Deal (10% Off)", "price": 18.000, "total_quota": 10 }
      ]
    }
    ```
* **Update / Delete Post:** `PUT /api/v2/seller/muskila/posts/{id}` & `DELETE /api/v2/seller/muskila/posts/{id}`

---

## 8. Services Catalog (`P1`)
*(Populates Customer App's `GET /api/v2/muskila/services`)*

* **List:** `GET /api/v2/seller/muskila/services?status=published|hidden|pending_approval&page=1`
* **Create:** `POST /api/v2/seller/muskila/services`
  * **Body:**
    ```json
    {
      "category_id": "ac-cooling",
      "title": "Split AC Deep Cleaning",
      "from_price": 12.000,
      "estimated_time": "1-2 hours",
      "warranty": "30 Days DOKAN Guarantee",
      "description": "Full chemical coil wash & drain flush.",
      "inclusions": ["Filter wash", "Coil cleaning", "Drain unclog"],
      "image_id": 142,
      "published": true
    }
    ```
* **Update:** `PUT /api/v2/seller/muskila/services/{id}` (partial updates allowed)
* **Toggle Visibility:** `POST /api/v2/seller/muskila/services/{id}/status` with `{ "published": true | false }`
* **Delete:** `DELETE /api/v2/seller/muskila/services/{id}` (return `422` if bookings exist; UI offers Hide instead).

---

## 9. Chat & Offer Negotiation (`P1`)
*(Follows `Cook Habibi` `ChOrderChat` reversed-list pagination + `dokan-app` Offers)*

### 9.1 List Threads
* **Endpoint:** `GET /api/v2/seller/muskila/chat/threads?page=1`
* **Response (`200`, Paginated):**
  ```json
  {
    "id": "th_12",
    "customer_name": "Salim Al-Harthy",
    "customer_avatar": "",
    "service_title": "Split AC Maintenance",
    "original_quote": 15.000,
    "current_agreed_price": 13.500,
    "is_agreed": false,
    "is_escrow_locked": false,
    "problem_nature": "Repair",
    "requested_timing": "Today, 02:00 PM - 04:00 PM",
    "last_message": "Can you do 13.500 OMR?",
    "last_message_time": "12:45 PM",
    "unread_count": 1
  }
  ```

### 9.2 Get Messages (Newest-First)
* **Endpoint:** `GET /api/v2/seller/muskila/chat/threads/{threadId}/messages?page=1`
* **Response (`200`, Paginated):**
  ```json
  {
    "result": true, "success": true, "status": 200,
    "chat_open": true,
    "has_unread": true,
    "data": [
      {
        "id": "msg_99",
        "sender": "user",
        "text": "Counter offer: OMR 13.500",
        "time_text": "12:45 PM",
        "is_offer": true,
        "proposed_price": 13.500,
        "offer_id": "off_44",
        "is_accepted": null,
        "date": "2026-11-26",
        "slot_id": "slot_2",
        "slot_label": "02:00 PM - 04:00 PM"
      }
    ],
    "meta": { "current_page": 1, "last_page": 1 }
  }
  ```

### 9.3 Send Message / Custom Offer & Mark Read
* **Send:** `POST /api/v2/seller/muskila/chat/threads/{threadId}/messages` *(Requires `Idempotency-Key`)*
  * **Body:** `{ "message": "...", "is_offer": true|false, "proposed_price": 14.000, "date": "2026-11-26", "slot_id": "slot_2" }`
* **Mark Read:** `POST /api/v2/seller/muskila/chat/threads/{threadId}/read`

### 9.4 Accept or Counter Customer Offer
* **Accept:** `POST /api/v2/seller/muskila/offers/{offerId}/accept` *(Requires `Idempotency-Key`)*
  * Sets `is_accepted = true`, updates thread `current_agreed_price` & `is_agreed = true` so Customer can proceed to Escrow Checkout.
* **Counter:** `POST /api/v2/seller/muskila/offers/{offerId}/counter` *(Requires `Idempotency-Key`)*
  * **Body:** `{ "amount": 14.000, "date": "2026-11-26", "slot_id": "slot_2", "note": "Final price with warranty" }`

---

## 10. Profile, Schedule, Location, Reviews & Earnings (`P1`)

### 10.1 Pro Profile (Partial-Diff Update)
* **Get:** `GET /api/v2/seller/muskila/profile`
  * Returns all `MuskilaPro` fields (`id`, `name`, `email`, `phone`, `photo`, `category_id`, `profession_title`, `experience_years`, `bio`, `skills[]`, `visit_price`, `hourly_rate`, `rating`, `reviews_count`, `jobs_completed`, `on_time_percentage`, `is_online`, `is_verified`, `fully_verified`, `is_suspended`, `verifications[8]`, `video`, `allow_custom_bargain`, `min_custom_price`, `service_areas[]`, `lat`, `lng`, `radius_km`).
* **Update:** `PUT /api/v2/seller/muskila/profile` (accepts partial fields: only changed fields are sent by the app).

### 10.2 Working Schedule & Location
* **Schedule:** `PUT /api/v2/seller/muskila/schedule`
  * **Body:** `{ "working_schedule": { "sat": { "open": true, "slots": ["slot_1", "slot_2"] }, "fri": { "open": false, "slots": [] } } }`
* **Location:** `PUT /api/v2/seller/muskila/location`
  * **Body:** `{ "lat": 23.5880, "lng": 58.3829, "location_label": "Al Ghubrah, Muscat", "service_areas": ["Muscat", "Seeb"], "radius_km": 15 }`

### 10.3 Customer Reviews
* **Endpoint:** `GET /api/v2/seller/muskila/reviews?page=1`
* **Response (`200`, Paginated):** `{ "rating": 4.8, "reviews_count": 12, "on_time_percentage": 98, "data": [{ "reviewer_name", "date_text", "rating", "comment", "booking_number" }] }`

### 10.4 Earnings & Escrow Ledger
* **Endpoint:** `GET /api/v2/seller/muskila/earnings`
* **Response (`200`):**
  ```json
  {
    "result": true, "success": true, "status": 200,
    "data": {
      "currency": "OMR",
      "balance_due": 420.000,
      "paid_out": 1425.500,
      "pending": { "bookings": 3, "customer_total": 125.000 },
      "released": { "bookings": 24, "your_earning": 1845.500, "commission": 184.500 },
      "recent_releases": [
        { "code": "#BK-8790", "service_title": "Breaker Diagnostic", "your_earning": 31.500, "commission": 3.500, "released_at": "2026-11-25T18:00:00+04:00" }
      ],
      "recent_payments": [
        { "amount": 250.000, "method": "Bank Transfer", "reference": "PAY-2026-112", "paid_at": "2026-11-20T12:00:00+04:00" }
      ]
    }
  }
  ```

### 10.5 In-App Notifications
* **List:** `GET /api/v2/seller/muskila/notifications?page=1`
* **Mark All Read:** `POST /api/v2/seller/muskila/notifications/read-all`

---

## 11. FCM Push Notification Payload Contract

Send FCM data payloads matching these exact `type` values so the Flutter app deep-links cleanly:

| Event | `data.type` | Required `data` Keys | App Action |
| :--- | :--- | :--- | :--- |
| Urgent Instant Match | `muskila_instant_request` | `instant_request_id` | Opens Instant Request sheet |
| New / Updated / Cancelled Booking | `muskila_booking` | `booking_id`, `status` | Refreshes bookings & opens detail |
| New Chat Message / Offer | `muskila_chat` / `muskila_offer` | `thread_id` | Reloads open chat or opens thread |
| New Matching Job Lead | `muskila_job_lead` | `lead_id` | Opens Job Leads tab |
| Customer Released Escrow | `muskila_escrow` | `booking_id` | Opens Earnings screen |

---

## 12. Existing Customer API Bug Found During Testing (FYI for Backend Team)
* **`GET /api/v2/muskila/notifications`** on `10.10.10.189:8000` currently throws **HTTP 500 `TypeError`**:
  `MuskilaHelper::isoString(): Argument #1 ($carbon) must be of type ?Carbon\Carbon, string given` at `app/Http/Resources/Muskila/NotificationResource.php:30`. Please cast `created_at` to `Carbon` or accept `string|Carbon` in `MuskilaHelper::isoString()`.

