import Foundation
import UserNotifications

/// Posts the TAKE / SKIP result as a regular notification from OfferCheck itself,
/// so it shows up no matter how the Shortcut handles the action's output.
enum VerdictNotifier {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func post(_ result: CheckResult) async {
        let offer = result.offer
        let eval = result.evaluation

        var title = "\(eval.verdict.emoji) \(eval.verdict.label)"
        if let pay = offer.payout { title += " · \(Format.money(pay))" }

        var details: [String] = []
        if let m = offer.miles { details.append("\(Format.number(m)) mi") }
        if let pm = eval.perMile { details.append("\(Format.money(pm))/mi") }
        if let ph = eval.perHour { details.append("\(Format.money(ph, decimals: 0))/hr") }
        if offer.deliveries > 1 { details.append("\(offer.deliveries) stops") }
        var body = details.joined(separator: " · ")
        if !eval.reasons.isEmpty {
            body += (body.isEmpty ? "" : "\n") + eval.reasons.joined(separator: " · ")
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body.isEmpty ? "No offer found on screen" : body
        content.sound = .default
        content.interruptionLevel = .active

        let request = UNNotificationRequest(identifier: "offer-verdict", content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}

/// Lets the banner show even while OfferCheck itself is open.
final class ForegroundNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ForegroundNotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
