# Partner App — Workspace & Screen Plan

Status: draft for owner review. Supersedes nothing; feeds Phase C of the
redesign brief.

This plan is built **only** on endpoints that exist in
`buss-booking-system-backend` today. Every capability is marked ✅ supported,
⚠️ partial, or ⛔ blocked, with the file that proves it. Nothing here invents an
endpoint, payload, or response shape.

---

## 0. Evidence base

| Claim | Proof |
|---|---|
| 5 roles exist; `roles[]` is the authorization source of truth, `activeRole` rides in the JWT | `models/userModel.js:53-64`, `middleware/checkRole.js` |
| Client declares desired role via `X-App-Source` header | `src/modules/auth/login/login.policy.js:88-120` |
| Two agent types, single unified lifecycle | `models/agentModel.js:44-62` |
| Conductors/drivers never self-register; owner invites, they activate | `models/conductorProfileModel.js:6-14`, `controllers/busOwnerController/staffAssignmentController.js:9-10` |
| Conductor has exactly 2 endpoints | `routes/conductorRoutes/conductorRoutes.js` |
| Driver has **zero** endpoints | `grep requireRole("driver")` → only a test asserting the middleware is a function |
| Agents cannot create bookings | `routes/ticketRoutes/ticketRoutes.js:24` — every booking route is `requireRole("passenger")` |
| Web's bookings/customers/earnings pages are static mock | `mockCounts` in each `page.tsx`; only `/api/agent/` appears in the entire web `src` |

---

## 1. Verified endpoint inventory

### Shared entry

| Method | Path | Notes |
|---|---|---|
| POST | `/api/login` | Generic. Send `X-App-Source: conductor` or `driver`. |
| POST | `/api/auth/activate/sendOTP` | `{phone}` |
| POST | `/api/auth/activate/` | `{phone, otp, newPassword}` → token pair |

`X-App-Source` is lowercased then matched against a case-sensitive list
containing `busOwner` — so `busowner` never matches. This is a **deliberate,
test-pinned quirk** (`auth-login-roles.test.js`). We never send `busOwner`, so
it does not affect us. Do not "fix" it.

### Agent auth — `/api/auth/agent`

`sendOTP` · `verifyOTP` · `resendOTP` · `register` · `login` · `refresh` ·
`logout` · `requestPasswordReset` · `verifyOtpForReset` · `resetPassword` ·
`resendOtpForReset` — all POST.

### Agent — `/api/agent` (auth → verifyRoleFromDB → agentMiddleware)

| Method | Path | Extra gate |
|---|---|---|
| POST | `/application/save` | DRAFT or MORE_INFO |
| POST | `/application/document` | DRAFT or MORE_INFO |
| POST | `/application/submit` | DRAFT or MORE_INFO |
| GET | `/application/status` | any status |
| GET | `/documents/view` | — |
| GET | `/profile` | `requireApprovedAgent` |
| GET | `/dashboard` | `requireApprovedAgent` |

`GET /dashboard` returns exactly eight scalars — no lists:

```
commissionBalance, totalOnlineBookings, totalCashBookings,
totalCommissionEarned, totalCommissionSettled, lastBookingAt,
commissionRate, agentType
```

### Conductor — `/api/conductor` (role: `busOwner` or `conductor`)

| Method | Path |
|---|---|
| POST | `/confirmBoarding` — `{ticketId, tripId}` |
| GET | `/manifest/:tripId` |

### Driver

None.

### Readable without a role

`POST /api/ticket/getSeats` — `optionalAuth`. Seat **availability** only, no writes.

---

## 2. Blockers

Ordered by how much of the app they stop.

| # | Blocker | Owner | Stops |
|---|---|---|---|
| **B1** | **Agents cannot sell or mark a seat.** Every booking-creation route is `requireRole("passenger")`; an agent JWT gets 403 `INSUFFICIENT_ROLE`. `agentBookingModel.js` is imported by nothing. | backend | The agent's entire stated purpose |
| **B2** | **Multi-operator affiliation is not modelled.** `Agent.linkedOperatorId` is a single `ObjectId`, not an array. The requirement is one agent ↔ many operators. | backend | Operator scoping, bus/route filtering |
| **B3** | **Conductor has no "my trips" endpoint.** `ConductorProfile.assignedTripIds[]` exists but nothing exposes it to the conductor. | backend | Conductor home screen |
| **B4** | **Driver has no backend whatsoever.** No routes, no GPS/location ingestion, no driver-readable profile. | backend | The entire driver workspace |
| **B5** | **No agent bookings / customers / earnings-history API.** `agentSettlementModel` and `agentWalletTransactionModel` have zero references anywhere. | backend | 3 of 6 agent tabs |
| **B6** | Riverpod (in `pubspec.yaml`) vs `Provider` (mandated by rules §4.1). | owner | Every screen's state layer |
| **B7** | `brand_header.dart:105` asks Neue Machina for w600; family ships 300/400 only. | owner | Header typography |

B1–B5 are backend work. The brief forbids me touching the backend, so those
screens can only be built as honest shells until the contracts land.

---

## 3. Identity model

The backend fixes `activeRole` **at login** and stamps it into the JWT. It is not
switchable within a session. Consequences:

- The role is chosen **before** the token exists → the role picker is a
  pre-auth screen, not a post-auth setting.
- Switching workspace = full logout + re-login with a different
  `X-App-Source`. Plan a "Switch role" action that does exactly that, honestly
  labelled.
- A user holding several roles (`roles: ["agent","conductor"]`) is normal —
  `staffAssignmentController` has an explicit upgrade path that `$addToSet`s a
  role onto an existing user. Do not assume one human = one role.
- `ROLE_NOT_REGISTERED` (403) is the response when someone logs in against a
  role they don't hold. That is a first-class screen, not a toast.

---

## 4. Folder structure

Shared: the app shell, core, and the entry screens. Everything after role
resolution is workspace-isolated — its own router branch, nav, state, screens.

```
lib/
├── main.dart
├── app/
│   ├── app.dart                  # root widget, theme injection
│   ├── bootstrap.dart            # token restore → first route decision
│   └── router/
│       ├── app_router.dart       # top-level table; one branch per workspace
│       ├── routes.dart           # path constants, no magic strings
│       └── guards.dart           # redirect logic (session, role, approval)
│
├── core/
│   ├── config/                   # AppEnvironment: baseUrl per flavour  ← fixes C1
│   ├── design/                   # ✅ done in Phase A — do not touch
│   ├── network/
│   │   ├── api_service.dart      # the ONLY http entry point (rules §4.2)
│   │   ├── interceptors/         # auth header, X-App-Source, refresh-on-401
│   │   └── api_paths.dart        # verified paths only
│   ├── errors/
│   │   ├── failure.dart          # sealed failure types
│   │   └── error_mapper.dart     # backend errorCode → Failure
│   └── storage/
│       └── session_store.dart    # flutter_secure_storage: tokens + activeRole
│
├── shared/
│   ├── ui/                       # ✅ done in Phase A
│   ├── state/                    # ViewState<T>, paging helpers
│   └── widgets/                  # cross-workspace composites
│
├── domain/                       # models used by ≥2 workspaces
│   ├── session.dart
│   ├── app_role.dart             # enum mirroring VALID_APP_SOURCES
│   └── ...
│
└── workspaces/
    ├── entry/                    # THE ONLY SHARED SCREENS
    │   ├── screens/              # splash, role pick, login, register, reset, activate
    │   ├── state/
    │   └── data/
    ├── agent/
    │   ├── shell/                # agent bottom nav (5 tabs)
    │   ├── application/          # KYC: 4 steps + status hub
    │   ├── overview/
    │   ├── bookings/
    │   ├── customers/
    │   ├── earnings/
    │   ├── settings/
    │   └── faq/
    ├── conductor/
    │   ├── shell/                # conductor nav — NOT the agent's
    │   ├── duty/
    │   ├── manifest/
    │   └── scan/
    └── driver/
        ├── shell/
        └── duty/
```

Every feature folder gets the same four-part interior, which is how §3.2's
separation of concerns lands on the client:

```
<feature>/
├── data/        # repository + DTOs. Only place that talks to ApiService.
├── state/       # controllers. No widgets.
├── screens/     # purely presentational (rules §4.1)
└── widgets/     # screen-local composites
```

---

## 5. Global boot state machine

```
launch
  └─ bootstrap: read secure store
       ├─ no token           → /welcome
       └─ token present
            ├─ refresh fails → clear store → /login (reason: session expired)
            └─ refresh ok    → switch on activeRole
                 ├─ agent     → agent gate  (below)
                 ├─ conductor → /conductor
                 ├─ driver    → /driver
                 └─ other     → /welcome (wrong app)

agent gate: GET /api/agent/application/status
  ├─ DRAFT | MORE_INFO → /agent/application  (resume where they left off)
  ├─ PENDING           → /agent/application  (pending rendering)
  ├─ REJECTED          → /agent/application  (rejected rendering)
  ├─ SUSPENDED         → /agent/application  (suspended rendering)
  └─ APPROVED          → /agent             (overview)
```

`requireApprovedAgent` already returns `applicationStatus` inside its 403 body
specifically so the client can route without a second call. Use it — the guard
should read that field rather than firing an extra request.

---

## 6. Canonical screen states

Defined once; each screen below lists only its deltas. Rules §4.2 forbids raw
exception screens and infinite spinners, so every one of these needs a real
rendering.

| State | Rendering rule |
|---|---|
| `initial` | Nothing user-visible; must not flash. |
| `loadingFirst` | Skeleton in the shape of the real content. Never a bare centred spinner. |
| `loadingRefresh` | Keep existing data on screen; inline progress only. |
| `data` | Content. |
| `empty` | Distinct illustration + copy **per screen** — never a generic "No data". |
| `errorRetryable` | Cause in plain language + Retry. Network/5xx. |
| `errorAuth` | 401 after refresh failed → clear session, route to login with reason. |
| `errorForbidden` | 403. Branch on `errorCode`, never show the raw message. |
| `offline` | Banner + cached data if any. `connectivity_plus` is already a dependency. |
| `submitting` | Disable the primary action, spinner inside the button. Block double-submit. |
| `submitFieldErrors` | Per-field messages inline, not a snackbar. |

`errorForbidden` branches on codes the backend actually emits:
`INSUFFICIENT_ROLE`, `ACCOUNT_SUSPENDED` (carries `reason`, `suspendedAt`,
`contact.email`, `contact.phone` — render them), `ACCOUNT_NOT_ACTIVATED`,
`ROLE_NOT_REGISTERED`, `NO_APPLICATION`, `APPLICATION_NOT_APPROVED`.

---

## 7. Screen inventory

### 7.1 Entry workspace — shared by all roles

| # | Screen | Route | Endpoint | State notes |
|---|---|---|---|---|
| E1 | Splash / bootstrap | `/` | — (token restore) | `loadingFirst` only; hard 3 s cap then fall through to `/welcome` |
| E2 | Welcome / role pick | `/welcome` | — | Two paths: "Apply as an agent" (self-serve) and "I was invited" (activation). Purely local. |
| E3 | Login | `/login` | agent: `/api/auth/agent/login`; conductor+driver: `/api/login` + `X-App-Source` | `ROLE_NOT_REGISTERED`, `ACCOUNT_SUSPENDED`, `ACCOUNT_NOT_ACTIVATED` → each its own rendering. Rate-limited server-side: handle 429 with the retry window. |
| E4 | Register — phone | `/register/phone` | `POST /auth/agent/sendOTP` | Duplicate-phone error inline |
| E5 | Register — OTP | `/register/otp` | `verifyOTP`, `resendOTP` | Resend cooldown timer; server rate-limits, mirror it locally |
| E6 | Register — password | `/register/password` | `register` | Password policy from `passwordValidator.js`; show rules, validate live |
| E7 | Forgot — phone | `/forgot/phone` | `requestPasswordReset` | |
| E8 | Forgot — OTP | `/forgot/otp` | `verifyOtpForReset`, `resendOtpForReset` | |
| E9 | Forgot — new password | `/forgot/reset` | `resetPassword` | On success → login, do not auto-login |
| E10 | Activate — phone | `/activate/phone` | `POST /auth/activate/sendOTP` | For invited conductors, drivers, operator-linked agents. 404 → "no invite found for this number" |
| E11 | Activate — OTP + password | `/activate/verify` | `POST /auth/activate/` | Returns a token pair → straight into the right workspace |
| E12 | Session-expired interstitial | `/login?reason=expired` | — | Reached only from `errorAuth` |

### 7.2 Agent workspace

Nav: 5 tabs — Overview · Bookings · Customers · Earnings · Settings. Matches the
web's `/dashboard/*`. FAQ lives inside Settings.

#### Application / KYC — ✅ fully supported

| # | Screen | Route | Endpoint | States |
|---|---|---|---|---|
| A1 | Status hub | `/agent/application` | `GET /application/status` | **Six renderings**, one per `applicationStatus`. See below. |
| A2 | Step 1 — Personal | `…/personal` | `POST /application/save` | `district`, `municipality`, `placeName`, `citizenshipNumber`, `nationalIdNumber` (optional), `panNumber` |
| A3 | Step 2 — Business | `…/business` | `POST /application/save` | `businessName`, `shopAddress`, `operationType` (6-value enum), `claimedMonthlyVolume`, `currentOperators`, `referralSource` |
| A4 | Step 3 — Documents | `…/documents` | `POST /application/document` | 7 types: `citizenship_front/back`, `national_id_front/back`, `shop_photo`, `pan_card`, `business_registration`. Per-document upload state — one failure must not reset the others. |
| A5 | Step 4 — Settlement | `…/settlement` | `POST /application/save` | `settlementMethod` BANK ⇒ bank triplet; ESEWA/KHALTI ⇒ single number. Conditional validation. |
| A6 | Review & submit | `…/review` | `POST /application/submit` | Server-side completeness validator can reject → map its response back to the offending step |
| A7 | Document viewer | `…/document/:key` | `GET /documents/view` | Streams via proxy; raw S3 URL never reaches the client |

A1's six renderings — this is the screen that carries the most state:

| `applicationStatus` | Rendering |
|---|---|
| `DRAFT` | Progress across 4 steps + resume CTA |
| `PENDING` | Submitted-at timestamp, expectation-setting, no edit affordance |
| `MORE_INFO` | `moreInfoRequest` text verbatim + reopen editing |
| `APPROVED` | Brief success, auto-forward to Overview |
| `REJECTED` | `rejectionReason`. Two sub-states: `isPermanentlyRejected: true` → no reapply path; otherwise reapply unlocks 24 h after `rejectedAt` → live countdown |
| `SUSPENDED` | `suspensionReason` + support contact, read-only |

#### Post-approval

| # | Screen | Route | Endpoint | Status |
|---|---|---|---|---|
| A8 | Overview | `/agent` | `GET /dashboard` | ✅ 8 scalars. Layout must not imply lists we can't fill. |
| A9 | Bookings | `/agent/bookings` | none | ⛔ **B1/B5.** Web is mock here too. |
| A10 | Customers | `/agent/customers` | none | ⛔ **B5.** No customer concept exists backend-side. |
| A11 | Earnings | `/agent/earnings` | `GET /dashboard` | ⚠️ 5 totals only. No transaction history, no payout request. |
| A12 | Settings / profile | `/agent/settings` | `GET /profile` | ✅ read-only; no update endpoint exists |
| A13 | FAQ | `/agent/faq` | — | ✅ static |
| A14 | Sell a ticket | — | none | ⛔ **B1.** The core job. Blocked. |

Agent-type divergence inside the same workspace:

| | `DEFAULT` | `OPERATOR_LINKED` |
|---|---|---|
| Origin | Self-registers | Created by admin (`agent/admin/setup`), activates via E10/E11 |
| Payment | Online only | Cash + online |
| Scope | Platform-wide | `linkedOperatorId` (**one** operator — B2) + `busAccessScope` `ALL_OPERATOR_BUSES` \| `SPECIFIC_ROUTES` |
| Commission | Paid by platform | Settled with operator |

`agentType` arrives on the dashboard payload, so the workspace can branch
without an extra call.

### 7.3 Conductor workspace

Its own nav — deliberately not the agent's. Three destinations: Duty · Scan ·
Profile.

| # | Screen | Route | Endpoint | Status |
|---|---|---|---|---|
| C1 | Duty home / today's trips | `/conductor` | none | ⛔ **B3.** Interim: manual trip-ID entry so C2/C3 are reachable and testable. |
| C2 | Trip manifest | `/conductor/trip/:tripId` | `GET /manifest/:tripId` | ✅ Passenger list. Needs boarded/not-boarded grouping, search, and a live boarded count. |
| C3 | Scan ticket | `/conductor/scan` | `POST /confirmBoarding` | ✅ Camera → parse `ticketId` → confirm. Distinct renderings for: valid, already-boarded, wrong-trip, not-found, offline. |
| C4 | Manual lookup | `/conductor/lookup` | `POST /confirmBoarding` | ✅ Fallback when a QR won't scan — needed in practice, low light and damaged prints are normal. |
| C5 | Boarding result | modal | — | ✅ Large, glanceable, one-handed. This is used standing in a bus doorway. |
| C6 | Profile | `/conductor/settings` | none | ⛔ No conductor-readable profile endpoint. `ConductorProfile.status` (`AVAILABLE`/`ON_DUTY`/`OFF_DUTY`/`SUSPENDED`/`INACTIVE`) is owner-controlled and not exposed. |

C3 must handle offline explicitly: boarding happens in places with no signal.
Queue confirmations locally and reconcile, or state plainly that connectivity is
required — but do not silently drop a scan. This needs an owner decision.

### 7.4 Driver workspace

⛔ **Entirely blocked (B4).** Zero endpoints. Planned shape, pending contracts:

| # | Screen | Needs |
|---|---|---|
| D1 | Duty home / today's assignment | trip-list endpoint for `activeRole: driver` |
| D2 | Trip tracking / location sharing | location-ingest endpoint + background-location policy |
| D3 | Profile & compliance | driver-readable profile exposing `licenseExpiry`, `medicalCertExpiry`, `approvalStatus` |

The requirement is also genuinely undefined ("might add more work on them but
don't know what exactly"). Building UI now would be guesswork. Recommendation:
ship the workspace folder with a single honest "coming soon" screen so a driver
who activates isn't dropped into a dead end, and defer D1–D3 until both the
contracts and the requirements exist.

---

## 8. Build order

Waves 1–4 are fully buildable today. Wave 5 is not.

| Wave | Content | Gate |
|---|---|---|
| 1 | `core/` (config, network, errors, storage) + entry workspace E1–E12 | Phase A4 sign-off, B6 |
| 2 | Agent application A1–A7 | Wave 1 |
| 3 | Agent overview A8, settings A12, FAQ A13 | Wave 2 |
| 4 | Conductor C2–C5 (+ C1 interim manual entry) | Wave 1 |
| 5 | A9–A11, A14, C1 proper, C6, driver D1–D3 | **B1–B5 backend work** |

Wave 1 also discharges brief item C1: base URL moves into
`core/config/app_environment.dart` per flavour, and
`usesCleartextTraffic="true"` comes out of the Android manifest.

---

## 9. Open decisions

1. **B6 — Riverpod or `Provider`?** Blocks Wave 1.
2. **B1/B2 scope** — is backend work in play this cycle, or do we build only
   Waves 1–4 and leave the selling flow out?
3. **Blocked screens** — honest "not available yet" states, or omit the tabs
   until the API exists? Mock data is not on the table; it would violate §2.3.
4. **C3 offline** — queue-and-reconcile, or require connectivity?
5. **B7** — Neue Machina w600.
