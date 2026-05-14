import Foundation

enum ArtifactKind {
    case palette
    case photos
    case ui
    case web
}

struct PaletteSwatch: Codable, Hashable {
    let name: String
    let hex: String
}

struct PaletteOptionPayload: Codable, Hashable {
    let id: String
    let swatches: [PaletteSwatch]
}

enum PhotoSource: String, Codable, Hashable {
    case pexels
    case unsplash
    case pinterest
    case arena
    case google
    case mixed
}

enum PhotoDisplayMode: String, Codable, Hashable {
    case image
    case moodboard
}

struct PhotoItemPayload: Codable, Hashable {
    let id: String
    let imageUrl: String
    let thumbUrl: String
    let bundleImageName: String?
    /// Longest edge in pixels for on-device assets; used to prefer sharp slots. Omitted in JSON when absent.
    let maxPixelDimension: Int?
    let alt: String
    let source: PhotoSource
    let author: String
    let detailUrl: String

    enum CodingKeys: String, CodingKey {
        case id, imageUrl, thumbUrl, bundleImageName, maxPixelDimension, alt, source, author, detailUrl
    }

    init(
        id: String,
        imageUrl: String,
        thumbUrl: String,
        bundleImageName: String?,
        maxPixelDimension: Int? = nil,
        alt: String,
        source: PhotoSource,
        author: String,
        detailUrl: String
    ) {
        self.id = id
        self.imageUrl = imageUrl
        self.thumbUrl = thumbUrl
        self.bundleImageName = bundleImageName
        self.maxPixelDimension = maxPixelDimension
        self.alt = alt
        self.source = source
        self.author = author
        self.detailUrl = detailUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        imageUrl = try c.decode(String.self, forKey: .imageUrl)
        thumbUrl = try c.decode(String.self, forKey: .thumbUrl)
        bundleImageName = try c.decodeIfPresent(String.self, forKey: .bundleImageName)
        maxPixelDimension = try c.decodeIfPresent(Int.self, forKey: .maxPixelDimension)
        alt = try c.decode(String.self, forKey: .alt)
        source = try c.decode(PhotoSource.self, forKey: .source)
        author = try c.decode(String.self, forKey: .author)
        detailUrl = try c.decode(String.self, forKey: .detailUrl)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(imageUrl, forKey: .imageUrl)
        try c.encode(thumbUrl, forKey: .thumbUrl)
        try c.encodeIfPresent(bundleImageName, forKey: .bundleImageName)
        try c.encodeIfPresent(maxPixelDimension, forKey: .maxPixelDimension)
        try c.encode(alt, forKey: .alt)
        try c.encode(source, forKey: .source)
        try c.encode(author, forKey: .author)
        try c.encode(detailUrl, forKey: .detailUrl)
    }
}

struct PhotoOptionPayload: Codable, Hashable {
    let id: String
    let displayMode: PhotoDisplayMode
    let source: PhotoSource
    let direction: String?
    let photos: [PhotoItemPayload]
    let swatches: [PaletteSwatch]?
}

enum UIDirection: String, Codable, Hashable {
    case editorial
    case minimal
    case bold
}

enum UIFeatureKind: String, Codable, Hashable {
    case toggles
    case buttons
    case picker
    case cards
}

struct UIOptionPayload: Codable, Hashable {
    let id: String
    let direction: UIDirection
    let label: String
    let productName: String
    let headline: String
    let supportingText: String
    let primaryCta: String
    let secondaryCta: String
    let accent: String
    let background: String
    let surface: String
    let mutedSurface: String
    let text: String
    let mutedText: String
    let featureKind: UIFeatureKind
    let featureTitle: String
    let featureItems: [String]
}

enum ArtifactPayload {
    case palette([PaletteOptionPayload])
    case photos([PhotoOptionPayload])
    case ui([UIOptionPayload])
    case web(String)

    var kind: ArtifactKind {
        switch self {
        case .palette:
            return .palette
        case .photos:
            return .photos
        case .ui:
            return .ui
        case .web:
            return .web
        }
    }
}

private struct EmbeddedPalettePayload: Codable {
    let kind: String
    let options: [PaletteOptionPayload]
}

private struct EmbeddedPhotoPayload: Codable {
    let kind: String
    let options: [PhotoOptionPayload]
}

private struct EmbeddedUIPayload: Codable {
    let kind: String
    let options: [UIOptionPayload]
}

enum ArtifactPayloadParser {
    static func parse(html: String) -> ArtifactPayload {
        if let paletteOptions = parsePaletteOptions(html: html), !paletteOptions.isEmpty {
            return .palette(paletteOptions)
        }

        if let photoOptions = parsePhotoOptions(html: html), !photoOptions.isEmpty {
            return .photos(photoOptions)
        }

        if let uiOptions = parseUIOptions(html: html), !uiOptions.isEmpty {
            return .ui(uiOptions)
        }

        return .web(html)
    }

    private static func parsePaletteOptions(html: String) -> [PaletteOptionPayload]? {
        guard let data = scriptJSON(
            html: html,
            scriptID: "draft-palette-options"
        ) else { return nil }

        guard let payload = try? JSONDecoder().decode(EmbeddedPalettePayload.self, from: data),
              payload.kind == "palette-options" else {
            return nil
        }

        return payload.options.filter { !$0.swatches.isEmpty }
    }

    private static func parsePhotoOptions(html: String) -> [PhotoOptionPayload]? {
        guard let data = scriptJSON(
            html: html,
            scriptID: "draft-photo-options"
        ) else { return nil }

        guard let payload = try? JSONDecoder().decode(EmbeddedPhotoPayload.self, from: data),
              payload.kind == "photo-options" else {
            return nil
        }

        return payload.options.filter { !$0.photos.isEmpty }
    }

    private static func parseUIOptions(html: String) -> [UIOptionPayload]? {
        guard let data = scriptJSON(
            html: html,
            scriptID: "draft-ui-options"
        ) else { return nil }

        guard let payload = try? JSONDecoder().decode(EmbeddedUIPayload.self, from: data),
              payload.kind == "ui-options" else {
            return nil
        }

        return payload.options
    }

    static func scriptJSON(html: String, scriptID: String) -> Data? {
        let escapedID = NSRegularExpression.escapedPattern(for: scriptID)
        let pattern = #"<script id=\""# + escapedID + #"\" type=\"application/json\">([\s\S]*?)</script>"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let fullRange = NSRange(location: 0, length: html.utf16.count)
        guard let match = regex.firstMatch(in: html, range: fullRange),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }

        return html[range].data(using: .utf8)
    }

    /// Pretty-printed JSON from the first embedded draft payload script, when present.
    static func primaryEmbeddedJSONString(html: String) -> String? {
        let scriptIDs = ["draft-palette-options", "draft-photo-options", "draft-ui-options"]
        for scriptID in scriptIDs {
            guard let data = scriptJSON(html: html, scriptID: scriptID) else { continue }
            if let obj = try? JSONSerialization.jsonObject(with: data, options: []),
               let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys, .prettyPrinted]) {
                return String(data: pretty, encoding: .utf8)
            }
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}

// MARK: - Persist generated artifact as a library board

enum GeneratedDraftLibraryImport {
    /// Builds a user-saved board appended at the end of the library list. Returns `nil` if nothing could be stored.
    static func makeBoard(prompt: String, html: String, directionIndex: Int) -> LibraryBoard? {
        let payload = ArtifactPayloadParser.parse(html: html)
        let runId = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12).lowercased()
        let title = boardTitle(from: prompt)
        let genID = "gen-user-saved"

        switch payload {
        case .photos(let options):
            guard options.indices.contains(directionIndex) else { return nil }
            let photos = options[directionIndex].photos
            guard !photos.isEmpty else { return nil }
            let items = photos.enumerated().map { idx, photo in
                libraryItem(from: photo, runId: String(runId), index: idx, generationID: genID)
            }
            return LibraryBoard(
                id: "user-saved-\(runId)",
                promptTitle: title,
                itemCount: items.count,
                updatedAtLabel: "Just now",
                generationID: genID,
                items: items
            )

        case .palette(let options):
            guard options.indices.contains(directionIndex) else { return nil }
            let swatches = options[directionIndex].swatches
            guard !swatches.isEmpty else { return nil }
            let items: [LibraryItem] = swatches.enumerated().map { idx, sw in
                let hx = hexUInt(sw.hex)
                return LibraryItem(
                    id: "saved-\(runId)-pal-\(idx)",
                    kind: .palette,
                    label: sw.name,
                    previewColorHex: hx,
                    secondaryColorHex: hx ^ 0x1A1A1A,
                    generationID: genID,
                    alt: "\(sw.name) \(sw.hex)"
                )
            }
            return LibraryBoard(
                id: "user-saved-\(runId)",
                promptTitle: title,
                itemCount: items.count,
                updatedAtLabel: "Just now",
                generationID: genID,
                items: items
            )

        case .ui(let options):
            guard options.indices.contains(directionIndex) else { return nil }
            let ui = options[directionIndex]
            let p = hexUInt(ui.accent)
            let s = hexUInt(ui.background)
            let items = [
                LibraryItem(
                    id: "saved-\(runId)-ui",
                    kind: .palette,
                    label: ui.productName,
                    previewColorHex: p,
                    secondaryColorHex: s,
                    generationID: genID,
                    alt: ui.headline
                ),
            ]
            return LibraryBoard(
                id: "user-saved-\(runId)",
                promptTitle: title,
                itemCount: 1,
                updatedAtLabel: "Just now",
                generationID: genID,
                items: items
            )

        case .web:
            return nil
        }
    }

    private static func boardTitle(from prompt: String) -> String {
        let t = prompt
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "Saved draft" }
        if t.count <= 56 { return t }
        return String(t.prefix(53)) + "…"
    }

    private static func libraryItem(from photo: PhotoItemPayload, runId: String, index: Int, generationID: String) -> LibraryItem {
        let id = "saved-\(runId)-img-\(index)-\(photo.id)"
        let (preview, secondary) = previewHexPair(from: photo.imageUrl)
        return LibraryItem(
            id: id,
            kind: .image,
            label: photo.alt,
            previewColorHex: preview,
            secondaryColorHex: secondary,
            generationID: generationID,
            imageURL: photo.imageUrl,
            thumbnailURL: photo.thumbUrl,
            bundleImageName: photo.bundleImageName,
            alt: photo.alt,
            source: librarySource(from: photo.source),
            author: photo.author
        )
    }

    private static func librarySource(from source: PhotoSource) -> LibrarySource? {
        switch source {
        case .pexels: return .pexels
        case .unsplash: return .unsplash
        case .pinterest: return .pinterest
        case .arena: return .arena
        case .google: return .google
        case .mixed: return nil
        }
    }

    private static func hexUInt(_ hex: String) -> UInt {
        var c = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "").uppercased()
        if c.count == 3 {
            c = c.map { chr in String(repeating: chr, count: 2) }.joined()
        }
        guard c.count == 6, let v = UInt32(c, radix: 16) else { return 0x5C4A38 }
        return UInt(v)
    }

    private static func previewHexPair(from string: String) -> (UInt, UInt) {
        var h = 5381
        for u in string.utf8 {
            h = ((h << 5) &+ h) &+ Int(u)
        }
        let a = UInt((h & 0xFFFFFF) | 0x303030)
        let b = UInt(((h >> 12) & 0xFFFFFF) | 0x202020)
        return (a, b)
    }
}
