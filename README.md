# OfferCheck

An iPhone companion for Uber Eats. When an offer pops up, double-tap the back of your phone: OfferCheck screenshots it, reads the pay, miles and time on-device, checks them against your rules, and shows a banner like:

    ✅ TAKE · $9.75 · 6.4 mi · $1.52/mi · $25/hr
    ❌ SKIP · $5.10 · 7.8 mi · $0.65/mi · $14/hr
    Under $1.50/mi

You still accept or decline in the Uber Driver app. OfferCheck never logs into Uber, never sends data anywhere, and never taps anything for you.

## What's in it

- **Rules:** profiles (Standard / Busy / Slow to start) with minimum pay, $/mile, $/hour, max miles, max deliveries, and blocked words (e.g. a slow restaurant or "Shop").
- **Log:** every checked offer, with what the phone read. Swipe right to mark Took it / Declined.
- **Stats:** offers checked, % that met your rules, averages, totals for orders you took, and average $/mile by hour of day.
- **Test:** run the reader on a saved screenshot, or type numbers in by hand.
- **Setup:** the Shortcut + Back Tap steps, in the app.

## Requirements

- A Mac with Xcode 16 or later
- iPhone on iOS 17 or later, USB cable
- A free Apple ID works. Apps signed with a free account expire after 7 days, so you'd reconnect and hit Run again each week. A paid developer account ($99/yr) makes installs last a year.

## Build and install

**Option A: XcodeGen (quickest)**

```sh
brew install xcodegen
cd OfferCheck
xcodegen
open OfferCheck.xcodeproj
```

**Option B: by hand**

1. Xcode → File → New → Project → iOS App. Name it `OfferCheck`, Interface SwiftUI, Storage None.
2. Delete the generated `ContentView.swift` and `OfferCheckApp.swift`.
3. Drag the `OfferCheck/Core`, `Intents` and `Views` folders plus `OfferCheckApp.swift` into the project (check "Copy items if needed").
4. Set the deployment target to iOS 17.0.

**Then:**

1. Select the OfferCheck target → Signing & Capabilities → pick your Team (your Apple ID).
2. Plug in your iPhone, pick it as the run destination, press Run.
3. First time only: on the phone, Settings → Privacy & Security → Developer Mode → on (it restarts), then Settings → General → VPN & Device Management → trust your developer certificate.

## Hook up Back Tap

1. Shortcuts app → **+** → add **Take Screenshot** → add **Check Uber Eats Offer** → name it "Check Offer".
2. Settings → Accessibility → Touch → Back Tap → Double Tap → **Check Offer**.

## Tuning

The reader takes the dollar amount in the largest text as the offer total (so "+$2.50" surge labels and small "Includes $2.00 promotion" lines are ignored), and reads time/distance from text like `23 min (6.4 mi) total`. If Uber changes its layout and something reads wrong, open the offer in the Log. "Text read from screen" shows exactly what the phone saw, and the patterns live in `Core/OfferParser.swift`.

## Files

```
OfferCheck/
  OfferCheckApp.swift        app entry + offer log storage
  Core/Rules.swift           rule profiles
  Core/TextRecognizer.swift  on-device text reading (Vision)
  Core/OfferParser.swift     pulls pay / miles / time / stops from the text
  Core/OfferEvaluator.swift  checks an offer against your rules
  Core/OfferRecord.swift     log entry
  Intents/CheckOfferIntent.swift  the Shortcuts action
  Views/                     Log, Stats, Rules, Test, Setup tabs
project.yml                  XcodeGen spec
```

## No Mac? Build on GitHub, install from Windows

1. Make a GitHub repo and upload everything in this folder, including the hidden `.github` folder.
2. Repo → Actions → "Build unsigned IPA" → Run workflow. It builds on one of GitHub's Macs, which takes about 5–10 minutes.
3. Open the finished run and download the `OfferCheck-ipa` artifact. Unzip it to get `OfferCheck.ipa`.
4. On Windows, install iTunes and iCloud (the versions from apple.com, not the Microsoft Store), then install Sideloadly.
5. Plug in your iPhone, drag `OfferCheck.ipa` into Sideloadly, enter your Apple ID, and click Start.
6. On the phone: Settings → Privacy & Security → Developer Mode → on, then Settings → General → VPN & Device Management → trust your Apple ID.

A free Apple ID still means re-signing every 7 days. Sideloadly can refresh it automatically over Wi-Fi while your PC is on.
