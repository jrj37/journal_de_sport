import Foundation

// MARK: - Un set individuel (ex: "3x70" → 3 reps à 70kg)
struct WorkoutSet: Codable, Identifiable, Equatable {
    var id = UUID()
    var reps: Int
    var weight: Double

    var description: String {
        if weight == weight.rounded() {
            return "\(reps)x\(Int(weight))"
        }
        return "\(reps)x\(String(format: "%.1f", weight))"
    }

    var volume: Double {
        Double(reps) * weight
    }
}

// MARK: - Une séance pour un exercice donné (ex: "3x70 5x65 5x60")
struct SessionEntry: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var sets: [WorkoutSet]

    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }

    var maxWeight: Double {
        sets.map(\.weight).max() ?? 0
    }

    var totalReps: Int {
        sets.reduce(0) { $0 + $1.reps }
    }

    var totalSets: Int {
        sets.count
    }

    /// Estimation du 1RM (meilleur set, formule d'Epley)
    var estimated1RM: Double {
        sets.map { s in
            if s.reps == 1 { return s.weight }
            return s.weight * (1 + Double(s.reps) / 30.0)
        }.max() ?? 0
    }

    /// Résumé compact : "3x70 5x65 5x60"
    var summary: String {
        sets.map(\.description).joined(separator: " ")
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "fr_FR")
        return f.string(from: date)
    }
}

// MARK: - Un exercice avec son historique
struct Exercise: Codable, Identifiable {
    var id = UUID()
    var name: String
    var category: ExerciseCategory
    var sessions: [SessionEntry]
    var isBodyweight: Bool = false

    var sortedSessions: [SessionEntry] {
        sessions.sorted { $0.date < $1.date }
    }
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case chest = "Pectoraux"
    case back = "Dos"
    case shoulders = "Épaules"
    case arms = "Bras"
    case legs = "Jambes"
    case other = "Autre"

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.pull.up"
        case .shoulders: return "figure.boxing"
        case .arms: return "figure.curling"
        case .legs: return "figure.run"
        case .other: return "dumbbell.fill"
        }
    }
}
