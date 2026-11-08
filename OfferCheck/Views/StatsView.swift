import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \OfferRecord.date, order: .reverse) private var records: [OfferRecord]
    @State private var range: StatsRange = .week

    enum StatsRange: String, CaseIterable, Identifiable {
        case today = "Today", week = "7 days", month = "30 days", all = "All"
        var id: Self { self }

        var start: Date? {
            let cal = Calendar.current
            switch self {
            case .today: return cal.startOfDay(for: .now)
            case .week: return cal.date(byAdding: .day, value: -7, to: .now)
            case .month: return cal.date(byAdding: .day, value: -30, to: .now)
            case .all: return nil
            }
        }
    }

    private var filtered: [OfferRecord] {
        guard let start = range.start else { return records }
        return records.filter { $0.date >= start }
    }

    private struct HourStat: Identifiable {
        let hour: Int
        let count: Int
        let avgPerMile: Double
        var id: Int { hour }
        var label: String {
            let h = hour % 12 == 0 ? 12 : hour % 12
            return "\(h)\(hour < 12 ? "a" : "p")"
        }
    }

    private var byHour: [HourStat] {
        let grouped = Dictionary(grouping: filtered.filter { $0.perMile != nil }) {
            Calendar.current.component(.hour, from: $0.date)
        }
        return grouped.map { hour, recs in
            let values = recs.compactMap(\.perMile)
            return HourStat(hour: hour, count: recs.count, avgPerMile: values.reduce(0, +) / Double(values.count))
        }
        .sorted { $0.hour < $1.hour }
    }

    var body: some View {
        NavigationStack {
            List {
                Picker("Range", selection: $range) {
                    ForEach(StatsRange.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                if filtered.isEmpty {
                    ContentUnavailableView("No offers in this range", systemImage: "chart.bar")
                } else {
                    Section("Overview") {
                        let passed = filtered.filter { $0.verdict == .take }.count
                        LabeledContent("Offers checked", value: "\(filtered.count)")
                        LabeledContent("Met your rules", value: "\(passed) (\(percent(passed, of: filtered.count)))")
                        LabeledContent("Avg pay", value: average(filtered.compactMap(\.payout)).map { Format.money($0) } ?? "—")
                        LabeledContent("Avg per mile", value: average(filtered.compactMap(\.perMile)).map { Format.money($0) } ?? "—")
                        LabeledContent("Avg per hour", value: average(filtered.compactMap(\.perHour)).map { Format.money($0, decimals: 0) } ?? "—")
                    }

                    let took = filtered.filter { $0.decision == "took" }
                    if !took.isEmpty {
                        Section("Orders you took") {
                            LabeledContent("Count", value: "\(took.count)")
                            LabeledContent("Total pay", value: Format.money(took.compactMap(\.payout).reduce(0, +)))
                            LabeledContent("Total miles", value: Format.number(took.compactMap(\.miles).reduce(0, +)))
                            LabeledContent("Avg per mile", value: average(took.compactMap(\.perMile)).map { Format.money($0) } ?? "—")
                        }
                    }

                    if !byHour.isEmpty {
                        Section("Avg $/mile by hour") {
                            Chart(byHour) { stat in
                                BarMark(
                                    x: .value("Hour", stat.label),
                                    y: .value("$/mi", stat.avgPerMile)
                                )
                                .annotation(position: .top) {
                                    Text(String(format: "%.2f", stat.avgPerMile))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(height: 200)

                            if let best = byHour.max(by: { $0.avgPerMile < $1.avgPerMile }) {
                                Text("Best hour: \(best.label) at \(Format.money(best.avgPerMile))/mi across \(best.count) offers")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private func average(_ values: [Double]) -> Double? {
        values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }

    private func percent(_ part: Int, of total: Int) -> String {
        total == 0 ? "0%" : "\(Int((Double(part) / Double(total) * 100).rounded()))%"
    }
}
