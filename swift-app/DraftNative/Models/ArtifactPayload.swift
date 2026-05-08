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
    let alt: String
    let source: PhotoSource
    let author: String
    let detailUrl: String
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

    private static func scriptJSON(html: String, scriptID: String) -> Data? {
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
}
