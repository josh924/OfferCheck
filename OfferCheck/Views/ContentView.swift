import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LogView()
                .tabItem { Label("Log", systemImage: "list.bullet.rectangle") }
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
            RulesView()
                .tabItem { Label("Rules", systemImage: "slider.horizontal.3") }
            TestView()
                .tabItem { Label("Test", systemImage: "camera.viewfinder") }
            SetupView()
                .tabItem { Label("Setup", systemImage: "hand.tap") }
        }
    }
}

struct VerdictBadge: View {
    let verdict: Verdict

    var body: some View {
        Text(verdict.label)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch verdict {
        case .take: return .green
        case .skip: return .red
        case .unclear: return .orange
        }
    }
}
