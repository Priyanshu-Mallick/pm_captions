# RevenueCat: going from simulated Pro to real purchases

The app already runs end-to-end without any of this: with no keys in `.env`,
`RevenueCatService` logs a warning, `isAvailable` stays false, and the debug
"Simulate Pro" switch in Settings drives the same `isPro` flag real entitlements
do. This document is the path to replacing that simulation with real purchases.

Project identifiers (both platforms share one):

| | Value |
|---|---|
| iOS bundle ID | `com.pmcaptions.app` |
| Android package | `com.pmcaptions.app` |

What the code already expects — deviate from these and the paywall will load but
show no prices:

- Entitlement identifier **`pro_access`** (override via `REVENUECAT_ENTITLEMENT_ID`).
- An offering marked **Current** in RevenueCat. `SubscriptionProvider.packages`
  reads `offerings.current`; a non-current offering returns nothing.
- Packages created as **`$rc_monthly`** and **`$rc_annual`**. These map to
  `PackageType.monthly` / `PackageType.annual`, which is what sorts annual first
  and draws the "BEST VALUE" badge. A custom package identifier becomes
  `PackageType.custom` and loses both.

Already handled, nothing to do: the `com.android.vending.BILLING` permission is
merged into the manifest by the plugin (verified in the built manifest), and
RevenueCat ships `consumerProguardFiles`, so its keep-rules apply to the
minified release build automatically.

---

## Step 1 — Create the store products

### App Store Connect

1. **Activate the Paid Applications agreement** under Business (formerly
   Agreements, Tax, and Banking), including tax and banking details. This is the
   single most common reason products return empty with no error message.
2. App record for `com.pmcaptions.app` if it doesn't exist.
3. **Subscriptions → create a Subscription Group** (e.g. "PM Captions Pro"). Put
   both durations in the *same* group so users upgrade/downgrade rather than
   stacking two active subscriptions.
4. Create two subscriptions in that group:
   - `pm_captions_pro_monthly` — 1 month
   - `pm_captions_pro_annual` — 1 year, priced ~40–50% below 12× monthly
5. Each needs a localized display name, description, and price before it leaves
   *Missing Metadata*. For sandbox testing they do **not** need to be approved.
6. In Xcode, add the **In-App Purchase** capability to the Runner target.

### Google Play Console

1. App record for `com.pmcaptions.app`.
2. **Upload a signed build to a closed track first.** Play will not serve
   subscription products until a build containing the billing library has been
   published to a track. This is a hard ordering requirement — do it before
   creating products.
3. **Monetize → Subscriptions →** create one subscription, e.g. `pm_captions_pro`,
   with two **base plans**: `monthly` (P1M, auto-renewing) and `annual` (P1Y).
4. Activate both base plans. A created-but-inactive base plan does not load.

## Step 2 — Wire the stores to RevenueCat

1. Create a project at [app.revenuecat.com](https://app.revenuecat.com).
2. **Add an App Store app**: bundle ID `com.pmcaptions.app`, then upload an
   **In-App Purchase Key** (App Store Connect → Users and Access → Integrations
   → In-App Purchase). Also set the App-Specific Shared Secret if prompted.
3. **Add a Play Store app**: package `com.pmcaptions.app`, then upload a
   **service account JSON**:
   - Google Cloud project → create a service account → create a JSON key.
   - Enable the **Google Play Android Developer API** for that project.
   - Play Console → Users and permissions → invite the service account email
     with *View financial data* and *Manage orders and subscriptions*.
   - Credential propagation takes up to ~36 hours; RevenueCat shows the status.
4. **Entitlements → create `pro_access`.**
5. **Products →** import from each store (or add the identifiers manually), then
   **attach every product to `pro_access`**. An entitlement with no attached
   products is the second most common cause of a purchase that succeeds but
   leaves `isPro` false.
6. **Offerings →** create `default`, mark it **Current**, and add two packages:
   `$rc_monthly` and `$rc_annual`. Attach the matching store product to each,
   per platform.

## Step 3 — Put the keys in the app

Project Settings → API keys → copy the **public app-specific** keys. Use the
public keys (`appl_…` / `goog_…`), never the secret key — a secret key in a
shipped binary is a credential leak.

```bash
# .env  (git-ignored; mirror the names into .env.example only, never values)
REVENUECAT_APPLE_KEY=appl_xxxxxxxxxxxxxxxxxxxx
REVENUECAT_GOOGLE_KEY=goog_xxxxxxxxxxxxxxxxxxxx
REVENUECAT_ENTITLEMENT_ID=pro_access
```

Then **turn off "Simulate Pro"** in Settings. It ORs into `isPro`, so leaving it
on masks whether the real entitlement is working — which defeats the point of
testing.

## Step 4 — Create test accounts

### iOS sandbox

1. App Store Connect → Users and Access → Sandbox → Test Accounts. Use an email
   address you actually control and can verify.
2. On the device: Settings → App Store → **Sandbox Account** → sign in there.
   Do *not* sign out of your real Apple ID.

### Android license testers

1. Play Console → Setup → **License testing** → add the tester Gmail accounts.
2. Send each tester the closed track **opt-in URL and make sure they open it**.
   Skipping the opt-in is why products silently fail to load.
3. Install once from the closed-track Play link. After that you can `flutter run`
   your own builds on that device and purchases still work.
4. The device needs a **screen lock PIN** set, or subscription purchases fail
   with an unhelpful error.
5. Be signed into exactly **one** Google account on the test device.

## Step 5 — Test

```bash
flutter run --release   # or a debug build once opted in on Android
```

1. Settings → Pro card shows **Upgrade**, not Pro member.
2. Editor → pick a Pro style (Karaoke Box, Word Pop, …). The preview updates and
   the gold "Previewing a Pro style — upgrade to export" chip appears.
3. Export Video → the paywall opens and now lists **real localized prices**. If
   it says "Pricing could not be loaded", the store/offering wiring is wrong,
   not the app.
4. Complete a purchase with the test account. Expect it to be slow — sandbox
   purchases can take 15s or more.
5. On success the sheet closes and the export starts automatically (the paywall
   returns whether the user became Pro so the interrupted action resumes).
6. Settings → now shows **Pro member**.
7. Delete and reinstall the app → Settings → **Restore Purchases** → Pro returns.
8. Verify the purchase appears in RevenueCat → Customer History.

### Faster iOS iteration (optional)

RevenueCat supports **StoreKit Configuration files** on iOS 14+ for simulator
testing, which avoids sandbox account juggling. Two constraints:

- It only works when the app is launched **directly from Xcode** — `flutter run`
  does not apply the configuration file. Open `ios/Runner.xcworkspace` and run
  from there.
- You must use Xcode's *Save Public Certificate* on the StoreKit config and
  upload that certificate to the RevenueCat dashboard, or receipt validation
  fails.

## Sandbox quirks that are not bugs

- Sandbox subscriptions renew up to **6× faster** than production — a monthly
  plan can renew every 5 minutes. Useful for testing renewal, alarming if you
  don't expect it.
- Prices in sandbox and TestFlight frequently don't match App Store Connect;
  TestFlight often reports USD regardless of the tester's storefront.
- RevenueCat caps **100 subscription receipts per customer**, which is easy to
  hit while testing. Create a fresh sandbox account when things get strange.
- Android sandbox subscriptions cancel automatically after ~6 renewals.

## Before shipping

- [ ] `.env` has real keys; `.env.example` has the names but no values.
- [ ] `.env` is git-ignored and not committed.
- [ ] Simulate Pro is off (it is compiled out of release builds by `kDebugMode`,
      but confirm behaviour in a release build anyway).
- [ ] Paywall's Privacy Policy / Terms link resolves — both stores reject
      subscription paywalls without it.
- [ ] iOS: subscription products submitted for review alongside the build.
      Products left in *Missing Metadata* will not load in production.
- [ ] Tested that a free style still exports with no paywall, and that SRT/VTT
      export is never gated.
