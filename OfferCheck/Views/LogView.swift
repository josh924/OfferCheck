import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \OfferRecord.date, order: .reverse) private var records: [OfferRecord]

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No offers yet",
                        systemImage: "hand.tap",
                        description: Text("Double-tap the back of your phone when an offer shows up. See the Setup tab.")
                    )
                } else {
                    List {
                        ForEach(records) { record in
                            NavigationLink {
                                OfferDetailView(record: record)
                            } label: {
                                OfferRow(record: record)
                            }
                            .swipeActions(edge: .leading) {
                                Button("Took it") { record.decision = "took" }.tint(.green)
                                Button("Declined") { record.decision = "declined" }.tint(.gray)
                            }
                        }
                        .onDelete { offsets in
                            for i in offsets { context.delete(records[i]) }
                        }
                    }
                }
            }
            .navigationTitle("Offers")
        }
    }
}

struct OfferRow: View {
    let record: OfferRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(record.payout.map { Format.money($0) } ?? "—").font(.headline)
                VerdictBadge(verdict: record.verdict)
                if let d = record.decision {
                    Text(d == "took" ? "Took" : "Declined")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(record.date, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                if let m = record.miles { Text("\(Format.number(m)) mi") }
                if let pm = record.perMile { Text("\(Format.money(pm))/mi") }
                if let ph = record.perHour { Text("\(Format.money(ph, decimals: 0))/hr") }
                if record.deliveries > 1 { Text("\(record.deliveries) stops") }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

struct OfferDetailView: View {
    @Bindable var record: OfferRecord

    var body: some View {
        Form {
            Section {
                LabeledContent("Verdict") { VerdictBadge(verdict: record.verdict) }
                LabeledContent("Pay", value: record.payout.map { Format.money($0) } ?? "Not found")
                LabeledContent("Miles", value: record.miles.map { Format.number($0) } ?? "Not found")
                LabeledContent("Minutes", value: record.minutes.map { Format.number($0) } ?? "Not found")
                LabeledContent("Deliveries", value: "\(record.deliveries)")
                LabeledContent("Per mile", value: record.perMile.map { Format.money($0) } ?? "—")
                LabeledContent("Per hour", value: record.perHour.map { Format.money($0, decimals: 0) } ?? "—")
                LabeledContent("Profile", value: record.profileName)
                LabeledContent("Time", value: record.date.formatted(date: .abbreviated, time: .shortened))
            }

            Section("What you did") {
                Picker("Decision", selection: $record.decision) {
                    Text("Not marked").tag(String?.none)
                    Text("Took it").tag(String?.some("took"))
                    Text("Declined").tag(String?.some("declined"))
                }
                .pickerStyle(.segmented)
            }

            if !record.reasons.isEmpty {
                Section("Why") {
                    ForEach(record.reasons, id: \.self) { Text($0) }
                }
            }

            Section {
                Text(record.rawText.isEmpty ? "(no text)" : record.rawText)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            } header: {
                Text("Text read from screen")
            } footer: {
                Text("If a number came out wrong, this shows what the phone actually read.")
            }
        }
        .navigationTitle("Offer")
        .navigationBarTitleDisplayMode(.inline)
    }
}
