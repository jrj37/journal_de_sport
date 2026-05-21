import SwiftUI

struct ExerciseListView<Header: View>: View {
    @EnvironmentObject var store: WorkoutStore
    @State private var selectedCategory: ExerciseCategory?

    @ViewBuilder var header: () -> Header

    var filteredExercises: [Exercise] {
        if let cat = selectedCategory {
            return store.exercises.filter { $0.category == cat }
        }
        return store.exercises
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                header()

                Section {
                    if filteredExercises.isEmpty {
                        emptyState
                    } else {
                        ForEach(Array(filteredExercises.enumerated()), id: \.element.id) { idx, exercise in
                            NavigationLink(value: exercise.id) {
                                ExerciseRow(exercise: exercise, index: idx + 1)
                            }
                            .buttonStyle(.plain)
                            Hairline()
                        }
                    }
                } header: {
                    VStack(spacing: 0) {
                        categoryStrip
                        Hairline()
                    }
                    .background(Ink.bg)
                }
            }
        }
        .background(Ink.bg)
    }

    // MARK: - Category strip (text only, with serif italic active marker)
    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 22) {
                categoryItem(title: "TOUT", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                    categoryItem(title: Fmt.category(cat), isSelected: selectedCategory == cat) {
                        selectedCategory = selectedCategory == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }

    private func categoryItem(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 10.5, weight: isSelected ? .semibold : .regular, design: .monospaced))
                    .tracking(2.5)
                    .foregroundStyle(isSelected ? Ink.paper : Ink.paperMute)
                Rectangle()
                    .fill(isSelected ? Ink.ember : Color.clear)
                    .frame(width: 14, height: 1.5)
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer().frame(height: 60)
            RunningHead(text: "— Rien ici —", color: Ink.paperMute, size: 10)
            Text("Ajoutez votre premier exercice")
                .font(.system(size: 22, design: .serif))
                .italic()
                .foregroundStyle(Ink.paperDim)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

extension ExerciseListView where Header == EmptyView {
    init() {
        self.init(header: { EmptyView() })
    }
}

// MARK: - Exercise row
struct ExerciseRow: View {
    let exercise: Exercise
    let index: Int

    private var heroValue: (value: String, unit: String)? {
        if exercise.isBodyweight {
            if let reps = exercise.sortedSessions.flatMap(\.sets).map(\.reps).max(), reps > 0 {
                return ("\(reps)", "reps")
            }
        } else if let best = exercise.sortedSessions.map(\.maxWeight).max(), best > 0 {
            return (Fmt.kg(best), "kg")
        }
        return nil
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            // Running number — like a chapter mark
            Text(String(format: "%02d", index))
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .tracking(1)
                .foregroundStyle(Ink.paperMute)
                .frame(width: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.name)
                    .font(.system(size: 19, weight: .regular, design: .serif))
                    .foregroundStyle(Ink.paper)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(Fmt.category(exercise.category))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .tracking(1.8)
                        .foregroundStyle(Ink.ember)
                    Text("·")
                        .foregroundStyle(Ink.paperMute)
                    if let last = exercise.sortedSessions.last {
                        Text(last.summary)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundStyle(Ink.paperDim)
                            .lineLimit(1)
                    } else {
                        Text("aucune séance")
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundStyle(Ink.paperMute)
                            .italic()
                    }
                }
            }

            Spacer(minLength: 8)

            if let h = heroValue {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(h.value)
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundStyle(Ink.paper)
                    Text(h.unit)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Ink.paperDim)
                        .baselineOffset(2)
                }
            } else {
                Text("—")
                    .font(.system(size: 24, design: .serif))
                    .foregroundStyle(Ink.paperMute)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
        .background(Ink.bg)
    }
}

#Preview {
    NavigationStack {
        ExerciseListView()
            .environmentObject(WorkoutStore())
    }
    .preferredColorScheme(.dark)
}
