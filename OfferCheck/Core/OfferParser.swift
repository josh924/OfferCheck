import Foundation
import CoreGraphics

struct ParsedOffer: Equatable {
    var payout: Double?
    var minutes: Double?
    var miles: Double?
    var deliveries: Int = 1
    var fullText: String = ""
}

/// Pulls pay, time, distance and stop count out of the text on an Uber Eats offer card.
///
/// A typical card reads something like:
///   $9.75
///   Includes expected tip
///   23 min (6.4 mi) total
///   McDonald's · Henderson
enum OfferParser {
    static func parse(_ lines: [RecognizedLine]) -> ParsedOffer {
        var offer = ParsedOffer()
        offer.fullText = lines.map(\.text).joined(separator: "\n")
        let flat = lines.map(\.text).joined(separator: " ")

        offer.payout = payout(from: lines)

        if let trip = tripDurationAndDistance(in: flat) {
            offer.minutes = trip.minutes
            offer.miles = trip.miles
        } else {
            offer.miles = firstNumber(matching: #"(\d+(?:\.\d+)?)\s*mi\b"#, in: flat)
            offer.minutes = duration(in: flat)
        }

        offer.deliveries = deliveryCount(in: flat)
        return offer
    }

    // MARK: - Pay

    /// The offer total is the biggest text on the card, so pick the dollar amount
    /// in the tallest text box. Amounts written "+$2.50" (surge zones, boosts) are ignored.
    static func payout(from lines: [RecognizedLine]) -> Double? {
        var best: (value: Double, height: CGFloat)?
        for line in lines {
            for value in dollarAmounts(in: line.text) {
                if let current = best {
                    if line.height > current.height * 1.05 { best = (value, line.height) }
                } else {
                    best = (value, line.height)
                }
            }
        }
        return best?.value
    }

    static func dollarAmounts(in text: String) -> [Double] {
        matches(of: #"(?<![+\d])\$\s?(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)"#, in: text)
            .compactMap { Double($0.replacingOccurrences(of: ",", with: "")) }
    }

    // MARK: - Time and distance

    /// Matches "23 min (6.4 mi)", "1 hr 5 min (20.1 mi)", "1 hr (18 mi)".
    static func tripDurationAndDistance(in text: String) -> (minutes: Double?, miles: Double)? {
        let pattern = #"((?:\d+\s*hrs?\s*)?(?:\d+\s*mins?)?)\s*\(\s*(\d+(?:\.\d+)?)\s*mi\s*\)"#
        guard let groups = firstMatchGroups(of: pattern, in: text), groups.count == 2,
              let miles = Double(groups[1]) else { return nil }
        return (duration(in: groups[0]), miles)
    }

    static func duration(in text: String) -> Double? {
        let hours = firstNumber(matching: #"(\d+)\s*hrs?\b"#, in: text)
        let mins = firstNumber(matching: #"(\d+)\s*mins?\b"#, in: text)
        if hours == nil && mins == nil { return nil }
        return (hours ?? 0) * 60 + (mins ?? 0)
    }

    // MARK: - Stops

    static func deliveryCount(in text: String) -> Int {
        if let n = firstNumber(matching: #"(\d+)\s*(?:deliveries|orders|dropoffs|drop-offs)\b"#, in: text) {
            return max(1, Int(n))
        }
        if text.range(of: "multiple", options: .caseInsensitive) != nil {
            return 2
        }
        return 1
    }

    // MARK: - Regex helpers

    private static func regex(_ pattern: String) -> NSRegularExpression? {
        try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
    }

    private static func matches(of pattern: String, in text: String) -> [String] {
        guard let re = regex(pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return re.matches(in: text, range: range).compactMap { match in
            guard match.numberOfRanges > 1, let r = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[r])
        }
    }

    private static func firstMatchGroups(of pattern: String, in text: String) -> [String]? {
        guard let re = regex(pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = re.firstMatch(in: text, range: range) else { return nil }
        return (1..<match.numberOfRanges).map { i in
            guard let r = Range(match.range(at: i), in: text) else { return "" }
            return String(text[r])
        }
    }

    private static func firstNumber(matching pattern: String, in text: String) -> Double? {
        matches(of: pattern, in: text).first.flatMap(Double.init)
    }
}
