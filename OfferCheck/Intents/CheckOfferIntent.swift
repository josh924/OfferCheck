import AppIntents
import SwiftData

/// The Shortcuts action. Back Tap → Take Screenshot → Check Uber Eats Offer.
struct CheckOfferIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Uber Eats Offer"
    static var description = IntentDescription(
        "Reads an Uber Eats offer screenshot, checks it against your active rules, and logs it."
    )
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Screenshot", supportedTypeIdentifiers: ["public.image"])
    var screenshot: IntentFile

    @Parameter(title: "Save to log", default: true)
    var saveToLog: Bool

    @Parameter(title: "Show result notification", default: true)
    var notify: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Check \(\.$screenshot)") {
            \.$saveToLog
            \.$notify
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let data = screenshot.data
        let rules = RulesStore.loadActive()

        let result = try await Task.detached(priority: .userInitiated) {
            try OfferChecker.check(imageData: data, rules: rules)
        }.value

        if saveToLog {
            let context = Persistence.container.mainContext
            context.insert(OfferRecord(result: result, profileName: rules.name))
            try? context.save()
        }

        if notify {
            await VerdictNotifier.post(result)
        }

        let summary = result.summary
        // Shortcuts shows this as a banner. Turn off "Show result notification"
        // in the action if you only want this one.
        return .result(value: summary, dialog: "\(summary)")
    }
}
