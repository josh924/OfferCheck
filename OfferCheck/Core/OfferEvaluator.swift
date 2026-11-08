import Foundation

enum Verdict: String, Codable {
    case take, skip, unclear

    var emoji: String {
        switch self {
        case .take: return "✅"
        case .skip: return "❌"
        case .unclear: return "⚠️"
        }
    }

    var label: String {
        switch self {
        case .take: return "TAKE"
        case .skip: return "SKIP"
        case .unclear: return "CHECK"
        }
    }
}

struct Evaluation {
    var verdict: Verdict
    var perMile: Double?
    var perHour: Double?
    var reasons: [String]

    /// One line for the banner, e.g. "✅ TAKE · $9.75 · 6.4 mi · $1.52/mi · $25/hr"
    func summary(for offer: ParsedOffer) -> String {
        var parts = ["\(verdict.emoji) \(verdict.label)"]
        if let p = offer.payout { parts.append(Format.money(p)) }
        if let m = offer.miles { parts.append("\(Format.number(m)) mi") }
        if let pm = perMile { parts.append("\(Format.money(pm))/mi") }
        if let ph = perHour { parts.append("\(Format.money(ph, decimals: 0))/hr") }
        var line = parts.joined(separator: " · ")
        if verdict != .take, let first = reasons.first {
            line += "\n\(first)"
        }
        return line
    }
}

enum OfferEvaluator {
    static func evaluate(_ offer: ParsedOffer, rules: RuleSet) -> Evaluation {
        let perMile: Double? = {
            guard let p = offer.payout, let m = offer.miles, m > 0 else { return nil }
            return p / m
        }()
        let perHour: Double? = {
            guard let p = offer.payout, let t = offer.minutes, t > 0 else { return nil }
            return p / t * 60
        }()

        var failures: [String] = []
        var missing: [String] = []

        guard let payout = offer.payout else {
            return Evaluation(verdict: .unclear, perMile: nil, perHour: nil,
                              reasons: ["Couldn't find the pay on screen"])
        }

        if rules.minPayout > 0, payout < rules.minPayout {
            failures.append("Pay under \(Format.money(rules.minPayout))")
        }
        if rules.minPerMile > 0 {
            if let pm = perMile {
                if pm < rules.minPerMile { failures.append("Under \(Format.money(rules.minPerMile))/mi") }
            } else {
                missing.append("Couldn't read the miles")
            }
        }
        if rules.minPerHour > 0 {
            if let ph = perHour {
                if ph < rules.minPerHour { failures.append("Under \(Format.money(rules.minPerHour, decimals: 0))/hr") }
            } else {
                missing.append("Couldn't read the time")
            }
        }
        if rules.maxMiles > 0, let m = offer.miles, m > rules.maxMiles {
            failures.append("Over \(Format.number(rules.maxMiles)) mi")
        }
        if rules.maxDeliveries > 0, offer.deliveries > rules.maxDeliveries {
            failures.append("\(offer.deliveries) deliveries (max \(rules.maxDeliveries))")
        }
        let text = offer.fullText.lowercased()
        for keyword in rules.blockedKeywords {
            let k = keyword.trimmingCharacters(in: .whitespaces).lowercased()
            if !k.isEmpty, text.contains(k) {
                failures.append("Blocked: \(keyword)")
            }
        }

        let verdict: Verdict
        if !failures.isEmpty {
            verdict = .skip
        } else if !missing.isEmpty {
            verdict = .unclear
        } else {
            verdict = .take
        }
        return Evaluation(verdict: verdict, perMile: perMile, perHour: perHour, reasons: failures + missing)
    }
}

struct CheckResult {
    var offer: ParsedOffer
    var evaluation: Evaluation
    var summary: String { evaluation.summary(for: offer) }
}

enum OfferChecker {
    static func check(imageData: Data, rules: RuleSet) throws -> CheckResult {
        let lines = try TextRecognizer.recognize(imageData: imageData)
        let offer = OfferParser.parse(lines)
        return CheckResult(offer: offer, evaluation: OfferEvaluator.evaluate(offer, rules: rules))
    }
}

enum Format {
    static func money(_ value: Double, decimals: Int = 2) -> String {
        "$" + String(format: "%.\(decimals)f", value)
    }

    static func number(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
