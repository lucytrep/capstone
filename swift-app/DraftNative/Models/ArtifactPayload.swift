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
