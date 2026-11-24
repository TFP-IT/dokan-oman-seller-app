# Cook Habibi Seller App: developer guide

Written for: mobile developers building the Cook (seller) app in Flutter.

This guide covers everything the seller app needs: signing in, applying to become a cook, managing the kitchen, dishes and stories, handling orders (including the pickup handover), earnings, and push notifications. The full endpoint contract is in `cook_habibi_api.md` (section 14). The Postman collection is `cook_habibi_seller.postman_collection.json`.

---

## 1. Environments and base URL

| Environment | Base URL |
|---|---|
| Local | `http://127.0.0.1:8000/api/v2` |
| Production | `https://YOUR-DOMAIN/api/v2` (set when deployed) |

All seller endpoints live under `{base}/seller/cook-habibi/...`. Sign-in is at `{base}/auth/login`.

### Headers on every request

| Header | Value | Notes |
|---|---|---|
| `Accept` | `application/json` | Always send it. |
| `System-Key` | the app key from the backend team | Required on every `/api` call except `/api/health`. |
| `App-Language` | `en` or `ar` | Controls the language of messages. |
| `Authorization` | `Bearer <access_token>` | Every call except sign-in, apply and health. |
| `Idempotency-Key` | a unique string per action (for example a UUID) | Send on writes listed in section 6. |

---

## 2. Responses and errors

Success and error bodies share one shape:

```json
{ "result": true,  "message": "Order updated.", "data": { } }
{ "result": false, "message": "Order is not waiting for handover.", "errors": { "otp": ["Incorrect code"] } }
```

- `message` is safe to show to the user.
- `errors` appears on validation failures (422). It maps each field to a list of messages.
- Lists are paginated: `data` is the array and `links` and `meta` are present. Lists are 20 per page; use `?page=2`.

| HTTP | Meaning in the app |
|---|---|
| 200 / 201 | Success. |
| 401 | Not signed in or the token expired. Send the user to sign-in. |
| 403 | Signed in, but this account can't do it (for example a customer token, or a token without the cook ability). Show the message. |
| 404 | Not found, or the item belongs to another kitchen. |
| 409 | The same `Idempotency-Key` request is still running. Wait a moment, then retry. |
| 422 | Rule broke (wrong order step, wrong code, not allowed right now). Show `message`. |
| 429 | Too many attempts. Show the message and wait a minute. |
| 503 | Server down. Retry later. |

Never show raw server text to the user. Use `message` or your own wording.

---

## 3. Sign-in and session

### 3.1 Sign in
`POST {base}/auth/login`

```json
{ "login_by": "email", "email": "cook@example.com", "password": "...", "user_type": "seller" }
```

`user_type` must be `seller`. The response contains `access_token` (use it as the Bearer token) and `user`.

Rules:
- The token is a seller token. It expires after **30 days**. When any call returns `401`, sign the user in again.
- Ten failed sign-ins in a minute return `429`. Show "Too many attempts, try again in a minute."
- A token without the cook permission returns `403` "Please sign in again with your cook account". Treat it like `401`.
- Email must be verified. An unverified seller gets a verification-code response from the backend (same as other roles).

### 3.2 Push token
Right after sign-in (and when the FCM token refreshes):

`POST {base}/seller/cook-habibi/device` with `{ "device_token": "<FCM token>", "device_type": "android" | "ios" }`

On sign-out, call `DELETE {base}/seller/cook-habibi/device` before clearing the local token, so this phone stops getting pushes.

---

## 4. Becoming a cook (application)

A new cook applies first, then waits for admin review. Flow:

1. **Apply:** `POST {base}/cook-habibi/apply` (public, `multipart/form-data`). It creates the seller account and a kitchen in **pending**. Send the identity and kitchen details and documents; see `cook_habibi_api.md` section 17 for the full field list. Limit: 5 per minute.
2. **Wait:** the account can sign in while pending. Call `GET {base}/seller/cook-habibi/application` to show progress.
3. **Rejected:** the response has `status: "rejected"` and `rejection_reason`. Show the reason, let the cook fix it, then call `POST {base}/seller/cook-habibi/application/resubmit`. It returns to pending.
4. **Approved:** `status: "approved"`. Show the kitchen tools (orders, dishes, stories, earnings).

### Application status object
```json
{
  "id": 12,
  "kitchen_name": "Hiram Lawrence",
  "status": "pending",
  "applied_at": "2026-11-23T06:00:00+04:00",
  "rejection_reason": null,
  "can_resubmit": false,
  "missing_checks": ["kitchen_visit"]
}
```
`missing_checks` lists the admin checks still missing (for example `civil_id`, `kitchen_visit`). Show them as "Waiting for: kitchen visit" so the cook knows why approval is slow.

**Screens:** Sign-in → Application status (pending / rejected) → Main tabs (approved only).

---

## 5. Kitchen (profile and open/close)

| Action | Call |
|---|---|
| Show profile | `GET .../profile` |
| Edit profile | `PUT .../profile` (partial; send only changed fields) |
| Working hours | `PUT .../schedule` |
| Open for orders | `POST .../open` |
| Close for orders | `POST .../close` |
| Upload a photo | `POST .../uploads` (`multipart/form-data`, field `file`, image up to 5 MB) → returns `upload_id` |

Profile fields you can edit: `kitchen_name`, `cook_name`, `emoji`, `cuisine_key`, `cover_image` (upload id), `owner_image` (upload id), `area`, `lat`, `lng` (send both or neither), `delivery_radius_km` (0–50), `delivery_fee` (0–99), `delivery_time_text`, `pickup_enabled`, `delivery_enabled`, `supports_pre_order`, `supports_subscription`, `supports_catering`, `has_family_meals`, `offer_text`, `offer_percent`, `offer_min_order`, `bio`, `languages` (array), `cooking_since`.

Admin-only fields (status, verification, premium, rating) are read-only in the app.

**Suspended kitchens:** the profile still loads, but every change returns `403` "Your kitchen is suspended". Show a banner and disable edit buttons.

**Screens:** Profile (view + edit), Hours, Open/Close switch (`is_accepting_orders` tells you the current state).

---

## 6. Orders

### 6.1 List and detail
- `GET .../orders?tab=active` (default) or `?tab=past`, and optional `?status=`.
- `GET .../orders/{id}` for one order.

Key fields in an order:
- `id`, `code` (for example `#CH-10012`), `status`, `status_title` (show this text).
- `fulfilment`: `delivery` or `pickup`.
- `dish`: `{id, name, emoji}`, `qty`, `note`, `slot`.
- `customer`: `name`, `phone` and `address` (shown only while the order is active; `address` only for delivery).
- `amounts`: `food`, `delivery_fee`, `customer_paid`, `your_earning` (`null` until released), `escrow_status`.
- `accept_deadline`: when the order must be accepted (placed orders only).
- `next_actions`: the steps allowed right now. **Show buttons only for these.**
- `cancel_reason`, `created_at`.

### 6.2 Order steps
Each step is a POST to `.../orders/{id}/{action}`. Always send an `Idempotency-Key`.

| `next_actions` value | Call | When |
|---|---|---|
| `accept` | `POST .../orders/{id}/accept` | placed |
| `preparing` | `POST .../orders/{id}/preparing` | accepted |
| `ready` | `POST .../orders/{id}/ready` | preparing |
| `out-for-delivery` | `POST .../orders/{id}/out-for-delivery` | ready, delivery orders |
| `handover` | `POST .../orders/{id}/handover` with `{"otp": "1234"}` | ready, **pickup** orders |
| `reject` | `POST .../orders/{id}/reject` with `{"reason": "..."}` (reason optional) | placed only; refunds the customer |

**Delivery orders:** after `out-for-delivery`, the delivery rider confirms the customer's code in the rider app. The cook does not enter a code. The order then shows `escrow_status` as held until admin releases the money.

**Pickup orders:** when the order is `ready`, the customer shows the 4-digit code at the counter. The cook types it in with `handover`. A correct code marks the order delivered.
- Five wrong codes lock the order for 15 minutes. Show the message "Too many wrong codes. Please try again in 15 minutes."
- A wrong code returns 422 with `errors.otp`.

There is no `delivered` action for the cook. Do not offer one.

### 6.3 Order screen behaviour
- Refresh the list on pull-to-refresh and when a push arrives.
- Show a countdown to `accept_deadline` on placed orders.
- Disable a button while its request runs, so the user doesn't tap twice. The idempotency key covers network retries, not double taps.

**Screens:** Orders (Active / Past tabs) → Order detail with action buttons from `next_actions` → Handover keypad (pickup) → Reject dialog.

---

## 7. Dishes

| Action | Call |
|---|---|
| List | `GET .../dishes?status=published\|hidden\|pending_approval` |
| Create | `POST .../dishes` |
| Show | `GET .../dishes/{id}` |
| Update | `PUT .../dishes/{id}` (partial) |
| Show / hide | `POST .../dishes/{id}/status` with `{"published": true\|false}` |
| Today's portions | `PUT .../dishes/{id}/capacity` with `{"daily_capacity": 8}` |
| Delete | `DELETE .../dishes/{id}` |

Main dish fields: `name` (required), `description`, `price`, `discount_percent` (0–100), `emoji`, `serves` (1–50), `dietary` (array), `allergens` (array, max 20), `is_family_meal`, `pre_order_only`, `badge`, `thumbnail` (upload id), `photos` (upload ids, max 10), `published`, `sort`, `daily_capacity`.

Rules to show clearly:
- `pending_approval` dishes are not visible to customers until admin approves.
- A dish with orders cannot be deleted (422). Offer "Hide" instead.

**Screens:** Dish list (tabs by status) → Dish form → Capacity sheet.

---

## 8. Stories

1. Upload the photo: `POST .../uploads` → `upload_id`.
2. Post: `POST .../stories` with `{"upload_id": 123, "caption": "...", "dish_id": 84}`. Caption max 200 characters, `dish_id` optional (must be your dish). Send an `Idempotency-Key`.
3. Edit: `PUT .../stories/{id}` with `caption` and/or `dish_id`. The photo cannot be changed.
4. Delete: `DELETE .../stories/{id}`.
5. List: `GET .../stories` (last 7 days).

A story is live for 24 hours. Each kitchen can have up to 10 live stories; the 11th returns 422 "You can have up to 10 live stories". Show the count from `GET .../dashboard` (`live_stories`).

---

## 9. Money: earnings and dashboard

### Dashboard (`GET .../dashboard`)
`orders_today`, `sales_today` (excludes cancelled and refunded), `active_orders`, `completed_orders`, `rating`, `reviews_count`, `live_stories`, `is_open`, `balance_due`.

### Earnings (`GET .../earnings`)
- `balance_due`: what the platform still owes the kitchen. The payout is made by the admin office.
- `paid_out`: total already paid out.
- `pending`: `{orders, customer_total}`. Paid orders waiting for delivery confirmation. The cook's share is only known after release.
- `released`: `{orders, your_earning, commission}`.
- `recent_releases`: last 20, each with `code`, `your_earning`, `commission`, `released_at`.
- `recent_payments`: last 20, each with `amount`, `method`, `reference`, `paid_at`.

Amounts are plain numbers. Format them in the app with the currency `currency` (`OMR` for now) and three decimals.

**Screens:** Dashboard (home tab) and Earnings (wallet-style list with balance at top).

---

## 9b. Chat, reviews, password (added 2026-11-24)

**Chat with the customer (per order).** `GET orders/{id}/messages?page=` lists messages, newest first. `POST orders/{id}/messages` with `{"message"}` sends one (max 1000 characters; send an `Idempotency-Key` so a double-tap does not send twice). `POST orders/{id}/messages/read` clears the unread dot. The response's `chat_open` is `false` once the order is finished; then show the history read-only. Each message has `is_mine`. Use it to align the bubble side.

**Reviews.** `GET reviews?page=` lists published reviews, newest first, with `reply` and `replied_at`. `POST reviews/{id}/reply` with `{"reply"}` (max 500 characters) posts one reply. A second reply returns `422`, so hide the reply button once `replied_at` is set.

**Password.** `PUT password` with `current_password`, `password` (min 8) and `password_confirmation`. A wrong current password returns `422` on `errors.current_password`. On success, every other signed-in device is signed out, so this phone keeps working and the others need to sign in again.

**Earnings history.** `GET earnings/releases?page=` (released orders) and `GET earnings/payments?page=` (payouts from the platform), both paginated with `meta`.

**Notifications.** The same endpoints as the customer app: `notifications`, `notifications/unread-count`, `notifications/{id}/read`, `notifications/read-all`. They include order updates and the application decision, so a pending applicant can use them too.

---

## 10. Push notifications

The backend sends a push for each order change, such as a new order, a cancellation, or the customer's status updates. Each push carries:
- `title`: "Cook Habibi"
- `body`: the message text
- `data`: `type` = `cook_habibi_order`, `order_id`, `status`

Chat messages send a second type, so the app can open the chat instead of the order:
- `data`: `type` = `cook_habibi_chat`, `order_id`, `conversation_id`. The body is always the generic "New message about your order #CODE". The text of the message is never in the push. Open `orders/{order_id}/messages` to read it.

When the user taps a push, open the order detail for `order_id`. Pushes are best-effort, so always refresh the order list when the app opens. The in-app notification list has the full history.

If a push token is rejected by Firebase, the backend clears it. Re-register on the next app open (section 3.2).

---

## 11. Idempotency

Send `Idempotency-Key` on these writes: order steps (`accept`, `preparing`, `ready`, `out-for-delivery`, `handover`, `reject`), story posting, and application resubmit.

- Generate the key once per user action and reuse it if the request is retried.
- A replay returns the first answer with the header `Idempotent-Replayed: true`. Treat it as a success.
- A failed request (4xx/5xx) is not remembered. Fix the input and send with a new key, or the same key.
- If you get `409`, the first request is still running. Wait 2–3 seconds and retry with the same key.

---

## 12. Screens checklist

| # | Screen | APIs |
|---|---|---|
| 1 | Sign-in | `POST auth/login`, `POST device` |
| 2 | Apply to be a cook | `POST cook-habibi/apply` |
| 3 | Application status | `GET application`, `POST application/resubmit` |
| 4 | Dashboard | `GET dashboard` |
| 5 | Orders (active/past) | `GET orders` |
| 6 | Order detail + actions | `GET orders/{id}`, step POSTs, `handover`, `reject` |
| 7 | Kitchen profile | `GET/PUT profile`, `PUT schedule`, `POST uploads` |
| 8 | Open / close | `POST open`, `POST close` |
| 9 | Dishes list and form | `GET/POST/PUT/DELETE dishes`, `POST dishes/{id}/status`, `PUT dishes/{id}/capacity` |
| 10 | Stories | `GET/POST/PUT/DELETE stories`, `POST uploads` |
| 11 | Earnings | `GET earnings` |
| 12 | Sign out | `DELETE device`, then clear token |

---

## 13. Testing

- Import `cook_habibi_seller.postman_collection.json` and the local or production environment. Sign in first, then run folders in order.
- Negative cases are in folder 7 of that collection: no token (401), cook marking delivered (404), wrong handover code (422), editing another kitchen's story (404).
- Test accounts and the local base URL are set in the environment file. Never commit real passwords.

---

## 14. Known limits (as of this version)

- Earnings show what is released; the cook is paid by the admin office, not in the app.
- Live rider tracking is not in this version. Show the order status only.
- Rider confirmation of delivery happens in the rider app; the seller app only shows `out_for_delivery` and then the delivered status.
- Escrow is released by the admin after the order is delivered. A handover code does not release the money, so the earnings show the order as held until then.
- Notification preferences and a payout log are not in this version.
- Friday is closed in the default hours, unless the kitchen sets Friday hours.
