import SwiftUI
import SwiftData
import UserNotifications

@main
struct OfferCheckApp: App {
    @StateObject private var rules = RulesStore()

    init() {
        UNUserNotificationCenter.current().delegate = ForegroundNotificationDelegate.shared
        VerdictNotifier.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(rules)
        }
        .modelContainer(Persistence.container)
    }
}

enum Persistence {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: OfferRecord.self)
        } catch {
            fatalError("Could not create the offer log: \(error)")
        }
    }()
}
