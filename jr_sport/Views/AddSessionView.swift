import SwiftUI

struct AddSessionView: View {
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss

    let exerciseId: UUID
    let exerciseName: String
    var existingSession: SessionEntry? = nil

    @State private var date = Date()
    @State private var setsInput: String = ""
    @State private var parsedSets: [WorkoutSet] = []
    @State private var manualSets: [SetInput] = [SetInput()]
    @State private var inputMode: InputMode = .quick
    @FocusState private var quickFocused: Bool

    enum InputMode: String, CaseIterable {
        case quick = "RAPIDE"
        case manual = "MANUEL"
    }

    private var isEditing: Bool { existingSession != nil }

    init(exerciseId: UUID, exerciseName: String, existingSession: SessionEntry? = nil) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.existingSession = existingSession
        if let session = existingSession {
            _date = State(initialValue: session.date)
            _inputMode = State(initialValue: .manual)
            _manualSets = State(initialValue: session.sets.map { set in
                var s = SetInput()
                s.reps = "\(set.reps)"
                s.weight = set.weight == set.weight.rounded()
                    ? "\(Int(set.weight))"
                    : String(format: "%.1f", set.weight)
                return s
            })
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    Hairline()

                    dateBlock
                    Hairline()

                    modeBlock
                    Hairline()

                    if inputMode == .quick { quickBlock } else { manualBlock }

                    if !summarySets.isEmpty {
                        Hairline()
                        summaryBlock
                    }
                }
            }
            .background(Ink.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !isEditing { quickFocused = true }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            RunningHead(text: isEditing ? "Modifier la séance" : "Nouvelle séance", color: Ink.ember)
            Text(exerciseName)
                .font(.system(size: 30, weight: .regular, design: .serif))
                .foregroundStyle(Ink.paper)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 22)
    }

    // MARK: - Date
    private var dateBlock: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                RunningHead(text: "Date")
                Text(Fmt.dateline(date))
                    .font(.system(size: 18, weight: .regular, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Ink.paper)
            }
            Spacer()
            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "fr_FR"))
                .tint(Ink.ember)
                .colorScheme(.dark)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
    }

    // MARK: - Mode toggle
    private var modeBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            RunningHead(text: "Mode de saisie")
            HStack(spacing: 22) {
                ForEach(InputMode.allCases, id: \.self) { m in
                    Button { inputMode = m } label: {
                        VStack(spacing: 5) {
                            Text(m.rawValue)
                                .font(.system(size: 11, weight: inputMode == m ? .semibold : .regular, design: .monospaced))
                                .tracking(2.5)
                                .foregroundStyle(inputMode == m ? Ink.paper : Ink.paperMute)
                            Rectangle()
                                .fill(inputMode == m ? Ink.ember : Color.clear)
                                .frame(width: 18, height: 1.5)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    // MARK: - Quick input
    private var quickBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            RunningHead(text: "Notation rapide")
            TextField("", text: $setsInput,
                      prompt: Text("3x70  5x65  5x60").foregroundColor(Ink.paperMute))
                .focused($quickFocused)
                .font(.system(size: 24, weight: .regular, design: .monospaced))
                .foregroundStyle(Ink.paper)
                .tint(Ink.ember)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: setsInput) { _, new in
                    parsedSets = WorkoutStore.parseSets(from: new)
                }
            Text("reps × poids, séparés par espace")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Ink.paperDim)
                .tracking(0.5)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
    }

    // MARK: - Manual input
    private var manualBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                RunningHead(text: "Séries")
                Spacer()
                Button { manualSets.append(SetInput()) } label: {
                    HStack(spacing: 5) {
                        Text("AJOUTER SÉRIE")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .tracking(2)
                        Text("＋")
                            .font(.system(size: 14, design: .serif))
                    }
                    .foregroundStyle(Ink.ember)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 0) {
                ForEach(manualSets) { setItem in
                    let idx = manualSets.firstIndex(where: { $0.id == setItem.id }) ?? 0
                    HStack(spacing: 14) {
                        Text(String(format: "№%02d", idx + 1))
                            .font(.system(size: 10, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(Ink.paperMute)
                            .frame(width: 32, alignment: .leading)

                        HStack(spacing: 6) {
                            TextField("", text: $manualSets[idx].reps,
                                      prompt: Text("0").foregroundColor(Ink.paperMute))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 22, weight: .regular, design: .serif))
                                .foregroundStyle(Ink.paper)
                                .tint(Ink.ember)
                                .frame(width: 60)
                            Text("reps")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Ink.paperDim)
                                .tracking(1)
                        }

                        Text("×")
                            .font(.system(size: 18, design: .serif))
                            .foregroundStyle(Ink.paperMute)

                        HStack(spacing: 6) {
                            TextField("", text: $manualSets[idx].weight,
                                      prompt: Text("0").foregroundColor(Ink.paperMute))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .font(.system(size: 22, weight: .regular, design: .serif))
                                .foregroundStyle(Ink.paper)
                                .tint(Ink.ember)
                                .frame(width: 70)
                            Text("kg")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Ink.paperDim)
                                .tracking(1)
                        }

                        Spacer()

                        if manualSets.count > 1 {
                            Button {
                                manualSets.removeAll { $0.id == setItem.id }
                            } label: {
                                Text("×")
                                    .font(.system(size: 20, design: .serif))
                                    .foregroundStyle(Ink.paperMute)
                                    .padding(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 12)
                    if idx < manualSets.count - 1 {
                        Hairline(color: Ink.rule.opacity(0.6))
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
    }

    // MARK: - Summary
    private var summarySets: [WorkoutSet] {
        switch inputMode {
        case .quick: return parsedSets
        case .manual: return manualSets.compactMap { $0.toWorkoutSet() }
        }
    }

    private var summaryBlock: some View {
        let sets = summarySets
        let volume = sets.reduce(0.0) { $0 + $1.volume }
        let maxW = sets.map(\.weight).max() ?? 0
        let totalReps = sets.reduce(0) { $0 + $1.reps }

        return HStack(spacing: 0) {
            summaryCol(label: "Séries", value: "\(sets.count)")
            VHairline().padding(.vertical, 16)
            summaryCol(label: "Reps", value: "\(totalReps)")
            VHairline().padding(.vertical, 16)
            if maxW > 0 {
                summaryCol(label: "Top", value: "\(Fmt.kg(maxW))", unit: "kg", color: Ink.ember)
                VHairline().padding(.vertical, 16)
                summaryCol(label: "Volume", value: "\(Int(volume))", unit: "kg")
            } else {
                summaryCol(label: "Top", value: "—")
                VHairline().padding(.vertical, 16)
                summaryCol(label: "Volume", value: "—")
            }
        }
        .padding(.horizontal, 8)
    }

    private func summaryCol(label: String, value: String, unit: String? = nil, color: Color = Color(red: 0.949, green: 0.922, blue: 0.851)) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RunningHead(text: label)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .regular, design: .serif))
                    .foregroundStyle(color)
                if let u = unit {
                    Text(u)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Ink.paperDim)
                        .baselineOffset(2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
    }

    // MARK: - Bottom bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Hairline()
            HStack(spacing: 0) {
                Button { dismiss() } label: {
                    Text("ANNULER")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(2.5)
                        .foregroundStyle(Ink.paperDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .contentShape(Rectangle())
                }
                Button(action: saveSession) {
                    Text(isValid ? (isEditing ? "ENREG. →" : "AJOUTER →") : "—")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .tracking(2.5)
                        .foregroundStyle(isValid ? Ink.ember : Ink.paperMute)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .contentShape(Rectangle())
                }
                .disabled(!isValid)
            }
            .overlay(alignment: .center) {
                Rectangle().fill(Ink.rule).frame(width: 0.5)
            }
            .background(Ink.bg)
        }
    }

    private var isValid: Bool {
        switch inputMode {
        case .quick: return !parsedSets.isEmpty
        case .manual: return manualSets.contains { $0.toWorkoutSet() != nil }
        }
    }

    private func saveSession() {
        let sets: [WorkoutSet]
        switch inputMode {
        case .quick: sets = parsedSets
        case .manual: sets = manualSets.compactMap { $0.toWorkoutSet() }
        }
        guard !sets.isEmpty else { return }
        if let existing = existingSession {
            var updated = existing
            updated.date = date
            updated.sets = sets
            store.updateSession(in: exerciseId, session: updated)
        } else {
            let session = SessionEntry(date: date, sets: sets)
            store.addSession(to: exerciseId, session: session)
        }
        dismiss()
    }
}

// MARK: - Helper for manual input
struct SetInput: Identifiable {
    let id = UUID()
    var reps: String = ""
    var weight: String = ""

    func toWorkoutSet() -> WorkoutSet? {
        guard let r = Int(reps), r > 0,
              let w = Double(weight.replacingOccurrences(of: ",", with: ".")), w >= 0 else {
            return nil
        }
        return WorkoutSet(reps: r, weight: w)
    }
}

#Preview {
    AddSessionView(exerciseId: UUID(), exerciseName: "Développé Couché")
        .environmentObject(WorkoutStore())
        .preferredColorScheme(.dark)
}
