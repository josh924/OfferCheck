import SwiftUI
import PhotosUI

/// Try the reader on a saved screenshot, or punch in numbers by hand.
struct TestView: View {
    @EnvironmentObject private var store: RulesStore
    @Environment(\.modelContext) private var context

    @State private var pickerItem: PhotosPickerItem?
    @State private var result: CheckResult?
    @State private var errorText: String?
    @State private var isReading = false
    @State private var saved = false

    @State private var manualPay: Double?
    @State private var manualMiles: Double?
    @State private var manualMinutes: Double?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $pickerItem, matching: .screenshots) {
                        Label("Pick an offer screenshot", systemImage: "photo")
                    }
                    if isReading { ProgressView("Reading…") }
                    if let errorText { Text(errorText).foregroundStyle(.red) }
                    if let result {
                        ResultCard(result: result)
                        Button(saved ? "Saved to log" : "Save to log") {
                            context.insert(OfferRecord(result: result, profileName: store.active.name))
                            saved = true
                        }
                        .disabled(saved)
                    }
                } header: {
                    Text("From a screenshot")
                } footer: {
                    Text("Checks against \(store.active.name).")
                }

                Section("By hand") {
                    numberField("Pay ($)", value: $manualPay)
                    numberField("Miles", value: $manualMiles)
                    numberField("Minutes", value: $manualMinutes)
                    if manualPay != nil {
                        ResultCard(result: manualResult)
                    }
                }
            }
            .navigationTitle("Test")
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task { await read(item) }
            }
        }
    }

    private var manualResult: CheckResult {
        let offer = ParsedOffer(payout: manualPay, minutes: manualMinutes, miles: manualMiles)
        return CheckResult(offer: offer, evaluation: OfferEvaluator.evaluate(offer, rules: store.active))
    }

    private func numberField(_ title: String, value: Binding<Double?>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("—", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
        }
    }

    private func read(_ item: PhotosPickerItem) async {
        isReading = true
        errorText = nil
        result = nil
        saved = false
        defer { isReading = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorText = "Couldn't load that photo."
                return
            }
            let rules = store.active
            result = try await Task.detached(priority: .userInitiated) {
                try OfferChecker.check(imageData: data, rules: rules)
            }.value
        } catch {
            errorText = error.localizedDescription
        }
    }
}

private struct ResultCard: View {
    let result: CheckResult

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VerdictBadge(verdict: result.evaluation.verdict)
                Text(result.offer.payout.map { Format.money($0) } ?? "No pay found").font(.headline)
            }
            HStack(spacing: 12) {
                if let m = result.offer.miles { Text("\(Format.number(m)) mi") }
                if let t = result.offer.minutes { Text("\(Format.number(t)) min") }
                if let pm = result.evaluation.perMile { Text("\(Format.money(pm))/mi") }
                if let ph = result.evaluation.perHour { Text("\(Format.money(ph, decimals: 0))/hr") }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            ForEach(result.evaluation.reasons, id: \.self) { reason in
                Text("• \(reason)").font(.footnote)
            }
        }
        .padding(.vertical, 4)
    }
}
