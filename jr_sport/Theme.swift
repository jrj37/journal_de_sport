import SwiftUI

// MARK: - Palette
// Warm ink dark — like a sports almanac printed on cream paper, rendered in dark mode.
enum Ink {
    static let bg        = Color(red: 0.055, green: 0.047, blue: 0.039)   // #0E0C0A
    static let surface   = Color(red: 0.086, green: 0.075, blue: 0.059)   // #16130F
    static let paper     = Color(red: 0.949, green: 0.922, blue: 0.851)   // #F2EBD9
    static let paperDim  = Color(red: 0.604, green: 0.572, blue: 0.525)   // #9A9286
    static let paperMute = Color(red: 0.361, green: 0.337, blue: 0.302)   // #5C564D
    static let rule      = Color(red: 0.169, green: 0.149, blue: 0.125)   // #2B2620
    static let ember     = Color(red: 0.851, green: 0.278, blue: 0.169)   // #D9472B
    static let emberSoft = Color(red: 0.545, green: 0.184, blue: 0.110)   // #8B2F1C
}

// MARK: - Type ramp
extension Font {
    static let display       = Font.system(size: 72, weight: .regular, design: .serif)
    static let displayLarge  = Font.system(size: 52, weight: .regular, design: .serif)
    static let displayMed    = Font.system(size: 34, weight: .regular, design: .serif)
    static let headline2     = Font.system(size: 22, weight: .regular, design: .serif)
    static let serifBody     = Font.system(size: 17, weight: .regular, design: .serif)

    static let monoLabel     = Font.system(size: 10, weight: .medium, design: .monospaced)
    static let monoSmall     = Font.system(size: 11, weight: .regular, design: .monospaced)
    static let monoNumeric   = Font.system(size: 14, weight: .regular, design: .monospaced)
    static let monoBold      = Font.system(size: 11, weight: .semibold, design: .monospaced)
}

// MARK: - Small caps label, letter-spaced, like a magazine running head
struct RunningHead: View {
    let text: String
    var color: Color = Ink.paperDim
    var size: CGFloat = 10

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: size, weight: .medium, design: .monospaced))
            .tracking(2.2)
            .foregroundStyle(color)
    }
}

// MARK: - Hairline rule, 0.5pt — print-style separator
struct Hairline: View {
    var color: Color = Ink.rule
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 0.5)
    }
}

// MARK: - Vertical hairline divider
struct VHairline: View {
    var color: Color = Ink.rule
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 0.5)
    }
}

// MARK: - Format helpers
enum Fmt {
    static func kg(_ w: Double) -> String {
        w == w.rounded() ? "\(Int(w))" : String(format: "%.1f", w)
    }

    /// Date en français — "17 AVR · 2026"
    static func dateline(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "dd MMM"
        return f.string(from: d).uppercased() + " · " + String(Calendar.current.component(.year, from: d))
    }

    /// Tag court pour les filtres de catégorie
    static func category(_ c: ExerciseCategory) -> String {
        switch c {
        case .chest: return "PECS"
        case .back: return "DOS"
        case .shoulders: return "ÉPAULES"
        case .arms: return "BRAS"
        case .legs: return "JAMBES"
        case .other: return "AUTRE"
        }
    }
}

// MARK: - Background that sets the warm ink tone
struct InkBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Ink.bg.ignoresSafeArea())
            .tint(Ink.ember)
    }
}

extension View {
    func inkBackground() -> some View { modifier(InkBackground()) }
}
