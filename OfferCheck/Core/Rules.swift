import Foundation
import SwiftUI

/// One set of cutoffs. A value of 0 means "no limit" for that rule.
struct RuleSet: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var minPayout: Double = 0
    var minPerMile: Double = 0
    var minPerHour: Double = 0
    var maxMiles: Double = 0
    var maxDeliveries: Int = 0
    var blockedKeywords: [String] = []

    static let defaultProfiles: [RuleSet] = [
        RuleSet(name: "Standard", minPayout: 6, minPerMile: 1.5, minPerHour: 20, maxMiles: 12, maxDeliveries: 2),
        RuleSet(name: "Busy (pickier)", minPayout: 8, minPerMile: 2, minPerHour: 25, maxMiles: 10, maxDeliveries: 1),
        RuleSet(name: "Slow (looser)", minPayout: 5, minPerMile: 1.2, minPerHour: 18, maxMiles: 15, maxDeliveries: 2),
    ]
}

/// Stores rule profiles in UserDefaults so the app and the Shortcut action share them.
final class RulesStore: ObservableObject {
    private static let profilesKey = "ruleProfiles"
    private static let activeKey = "activeProfileID"

    @Published var profiles: [RuleSet] { didSet { save() } }
    @Published var activeID: UUID { didSet { save() } }

    init() {
        let loaded = Self.loadProfiles()
        profiles = loaded
        activeID = Self.loadActiveID(in: loaded)
    }

    var active: RuleSet {
        profiles.first { $0.id == activeID } ?? profiles[0]
    }

    func addProfile() {
        var new = active
        new.id = UUID()
        new.name = "New profile"
        profiles.append(new)
        activeID = new.id
    }

    func delete(at offsets: IndexSet) {
        guard profiles.count - offsets.count >= 1 else { return }
        profiles.remove(atOffsets: offsets)
        if !profiles.contains(where: { $0.id == activeID }) {
            activeID = profiles[0].id
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: Self.profilesKey)
        }
        UserDefaults.standard.set(activeID.uuidString, forKey: Self.activeKey)
    }

    private static func loadProfiles() -> [RuleSet] {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode([RuleSet].self, from: data),
           !decoded.isEmpty {
            return decoded
        }
        return RuleSet.defaultProfiles
    }

    private static func loadActiveID(in profiles: [RuleSet]) -> UUID {
        if let raw = UserDefaults.standard.string(forKey: activeKey),
           let id = UUID(uuidString: raw),
           profiles.contains(where: { $0.id == id }) {
            return id
        }
        return profiles[0].id
    }

    /// Used by the Shortcut action, which runs without the SwiftUI environment.
    static func loadActive() -> RuleSet {
        let profiles = loadProfiles()
        let id = loadActiveID(in: profiles)
        return profiles.first { $0.id == id } ?? profiles[0]
    }
}
