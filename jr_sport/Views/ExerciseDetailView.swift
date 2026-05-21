import SwiftUI
import Charts

struct ExerciseDetailView: View {
    @EnvironmentObject var store: WorkoutStore
    @Environment(\.dismiss) var dismiss
    let exerciseId: UUID

    @State private var showingAddSession = false
    @State private var sessionToEdit: SessionEntry? = nil
    @State private var selectedMetric: ChartMetric = .maxWeight
    @State private var hasSetInitialMetric = false
    @State private var selectedDate: Date?

    enum ChartMetric: String, CaseIterable {
        case maxWeight = "CHARGE MAX"
        case estimated1RM = "1RM EST."
        case avgLoad = "CHARGE MOY"
        case volume = "VOLUME"
        case totalReps = "REPS TOTAL"
        case maxRepsInSet = "MEILL. SÉRIE"
    }

    var exercise: Exercise? {
        store.exercises.first { $0.id == exerciseId }
    }

    var availableMetrics: [ChartMetric] {
        if exercise?.isBodyweight == true {
            return [.maxRepsInSet, .totalReps]
        }
        return [.maxWeight, .estimated1RM, .avgLoad, .volume, .totalReps]
    }

    var body: some View {
        ZStack(alignment: .top) {
            Ink.bg.ignoresSafeArea()

            if let exercise {
                ScrollView {
                    VStack(spacing: 0) {
                        hero(exercise)
                        statsStrip(exercise)
                        chartSection(exercise)
                        analysisSection(exercise)
                        historySection(exercise)
                        Spacer(minLength: 60)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .onAppear {
            if !hasSetInitialMetric, let ex = exercise {
                hasSetInitialMetric = true
                if ex.isBodyweight { selectedMetric = .totalReps }
            }
        }
        .sheet(isPresented: $showingAddSession) {
            if let exercise {
                AddSessionView(exerciseId: exercise.id, exerciseName: exercise.name)
            }
        }
        .sheet(item: $sessionToEdit) { session in
            if let exercise {
                AddSessionView(exerciseId: exercise.id, exerciseName: exercise.name, existingSession: session)
            }
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    HStack(spacing: 6) {
                        Text("←")
                            .font(.system(size: 22, weight: .regular, design: .serif))
                        Text("RETOUR")
                            .font(.monoLabel)
                            .tracking(2)
                    }
                    .foregroundStyle(Ink.paper)
                }
                Spacer()
                Button { showingAddSession = true } label: {
                    HStack(spacing: 6) {
                        Text("AJOUTER")
                            .font(.monoLabel)
                            .tracking(2)
                        Text("＋")
                            .font(.system(size: 18, weight: .regular, design: .serif))
                    }
                    .foregroundStyle(Ink.ember)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Ink.bg)

            Hairline()
        }
    }

    // MARK: - Hero
    @ViewBuilder
    private func hero(_ exercise: Exercise) -> some View {
        let sessions = exercise.sortedSessions
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                RunningHead(text: Fmt.category(exercise.category), color: Ink.ember, size: 10)
                Spacer()
                if let last = sessions.last {
                    RunningHead(text: "Dernier · \(Fmt.dateline(last.date))", color: Ink.paperMute, size: 9)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 14)

            Text(exercise.name)
                .font(.system(size: 38, weight: .regular, design: .serif))
                .foregroundStyle(Ink.paper)
                .padding(.horizontal, 20)
                .padding(.bottom, 22)

            // Massive hero number
            if !sessions.isEmpty {
                if exercise.isBodyweight {
                    let best = sessions.flatMap(\.sets).map(\.reps).max() ?? 0
                    heroFigure(value: "\(best)", unit: "reps", label: "Record Personnel")
                } else {
                    let best = sessions.map(\.maxWeight).max() ?? 0
                    heroFigure(value: Fmt.kg(best), unit: "kg", label: "Record Personnel")
                }
            } else {
                Text("—")
                    .font(.displayLarge)
                    .foregroundStyle(Ink.paperMute)
                    .padding(.horizontal, 20)
            }

            Hairline().padding(.top, 22)
        }
    }

    private func heroFigure(value: String, unit: String, label: String) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                RunningHead(text: label, color: Ink.paperDim)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 92, weight: .regular, design: .serif))
                        .foregroundStyle(Ink.paper)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(unit)
                        .font(.system(size: 18, design: .monospaced))
                        .foregroundStyle(Ink.paperDim)
                        .baselineOffset(6)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Stats strip (3 columns, hairline-divided)
    @ViewBuilder
    private func statsStrip(_ exercise: Exercise) -> some View {
        let sessions = exercise.sortedSessions
        if sessions.count >= 2 {
            let first = metricValue(sessions.first!, for: selectedMetric)
            let last = metricValue(sessions.last!, for: selectedMetric)
            let pct = first > 0 ? ((last - first) / first) * 100 : 0
            let pctStr = (pct >= 0 ? "+" : "") + String(format: "%.0f", pct) + "%"
            let totalVol = sessions.reduce(0.0) { $0 + $1.totalVolume }

            HStack(spacing: 0) {
                statCol(label: "Séances", value: "\(sessions.count)", color: Ink.paper)
                VHairline().padding(.vertical, 16)
                statCol(label: "Progrès", value: pctStr, color: pct >= 0 ? Ink.ember : Ink.paperDim)
                VHairline().padding(.vertical, 16)
                statCol(label: "Volume", value: "\(Int(totalVol/1000))k", color: Ink.paper)
            }
            .padding(.horizontal, 8)

            Hairline()
        }
    }

    private func statCol(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            RunningHead(text: label)
            Text(value)
                .font(.system(size: 26, weight: .regular, design: .serif))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 18)
    }

    // MARK: - Chart
    @ViewBuilder
    private func chartSection(_ exercise: Exercise) -> some View {
        let sessions = exercise.sortedSessions

        VStack(alignment: .leading, spacing: 0) {
            // Metric tabs — text-only with underline
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(availableMetrics, id: \.self) { m in
                        Button { selectedMetric = m } label: {
                            VStack(spacing: 5) {
                                Text(m.rawValue)
                                    .font(.system(size: 10.5, weight: selectedMetric == m ? .semibold : .regular, design: .monospaced))
                                    .tracking(2.5)
                                    .foregroundStyle(selectedMetric == m ? Ink.paper : Ink.paperMute)
                                Rectangle()
                                    .fill(selectedMetric == m ? Ink.ember : Color.clear)
                                    .frame(width: 14, height: 1.5)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }

            if sessions.count >= 2 {
                chartBody(sessions)
                    .frame(height: 200)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            } else {
                VStack(spacing: 10) {
                    Spacer()
                    RunningHead(text: "Données insuffisantes", color: Ink.paperMute)
                    Text("Il faut deux séances")
                        .font(.system(size: 18, design: .serif))
                        .italic()
                        .foregroundStyle(Ink.paperDim)
                    Spacer()
                }
                .frame(height: 160)
                .frame(maxWidth: .infinity)
            }

            Hairline()
        }
    }

    private func chartBody(_ sessions: [SessionEntry]) -> some View {
        let selected = nearestSession(to: selectedDate, in: sessions)

        return Chart {
            ForEach(sessions) { session in
                AreaMark(
                    x: .value("Date", session.date),
                    y: .value("v", metricValue(session, for: selectedMetric))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Ink.ember.opacity(0.32),
                            Ink.ember.opacity(0.08),
                            Ink.ember.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.monotone)

                LineMark(
                    x: .value("Date", session.date),
                    y: .value("v", metricValue(session, for: selectedMetric))
                )
                .foregroundStyle(Ink.ember)
                .lineStyle(StrokeStyle(lineWidth: 1.2))
                .interpolationMethod(.monotone)

                PointMark(
                    x: .value("Date", session.date),
                    y: .value("v", metricValue(session, for: selectedMetric))
                )
                .foregroundStyle(Ink.bg)
                .symbolSize(28)
                .annotation(position: .overlay) {
                    Circle()
                        .stroke(Ink.ember, lineWidth: 1.2)
                        .frame(width: 6, height: 6)
                }
            }

            if let selected {
                RuleMark(x: .value("Date", selected.date))
                    .foregroundStyle(Ink.paperDim.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 0.6, dash: [2, 3]))

                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("v", metricValue(selected, for: selectedMetric))
                )
                .foregroundStyle(Ink.ember)
                .symbolSize(80)
                .annotation(
                    position: .top,
                    alignment: .center,
                    spacing: 8,
                    overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                ) {
                    tooltip(for: selected)
                }
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [2, 3]))
                    .foregroundStyle(Ink.rule)
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Ink.paperMute)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [2, 3]))
                    .foregroundStyle(Ink.rule)
                AxisValueLabel()
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Ink.paperMute)
            }
        }
    }

    private func nearestSession(to date: Date?, in sessions: [SessionEntry]) -> SessionEntry? {
        guard let date else { return nil }
        return sessions.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
    }

    @ViewBuilder
    private func tooltip(for session: SessionEntry) -> some View {
        let value = metricValue(session, for: selectedMetric)
        let unit = tooltipUnit(for: selectedMetric)
        let valueText: String = {
            switch selectedMetric {
            case .totalReps, .maxRepsInSet:
                return "\(Int(value))"
            default:
                return Fmt.kg(value)
            }
        }()

        VStack(alignment: .leading, spacing: 4) {
            Text(Fmt.dateline(session.date))
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .tracking(1.3)
                .foregroundStyle(Ink.paperMute)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(valueText)
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .foregroundStyle(Ink.paper)
                if let unit {
                    Text(unit)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Ink.paperDim)
                        .baselineOffset(1)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            ZStack {
                Ink.bg
                Rectangle().stroke(Ink.rule, lineWidth: 0.5)
            }
        )
    }

    private func tooltipUnit(for metric: ChartMetric) -> String? {
        switch metric {
        case .maxWeight, .estimated1RM, .avgLoad: return "kg"
        case .volume: return "kg·rep"
        case .totalReps, .maxRepsInSet: return "reps"
        }
    }

    // MARK: - Analysis (editorial reading of the data)
    @ViewBuilder
    private func analysisSection(_ exercise: Exercise) -> some View {
        let sessions = exercise.sortedSessions
        if sessions.count >= 2 {
            let bw = exercise.isBodyweight

            let bestSet: WorkoutSet? = bw
                ? sessions.flatMap(\.sets).max(by: { $0.reps < $1.reps })
                : sessions.flatMap(\.sets).max(by: { Self.setScore($0) < Self.setScore($1) })

            let dates = sessions.map(\.date).sorted()
            let intervals: [Double] = (1..<dates.count).map {
                dates[$0].timeIntervalSince(dates[$0 - 1]) / 86_400
            }
            let cadenceDays = intervals.isEmpty ? 0 : intervals.reduce(0, +) / Double(intervals.count)

            let last = sessions.last!
            let prev = sessions.dropLast().last ?? last
            let lastV = bw
                ? Double(last.sets.map(\.reps).max() ?? 0)
                : last.maxWeight
            let prevV = bw
                ? Double(prev.sets.map(\.reps).max() ?? 0)
                : prev.maxWeight
            let gain = lastV - prevV

            let daysSinceLast = max(
                0,
                Int(((-last.date.timeIntervalSinceNow) / 86_400).rounded(.down))
            )

            VStack(spacing: 0) {
                HStack {
                    RunningHead(text: "Lecture", color: Ink.paperDim)
                    Spacer()
                    RunningHead(text: "Analyse", color: Ink.paperMute, size: 9)
                }
                .padding(.horizontal, 20)
                .padding(.top, 26)
                .padding(.bottom, 12)

                Hairline()

                HStack(spacing: 0) {
                    analysisCard(
                        label: "Meilleure série",
                        value: bestSetValue(bestSet, bw: bw),
                        unit: bw ? "reps" : nil,
                        sub: bestSetSub(bestSet, bw: bw),
                        valueColor: Ink.paper
                    )
                    VHairline().padding(.vertical, 18)
                    analysisCard(
                        label: "Cadence",
                        value: cadenceDays > 0 ? "\(Int(cadenceDays.rounded()))" : "—",
                        unit: cadenceDays > 0 ? "j" : nil,
                        sub: "entre séances",
                        valueColor: Ink.paper
                    )
                }

                Hairline()

                HStack(spacing: 0) {
                    analysisCard(
                        label: "Dernier gain",
                        value: gainValue(gain, bw: bw),
                        unit: gainUnit(gain, bw: bw),
                        sub: "vs précédent",
                        valueColor: gain > 0 ? Ink.ember : (gain < 0 ? Ink.paperDim : Ink.paperMute)
                    )
                    VHairline().padding(.vertical, 18)
                    analysisCard(
                        label: "Jours off",
                        value: "\(daysSinceLast)",
                        unit: "j",
                        sub: daysSinceLastSub(daysSinceLast),
                        valueColor: daysSinceLast >= 14 ? Ink.ember : Ink.paper
                    )
                }

                Hairline()
            }
        }
    }

    private static func setScore(_ s: WorkoutSet) -> Double {
        s.reps == 1 ? s.weight : s.weight * (1 + Double(s.reps) / 30.0)
    }

    private func bestSetValue(_ set: WorkoutSet?, bw: Bool) -> String {
        guard let s = set else { return "—" }
        if bw { return "\(s.reps)" }
        return "\(s.reps)×\(Fmt.kg(s.weight))"
    }

    private func bestSetSub(_ set: WorkoutSet?, bw: Bool) -> String {
        guard let s = set else { return "—" }
        if bw { return "reps consécutives" }
        return "1RM est. \(Fmt.kg(Self.setScore(s))) kg"
    }

    private func gainValue(_ gain: Double, bw: Bool) -> String {
        if gain == 0 { return "0" }
        let sign = gain > 0 ? "+" : "−"
        let mag = abs(gain)
        if bw { return "\(sign)\(Int(mag))" }
        return "\(sign)\(Fmt.kg(mag))"
    }

    private func gainUnit(_ gain: Double, bw: Bool) -> String? {
        if gain == 0 { return nil }
        return bw ? "reps" : "kg"
    }

    private func daysSinceLastSub(_ days: Int) -> String {
        switch days {
        case 0: return "aujourd'hui"
        case 1: return "hier"
        case 2...6: return "cette semaine"
        case 7...13: return "semaine dernière"
        default: return "depuis dernière séance"
        }
    }

    private func analysisCard(
        label: String,
        value: String,
        unit: String?,
        sub: String,
        valueColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RunningHead(text: label, color: Ink.paperDim)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                if let unit {
                    Text(unit)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Ink.paperDim)
                        .baselineOffset(2)
                }
            }
            Text(sub.uppercased())
                .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Ink.paperMute)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
    }

    // MARK: - History
    @ViewBuilder
    private func historySection(_ exercise: Exercise) -> some View {
        let sessions = Array(exercise.sortedSessions.reversed())
        VStack(spacing: 0) {
            HStack {
                RunningHead(text: "Carnet", color: Ink.paperDim)
                Spacer()
                RunningHead(text: "\(sessions.count) entrées", color: Ink.paperMute)
            }
            .padding(.horizontal, 20)
            .padding(.top, 26)
            .padding(.bottom, 12)

            Hairline()

            ForEach(Array(sessions.enumerated()), id: \.element.id) { idx, session in
                Button {
                    sessionToEdit = session
                } label: {
                    SessionRow(session: session, index: sessions.count - idx, isBodyweight: exercise.isBodyweight)
                }
                .buttonStyle(.plain)
                Hairline()
            }
        }
    }

    // MARK: - Helpers
    func metricValue(_ session: SessionEntry, for metric: ChartMetric) -> Double {
        switch metric {
        case .maxWeight: return session.maxWeight
        case .estimated1RM: return session.estimated1RM
        case .avgLoad:
            let weights = session.sets.map(\.weight).filter { $0 > 0 }
            guard !weights.isEmpty else { return 0 }
            return weights.reduce(0, +) / Double(weights.count)
        case .volume: return session.totalVolume
        case .totalReps: return Double(session.totalReps)
        case .maxRepsInSet: return Double(session.sets.map(\.reps).max() ?? 0)
        }
    }
}

// MARK: - Session row
struct SessionRow: View {
    let session: SessionEntry
    let index: Int
    var isBodyweight: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(String(format: "№%02d", index))
                .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(Ink.paperMute)
                .frame(width: 32, alignment: .leading)

            VStack(alignment: .leading, spacing: 7) {
                Text(Fmt.dateline(session.date))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Ink.paper)

                // Sets rendered inline, slash-separated like a stat-line
                Text(session.sets.map { setNotation($0) }.joined(separator: "  /  "))
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(Ink.paperDim)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            if isBodyweight {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(session.totalReps)")
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .foregroundStyle(Ink.paper)
                    Text("rps")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Ink.paperMute)
                        .baselineOffset(2)
                }
            } else if session.maxWeight > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(Fmt.kg(session.maxWeight))
                        .font(.system(size: 24, weight: .regular, design: .serif))
                        .foregroundStyle(Ink.paper)
                    Text("kg")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Ink.paperMute)
                        .baselineOffset(2)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .background(Ink.bg)
    }

    private func setNotation(_ s: WorkoutSet) -> String {
        if s.weight == 0 {
            return "\(s.reps)"
        }
        let w = s.weight == s.weight.rounded() ? "\(Int(s.weight))" : String(format: "%.1f", s.weight)
        return "\(s.reps)·\(w)"
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exerciseId: UUID())
            .environmentObject(WorkoutStore())
    }
    .preferredColorScheme(.dark)
}
