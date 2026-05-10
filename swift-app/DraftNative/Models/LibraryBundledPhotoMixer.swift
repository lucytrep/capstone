import Foundation
import UIKit

/// Surfaces on-device images from `LibrarySeedData` when the user's prompt matches
/// bundle asset names, labels, alts, or board titles — then merges with API results.
enum LibraryBundledPhotoMixer {

    private struct CatalogEntry {
        let itemID: String
        let bundleImageName: String
        let label: String
        let alt: String
        let boardPromptTitle: String
        let author: String?
        let source: LibrarySource?
    }

    private static let catalog: [CatalogEntry] = LibrarySeedData.boards.flatMap { board in
        board.items.compactMap { item -> CatalogEntry? in
            guard item.kind == .image, let name = item.bundleImageName, !name.isEmpty else { return nil }
            return CatalogEntry(
                itemID: item.id,
                bundleImageName: name,
                label: item.label,
                alt: item.alt ?? "",
                boardPromptTitle: board.promptTitle,
                author: item.author,
                source: item.source
            )
        }
    }

    private static let stopwords: Set<String> = [
        "the", "and", "for", "with", "that", "this", "from", "into", "your", "have", "are", "was", "were",
        "been", "being", "give", "show", "make", "some", "any", "want", "need", "please", "help", "find",
        "just", "like", "also", "more", "get", "use", "using", "try", "our", "you", "can", "how", "what",
        "when", "who", "them", "they", "its", "it's", "but", "not", "all", "each", "has", "had", "did",
        "does", "doing", "about", "into", "than", "then", "too", "very", "here", "there", "where", "which"
    ]

    /// Keywords from the prompt used to match bundled assets (file names use `_`, `-`, and words).
    static func photoPayloadsMatchingPrompt(_ prompt: String, limit: Int = 18) -> [PhotoItemPayload] {
        let terms = retrievalTerms(from: prompt)
        guard !terms.isEmpty else { return [] }

        var scored: [(score: Int, payload: PhotoItemPayload)] = []
        scored.reserveCapacity(catalog.count)

        for entry in catalog {
            let haystack = searchHaystack(for: entry)
            var matchedTermCount = 0
            var score = 0
            for term in terms {
                let fragments = expandedFragments(for: term)
                if fragments.contains(where: { haystack.contains($0) }) {
                    matchedTermCount += 1
                    score += 12 + min(term.count, 12)
                }
            }
            guard matchedTermCount > 0 else { continue }
            score += matchedTermCount * 6
            let payload = photoPayload(from: entry)
            scored.append((score, payload))
        }

        scored.sort {
            if $0.score != $1.score { return $0.score > $1.score }
            let da = $0.payload.maxPixelDimension ?? 0
            let db = $1.payload.maxPixelDimension ?? 0
            if da != db { return da > db }
            return $0.payload.id < $1.payload.id
        }

        var seenBundles = Set<String>()
        var result: [PhotoItemPayload] = []
        for row in scored {
            guard let name = row.payload.bundleImageName, seenBundles.insert(name).inserted else { continue }
            result.append(row.payload)
            if result.count >= limit { break }
        }
        return result
    }

    private static func searchHaystack(for entry: CatalogEntry) -> String {
        [
            entry.bundleImageName,
            entry.label,
            entry.alt,
            entry.boardPromptTitle,
            entry.author ?? ""
        ]
            .joined(separator: " ")
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }

    private static func retrievalTerms(from prompt: String) -> [String] {
        let raw = prompt
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9\s]"#, with: " ", options: .regularExpression)
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .filter { $0.count > 2 && !stopwords.contains($0) }
        var seen = Set<String>()
        return raw.filter { seen.insert($0).inserted }
    }

    /// Maps spoken words to substrings that appear in asset names (e.g. `imagery` → `image`).
    private static func expandedFragments(for term: String) -> [String] {
        let t = term.lowercased()
        switch t {
        case "imagery", "imageries":
            return [t, "imagery", "image", "images"]
        case "image", "images":
            return [t, "image", "images"]
        case "photo", "photos", "photography", "photograph":
            return [t, "photo", "image", "images"]
        case "reference", "references":
            return [t, "reference", "ref", "pinterest"]
        case "moodboard", "moodboards":
            return [t, "moodboard", "mood", "board"]
        case "editorial", "editorials":
            return [t, "editorial", "edit"]
        default:
            return [t]
        }
    }

    private static func photoPayload(from entry: CatalogEntry) -> PhotoItemPayload {
        PhotoItemPayload(
            id: "local-catalog-\(entry.itemID)",
            imageUrl: "",
            thumbUrl: "",
            bundleImageName: entry.bundleImageName,
            maxPixelDimension: maxPixelDimensionForAsset(named: entry.bundleImageName),
            alt: entry.alt.isEmpty ? entry.label : entry.alt,
            source: photoSource(from: entry.source),
            author: entry.author ?? entry.boardPromptTitle,
            detailUrl: ""
        )
    }

    /// Longest edge in pixels for an asset catalog image (basis for layout / ranking).
    static func maxPixelDimensionForAsset(named bundleName: String) -> Int? {
        guard let image = UIImage(named: bundleName),
              let cg = image.cgImage else {
            return nil
        }
        return max(cg.width, cg.height)
    }

    private static func photoSource(from source: LibrarySource?) -> PhotoSource {
        switch source {
        case .pexels: return .pexels
        case .unsplash: return .unsplash
        case .pinterest: return .pinterest
        case .arena: return .arena
        case .google: return .google
        case nil: return .mixed
        }
    }
}
