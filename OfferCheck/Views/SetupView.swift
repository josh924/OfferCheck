import SwiftUI

struct SetupView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("1. Make the shortcut") {
                    step("Open the Shortcuts app and tap + to make a new shortcut.")
                    step("Add the action \"Take Screenshot\".")
                    step("Add \"Check Uber Eats Offer\" (from OfferCheck). It picks up the screenshot automatically.")
                    step("Name it \"Check Offer\" and tap Done.")
                }

                Section("2. Put it on Back Tap") {
                    step("Settings → Accessibility → Touch → Back Tap.")
                    step("Choose Double Tap, scroll down to Shortcuts, and pick \"Check Offer\".")
                }

                Section("3. Use it") {
                    step("When an offer pops up in the Uber Driver app, double-tap the back of your phone.")
                    step("A banner shows TAKE, SKIP or CHECK with the pay, $/mile and $/hour.")
                    step("You still accept or decline in the Uber app yourself.")
                }

                Section("Tips") {
                    step("Pick your active profile in Rules before you start driving.")
                    step("If a number reads wrong, open that offer in the Log to see what the phone read.")
                    step("Swipe right on an offer in the Log to mark whether you took it. Stats use that.")
                }
            }
            .navigationTitle("Setup")
        }
    }

    private func step(_ text: String) -> some View {
        Text(text).font(.subheadline)
    }
}
