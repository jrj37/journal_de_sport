import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var showingAddExercise = false

    var body: some View {
        NavigationStack {
            ExerciseListView {
                Masthead(onAdd: { showingAddExercise = true })
            }
            .background(Ink.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { exerciseId in
                ExerciseDetailView(exerciseId: exerciseId)
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseView()
            }
        }
        .tint(Ink.ember)
    }
}

// MARK: - Masthead — newspaper-style header
private struct Masthead: View {
    @EnvironmentObject var store: WorkoutStore
    let onAdd: () -> Void

    private var todayLine: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE · dd MMMM yyyy"
        return f.string(from: Date()).uppercased()
    }

    private var totalExercises: Int { store.exercises.count }
    private var totalSessions: Int { store.exercises.reduce(0) { $0 + $1.sessions.count } }

    private var bestLift: (name: String, kg: Double)? {
        var best: (String, Double)? = nil
        for ex in store.exercises where !ex.isBodyweight {
            if let w = ex.sessions.map(\.maxWeight).max(), w > 0 {
                if best == nil || w > best!.1 { best = (ex.name, w) }
            }
        }
        return best.map { ($0.0, $0.1) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top rule + date + edition mark
            HStack {
                RunningHead(text: todayLine, color: Ink.paperMute, size: 9)
                Spacer()
                RunningHead(text: "N° \(totalSessions)", color: Ink.paperMute, size: 9)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 10)

            Hairline()

            // Nameplate
            HStack(alignment: .firstTextBaseline) {
                Text("Journal")
                    .font(.system(size: 38, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(Ink.paper)
                Spacer()
                Button(action: onAdd) {
                    Text("＋")
                        .font(.system(size: 26, weight: .regular, design: .serif))
                        .foregroundStyle(Ink.paper)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            HStack {
                Text("de Musculation")
                    .font(.system(size: 38, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(Ink.ember)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            Hairline()
            Hairline().padding(.top, 2)

            // Stats strip — three columns separated by vertical hairlines
            HStack(spacing: 0) {
                statCell(label: "Exercices", value: "\(totalExercises)")
                VHairline().padding(.vertical, 14)
                statCell(label: "Séances", value: "\(totalSessions)")
                VHairline().padding(.vertical, 14)
                bestCell()
            }
            .padding(.horizontal, 20)

            Hairline()
        }
        .padding(.bottom, 4)
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RunningHead(text: label)
            Text(value)
                .font(.displayMed)
                .foregroundStyle(Ink.paper)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }

    @ViewBuilder
    private func bestCell() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RunningHead(text: "Record", color: Ink.ember)
            if let b = bestLift {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Fmt.kg(b.kg))")
                        .font(.displayMed)
                        .foregroundStyle(Ink.paper)
                    Text("kg")
                        .font(.monoSmall)
                        .foregroundStyle(Ink.paperDim)
                        .baselineOffset(2)
                }
                Text(b.name.uppercased())
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Ink.paperMute)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                Text("—")
                    .font(.displayMed)
                    .foregroundStyle(Ink.paperMute)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
    }
}

#Preview {
    ContentView()
        .environmentObject(WorkoutStore())
        .preferredColorScheme(.dark)
}
