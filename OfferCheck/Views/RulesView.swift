import SwiftUI

struct RulesView: View {
    @EnvironmentObject private var store: RulesStore

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Active profile", selection: $store.activeID) {
                        ForEach(store.profiles) { profile in
                            Text(profile.name).tag(profile.id)
                        }
                    }
                } footer: {
                    Text("Back Tap checks offers against this profile.")
                }

                Section("Profiles") {
                    ForEach($store.profiles) { $profile in
                        NavigationLink {
                            RuleEditor(rules: $profile)
                        } label: {
                            HStack {
                                Text(profile.name)
                                Spacer()
                                if profile.id == store.activeID {
                                    Image(systemName: "checkmark").foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                    .onDelete { store.delete(at: $0) }

                    Button("Add profile", systemImage: "plus") { store.addProfile() }
                }
            }
            .navigationTitle("Rules")
        }
    }
}

struct RuleEditor: View {
    @Binding var rules: RuleSet
    @State private var newKeyword = ""

    var body: some View {
        Form {
            Section("Name") {
                TextField("Profile name", text: $rules.name)
            }

            Section {
                NumberRow(title: "Minimum pay", prefix: "$", value: $rules.minPayout)
                NumberRow(title: "Minimum per mile", prefix: "$", value: $rules.minPerMile)
                NumberRow(title: "Minimum per hour", prefix: "$", value: $rules.minPerHour)
                NumberRow(title: "Max total miles", prefix: "", value: $rules.maxMiles)
                Stepper(value: $rules.maxDeliveries, in: 0...5) {
                    HStack {
                        Text("Max deliveries")
                        Spacer()
                        Text(rules.maxDeliveries == 0 ? "Any" : "\(rules.maxDeliveries)")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Cutoffs")
            } footer: {
                Text("Set any value to 0 to turn that rule off. Per hour uses the trip time Uber shows.")
            }

            Section {
                ForEach(rules.blockedKeywords, id: \.self) { Text($0) }
                    .onDelete { rules.blockedKeywords.remove(atOffsets: $0) }
                HStack {
                    TextField("e.g. Walmart, Costco", text: $newKeyword)
                        .textInputAutocapitalization(.words)
                        .onSubmit(addKeyword)
                    Button("Add", action: addKeyword)
                        .disabled(newKeyword.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Blocked words")
            } footer: {
                Text("Skip any offer whose screen mentions one of these, like a slow restaurant or a shop order.")
            }
        }
        .navigationTitle(rules.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addKeyword() {
        let k = newKeyword.trimmingCharacters(in: .whitespaces)
        guard !k.isEmpty, !rules.blockedKeywords.contains(k) else { return }
        rules.blockedKeywords.append(k)
        newKeyword = ""
    }
}

private struct NumberRow: View {
    let title: String
    let prefix: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(prefix).foregroundStyle(.secondary)
            TextField("0", value: $value, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
        }
    }
}
