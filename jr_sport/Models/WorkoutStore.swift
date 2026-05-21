import Combine
import Foundation

final class WorkoutStore: ObservableObject {
    @Published var exercises: [Exercise] = []

    private let saveKey = "jr_sport_exercises"
    private let seedVersionKey = "jr_sport_seed_version"
    private let currentSeedVersion = 5

    private static let seedFileName = "Muscu2026 - Feuille 1-2"
    private static let seedFileExtension = "csv"
    private static let supportedSeedEncodings: [String.Encoding] = [.utf8, .unicode, .isoLatin1]
    private static let exerciseDefinitions: [String: SeedExerciseDefinition] = [
        "dc": SeedExerciseDefinition(name: "Développé Couché", category: .chest),
        "developpecouche": SeedExerciseDefinition(name: "Développé Couché", category: .chest),
        "tiragevertical": SeedExerciseDefinition(name: "Tirage Vertical", category: .back),
        "tiragemachinevertical": SeedExerciseDefinition(name: "Tirage Machine Vertical", category: .back),
        "tiragehorizontal": SeedExerciseDefinition(name: "Tirage Horizontal", category: .back),
        "shoulderpress": SeedExerciseDefinition(name: "Shoulder Press", category: .shoulders),
        "machinecurl": SeedExerciseDefinition(name: "Machine Curl", category: .arms),
        "elevlateral": SeedExerciseDefinition(name: "Élévations Latérales", category: .shoulders),
        "elevationslaterales": SeedExerciseDefinition(name: "Élévations Latérales", category: .shoulders),
        "machinepecs": SeedExerciseDefinition(name: "Machine Pecs", category: .chest),
        "pecfly": SeedExerciseDefinition(name: "Pec Fly", category: .chest),
        "barrebiceps": SeedExerciseDefinition(name: "Barre Biceps", category: .arms),
        "dcguide": SeedExerciseDefinition(name: "DC Guidé", category: .chest),
        "dlatpulldown": SeedExerciseDefinition(name: "Lat Pulldown", category: .back),
        "latpulldown": SeedExerciseDefinition(name: "Lat Pulldown", category: .back),
        "legpress": SeedExerciseDefinition(name: "Leg Press", category: .legs),
        "legextension": SeedExerciseDefinition(name: "Leg Extension", category: .legs),
        "hacksquat": SeedExerciseDefinition(name: "Hack Squat", category: .legs),
        "tractionassistee": SeedExerciseDefinition(name: "Traction Assistée", category: .back),
        "traction": SeedExerciseDefinition(name: "Traction", category: .back, isBodyweight: true),
        "convergingchestpress": SeedExerciseDefinition(name: "Converging Chest Press", category: .chest),
        "exttriceps": SeedExerciseDefinition(name: "Extension Triceps", category: .arms),
        "extensiontriceps": SeedExerciseDefinition(name: "Extension Triceps", category: .arms),
        "seatedrow": SeedExerciseDefinition(name: "Seated Row", category: .back),
        "avantbraspoulie": SeedExerciseDefinition(name: "Avant-bras Poulie", category: .arms),
        "tirhorizlarge": SeedExerciseDefinition(name: "Tirage Horizontal Large", category: .back),
        "tiragehorizontallarge": SeedExerciseDefinition(name: "Tirage Horizontal Large", category: .back)
    ]

    init() {
        loadFromDisk()

        let savedVersion = UserDefaults.standard.integer(forKey: seedVersionKey)
        if savedVersion < currentSeedVersion {
            if seedFromCSV() {
                UserDefaults.standard.set(currentSeedVersion, forKey: seedVersionKey)
                save()
            }
        } else if exercises.isEmpty, seedFromCSV() {
            UserDefaults.standard.set(currentSeedVersion, forKey: seedVersionKey)
            save()
        }
    }

    // MARK: - Persistence

    func save() {
        if let data = try? JSONEncoder().encode(exercises) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Exercise].self, from: data) {
            exercises = decoded
        }
    }

    // MARK: - Actions

    func addSession(to exerciseId: UUID, session: SessionEntry) {
        if let idx = exercises.firstIndex(where: { $0.id == exerciseId }) {
            exercises[idx].sessions.append(session)
            exercises[idx].sessions.sort { $0.date < $1.date }
            save()
        }
    }

    func updateSession(in exerciseId: UUID, session: SessionEntry) {
        if let exIdx = exercises.firstIndex(where: { $0.id == exerciseId }),
           let sIdx = exercises[exIdx].sessions.firstIndex(where: { $0.id == session.id }) {
            exercises[exIdx].sessions[sIdx] = session
            exercises[exIdx].sessions.sort { $0.date < $1.date }
            save()
        }
    }

    func deleteSession(from exerciseId: UUID, at offsets: IndexSet) {
        if let idx = exercises.firstIndex(where: { $0.id == exerciseId }) {
            let sorted = exercises[idx].sortedSessions
            let idsToDelete = offsets.map { sorted[$0].id }
            exercises[idx].sessions.removeAll { idsToDelete.contains($0.id) }
            save()
        }
    }

    func addExercise(name: String, category: ExerciseCategory, isBodyweight: Bool = false) {
        let exercise = Exercise(name: name, category: category, sessions: [], isBodyweight: isBodyweight)
        exercises.append(exercise)
        save()
    }

    func deleteExercise(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Seed from CSV data

    @discardableResult
    func seedFromCSV() -> Bool {
        let seededExercises = Self.loadExercisesFromSeedCSV()
        guard !seededExercises.isEmpty else { return false }
        exercises = seededExercises
        return true
    }

    static func parseSets(from input: String) -> [WorkoutSet] {
        parseSets(from: input, isBodyweight: false)
    }

    func parseSets(from input: String) -> [WorkoutSet] {
        Self.parseSets(from: input)
    }

    private static func parseSets(from input: String, isBodyweight: Bool) -> [WorkoutSet] {
        let normalized = normalizeSetInput(input)
        guard !normalized.isEmpty else { return [] }

        return normalized
            .split(whereSeparator: \.isWhitespace)
            .flatMap { token in
                parseToken(String(token), isBodyweight: isBodyweight)
            }
    }

    private static func normalizeSetInput(_ input: String) -> String {
        var normalized = input
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "->", with: " ")

        normalized = normalized.replacingOccurrences(
            of: #"(?i)(\d+(?:\.\d+)?)\s+(\d+)\s*reps?"#,
            with: "$2x$1",
            options: .regularExpression
        )
        normalized = normalized.replacingOccurrences(
            of: #"[^0-9xX.\s]"#,
            with: " ",
            options: .regularExpression
        )
        normalized = normalized.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )

        return normalized.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func parseToken(_ token: String, isBodyweight: Bool) -> [WorkoutSet] {
        let cleaned = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return [] }

        if cleaned.contains("x") {
            return parseCompoundToken(cleaned, isBodyweight: isBodyweight)
        }

        guard let value = parseNumber(cleaned) else { return [] }
        if isBodyweight, let reps = integerValue(from: value) {
            return [WorkoutSet(reps: reps, weight: 1)]
        }

        return [WorkoutSet(reps: 1, weight: value)]
    }

    private static func parseCompoundToken(_ token: String, isBodyweight: Bool) -> [WorkoutSet] {
        let components = token.split(separator: "x", omittingEmptySubsequences: true)
        guard components.count == 2,
              let first = parseNumber(String(components[0])),
              let second = parseNumber(String(components[1])) else {
            return []
        }

        let firstInt = integerValue(from: first)
        let secondInt = integerValue(from: second)

        if isBodyweight,
           let setCount = firstInt,
           let reps = secondInt,
           setCount > 1,
           reps > 1,
           setCount <= 10,
           reps <= 20 {
            return Array(repeating: WorkoutSet(reps: reps, weight: 1), count: setCount)
        }

        if shouldTreatAsRepsFirst(first: first, second: second), let reps = firstInt {
            return [WorkoutSet(reps: reps, weight: second)]
        }

        if let reps = secondInt {
            return [WorkoutSet(reps: reps, weight: first)]
        }

        if let reps = firstInt {
            return [WorkoutSet(reps: reps, weight: second)]
        }

        return []
    }

    private static func shouldTreatAsRepsFirst(first: Double, second: Double) -> Bool {
        if first <= 20, second > 20 {
            return true
        }

        if first > 20, second <= 20 {
            return false
        }

        return true
    }

    private static func parseNumber(_ rawValue: String) -> Double? {
        Double(rawValue.replacingOccurrences(of: ",", with: "."))
    }

    private static func integerValue(from value: Double) -> Int? {
        guard value.isFinite else { return nil }

        let rounded = value.rounded()
        guard abs(rounded - value) < 0.000_1, rounded > 0 else { return nil }
        return Int(rounded)
    }

    private static func loadExercisesFromSeedCSV(referenceDate: Date = Date()) -> [Exercise] {
        guard let csvURL = seedCSVURL(),
              let csvContent = loadSeedFile(from: csvURL) else {
            return []
        }

        let calendar = Calendar.current

        return csvContent
            .split(whereSeparator: \.isNewline)
            .compactMap { rawLine in
                let columns = parseCSVLine(String(rawLine))
                guard let rawName = columns.first else { return nil }

                let key = normalizedLookupKey(rawName)
                guard let definition = exerciseDefinitions[key] else { return nil }

                let sessionCells = Array(columns.dropFirst()).map(sanitizedSessionCell)
                guard let lastSessionIndex = sessionCells.lastIndex(where: { cell in
                    guard let cell else { return false }
                    return !cell.isEmpty
                }) else {
                    return nil
                }

                var sessions: [SessionEntry] = []
                for (index, rawCell) in sessionCells.enumerated() where index <= lastSessionIndex {
                    guard let rawCell,
                          !rawCell.isEmpty,
                          let date = calendar.date(byAdding: .weekOfYear, value: index - lastSessionIndex, to: referenceDate) else {
                        continue
                    }

                    let sets = parseSets(from: rawCell, isBodyweight: definition.isBodyweight)
                    guard !sets.isEmpty else { continue }
                    sessions.append(SessionEntry(date: date, sets: sets))
                }

                guard !sessions.isEmpty else { return nil }

                return Exercise(
                    name: definition.name,
                    category: definition.category,
                    sessions: sessions,
                    isBodyweight: definition.isBodyweight
                )
            }
    }

    private static func seedCSVURL() -> URL? {
        // Try bundle root first
        if let bundledURL = Bundle.main.url(forResource: seedFileName, withExtension: seedFileExtension) {
            return bundledURL
        }

        // Try inside "data" subdirectory (folder reference in bundle)
        if let bundledURL = Bundle.main.url(forResource: seedFileName, withExtension: seedFileExtension, subdirectory: "data") {
            return bundledURL
        }

        #if DEBUG
        let sourceURL = URL(fileURLWithPath: #filePath)
        let projectRoot = sourceURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let developmentURL = projectRoot
            .appendingPathComponent("data", isDirectory: true)
            .appendingPathComponent("\(seedFileName).\(seedFileExtension)")

        if FileManager.default.fileExists(atPath: developmentURL.path) {
            return developmentURL
        }
        #endif

        return nil
    }

    private static func loadSeedFile(from url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }

        for encoding in supportedSeedEncodings {
            if let content = String(data: data, encoding: encoding) {
                return content
            }
        }

        return nil
    }

    private static func parseCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var isInsideQuotes = false

        for character in line {
            switch character {
            case "\"":
                isInsideQuotes.toggle()
            case "," where !isInsideQuotes:
                values.append(currentValue)
                currentValue = ""
            default:
                currentValue.append(character)
            }
        }

        values.append(currentValue)
        return values
    }

    private static func sanitizedSessionCell(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func normalizedLookupKey(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "fr_FR"))
            .replacingOccurrences(of: #"[^a-z0-9]"#, with: "", options: .regularExpression)
    }
}

private struct SeedExerciseDefinition {
    let name: String
    let category: ExerciseCategory
    var isBodyweight: Bool = false
}
