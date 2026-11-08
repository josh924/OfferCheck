import Foundation
import SwiftData

@Model
final class OfferRecord {
    var date: Date
    var payout: Double?
    var miles: Double?
    var minutes: Double?
    var deliveries: Int
    var perMile: Double?
    var perHour: Double?
    var verdictRaw: String
    var reasons: [String]
    var profileName: String
    var rawText: String
    /// What you actually did: "took", "declined", or nil if not marked.
    var decision: String?

    init(result: CheckResult, profileName: String, date: Date = .now) {
        self.date = date
        self.payout = result.offer.payout
        self.miles = result.offer.miles
        self.minutes = result.offer.minutes
        self.deliveries = result.offer.deliveries
        self.perMile = result.evaluation.perMile
        self.perHour = result.evaluation.perHour
        self.verdictRaw = result.evaluation.verdict.rawValue
        self.reasons = result.evaluation.reasons
        self.profileName = profileName
        self.rawText = result.offer.fullText
        self.decision = nil
    }

    var verdict: Verdict { Verdict(rawValue: verdictRaw) ?? .unclear }
}
