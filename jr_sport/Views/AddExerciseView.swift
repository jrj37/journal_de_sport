import SwiftUI

struct AddExerciseView: View {
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var category: ExerciseCategory = .chest
    @State private var isBodyweight: Bool = false
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                        // Top heading
                        VStack(alignment: .leading, spacing: 6) {
                            RunningHead(text: "Nouvelle Entrée", color: Ink.ember)
                            Text("Définir un exercice")
                                .font(.system(size: 32, weight: .regular, design: .serif))
                                .italic()
                                .foregroundStyle(Ink.paper)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .padding(.bottom, 24)

                        Hairline()

                        // Name field
                        FieldBlock(label: "Nom") {
                            TextField("", text: $name, prompt: Text("ex. Développé Couché").foregroundColor(Ink.paperMute))
                                .focused($nameFocused)
                                .font(.system(size: 22, weight: .regular, design: .serif))
                                .foregroundStyle(Ink.paper)
                                .tint(Ink.ember)
                                .submitLabel(.next)
                        }

                        Hairline()

                        // Category — chips of monospace text
                        VStack(alignment: .leading, spacing: 14) {
                            RunningHead(text: "Catégorie")
                            FlowChips {
                                ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                                    let selected = category == cat
                                    Button { category = cat } label: {
                                        Text(Fmt.category(cat))
                                            .font(.system(size: 10.5, weight: selected ? .semibold : .regular, design: .monospaced))
                                            .tracking(2)
                                            .foregroundStyle(selected ? Ink.bg : Ink.paper)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(
                                                Rectangle()
                                                    .fill(selected ? Ink.paper : Color.clear)
                                                    .overlay(
                                                        Rectangle()
                                                            .stroke(selected ? Ink.paper : Ink.paperMute, lineWidth: 0.5)
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 22)

                        Hairline()

                        // Bodyweight toggle
                        Button { isBodyweight.toggle() } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    RunningHead(text: "Poids du corps")
                                    Text("Suivre les reps, pas la charge")
                                        .font(.system(size: 14, design: .serif))
                                        .italic()
                                        .foregroundStyle(Ink.paperDim)
                                }
                                Spacer()
                                Text(isBodyweight ? "ON" : "OFF")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .tracking(2)
                                    .foregroundStyle(isBodyweight ? Ink.ember : Ink.paperMute)
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 18)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Hairline()
                    }
                }
                .background(Ink.bg.ignoresSafeArea())
                .toolbar(.hidden, for: .navigationBar)
                .safeAreaInset(edge: .bottom, spacing: 0) {
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
                            Button(action: save) {
                                Text(name.trimmingCharacters(in: .whitespaces).isEmpty ? "AJOUTER —" : "AJOUTER →")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .tracking(2.5)
                                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? Ink.paperMute : Ink.ember)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .contentShape(Rectangle())
                            }
                            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .overlay(alignment: .center) {
                            Rectangle().fill(Ink.rule).frame(width: 0.5)
                        }
                        .background(Ink.bg)
                    }
                }
        }
        .preferredColorScheme(.dark)
        .onAppear { nameFocused = true }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.addExercise(name: trimmed, category: category, isBodyweight: isBodyweight)
        dismiss()
    }
}

// MARK: - Field block (label above input, hairline below)
struct FieldBlock<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RunningHead(text: label)
            content()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
    }
}

// MARK: - Flow-laying chip container
struct FlowChips<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        FlowChipsLayout(spacing: 8) { content() }
    }
}

struct FlowChipsLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let r = arrange(proposal: proposal, subviews: subviews)
        for (i, s) in subviews.enumerated() {
            s.place(at: CGPoint(x: bounds.minX + r.positions[i].x, y: bounds.minY + r.positions[i].y),
                    anchor: .topLeading, proposal: .unspecified)
        }
    }
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxW = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for sv in subviews {
            let sz = sv.sizeThatFits(.unspecified)
            if x + sz.width > maxW, x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            positions.append(.init(x: x, y: y))
            rowH = max(rowH, sz.height)
            x += sz.width + spacing
            maxX = max(maxX, x)
        }
        return (positions, .init(width: maxX, height: y + rowH))
    }
}

#Preview {
    AddExerciseView()
        .environmentObject(WorkoutStore())
        .preferredColorScheme(.dark)
}
