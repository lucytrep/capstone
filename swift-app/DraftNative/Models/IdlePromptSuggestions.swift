import Foundation

/// Home-screen rotating lines derived from `LibrarySeedData` and phrased so `MockArtifactGenerator`
/// routes to palette, moodboard, or UI (bundled library / on-device imagery answers).
enum IdlePromptSuggestions {

    /// One line each; sorted stable order from seed boards, then a few generator-native phrases.
    /// Lines in `excluding` are omitted (already shown and used on the home screen).
    static func makeLines(excluding consumed: Set<String> = []) -> [String] {
        let built = buildLinesUnfiltered()
        let filtered = built.filter { !consumed.contains($0) }
        if filtered.isEmpty {
            return ["Color palette color story", "Editorial fashion moodboard", "Mobile app home screen UI"]
        }
        return filtered
    }

    private static func buildLinesUnfiltered() -> [String] {
        var lines: [String] = []
        lines.reserveCapacity(LibrarySeedData.boards.count + generatorAlignedExtras.count)
        var seen = Set<String>()

        for board in LibrarySeedData.boards {
            let line = routingHintLine(for: board)
            if seen.insert(line).inserted {
                lines.append(line)
            }
        }

        for extra in generatorAlignedExtras where seen.insert(extra).inserted {
            lines.append(extra)
        }

        if lines.isEmpty {
            return ["Color palette color story", "Editorial fashion moodboard", "Mobile app home screen UI"]
        }
        return lines
    }

    // MARK: - Private

    private static let generatorAlignedExtras: [String] = [
        "Calm pastel color story",
        "Neon nightlife dashboard UI",
        "Street style photo references",
    ]

    private static func routingHintLine(for board: LibraryBoard) -> String {
        let title = board.promptTitle
        switch board.subtitle {
        case "Color palette":
            return "\(title) color story"
        case "Interface studies":
            return "\(title) app interface"
        default:
            return "\(title) moodboard"
        }
    }
}
