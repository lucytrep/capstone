import Foundation

struct MockArtifactGenerator: ArtifactGenerating {
    private enum BoardType {
        case color
        case image
        case moodboard
        case ui
    }

    /// Tokens stripped before comparing alts for “same session” clustering.
    private enum ShootClustering {
        static let noiseTokens: Set<String> = [
            "woman", "women", "man", "men", "young", "adult", "person", "people", "female", "male",
            "girl", "girls", "boy", "boys", "teen", "teenager",
            "model", "models", "portrait", "portraits", "posing", "pose", "posed",
            "standing", "sitting", "walking", "running", "jumping", "looking", "camera", "smiling",
            "beautiful", "handsome", "attractive", "confident", "happy", "serious", "calm",
            "wearing", "wear", "dressed", "holding", "shows", "showing",
            "studio", "indoors", "indoor", "outdoors", "outdoor", "outside", "inside",
            "background", "backdrop", "blur", "bokeh",
            "photo", "photography", "photograph", "image", "picture", "shot",
            "closeup", "close", "angle", "angles", "view", "side", "front", "profile",
            "full", "body", "waist", "crop", "cropped", "headshot",
            "editorial", "commercial", "lifestyle",
            "light", "lighting", "natural", "daylight", "sunlight",
            "urban", "street", "city",
            "healthy", "fit", "fitness", "active", "sport", "sports", "athletic", "workout",
            "fashion", "stylish", "style", "trendy", "elegant", "casual", "formal",
            "hair", "face", "eyes",
            "color", "colour", "bright", "dark",
            "the", "and", "with", "from", "for", "her", "his", "their", "against", "into"
        ]
    }

    private struct APIKeys {
        let anthropic: String
        let pexels: String
        let unsplash: String
        let pinterestServiceURL: String
        let arenaToken: String
        let googleApiKey: String
        let googleSearchEngineId: String

        static func load() -> APIKeys {
            let env = loadEnvironment()

            return APIKeys(
                anthropic: env["EXPO_PUBLIC_ANTHROPIC_API_KEY"] ?? "",
                pexels: env["EXPO_PUBLIC_PEXELS_API_KEY"] ?? "",
                unsplash: env["EXPO_PUBLIC_UNSPLASH_ACCESS_KEY"] ?? "",
                pinterestServiceURL: env["EXPO_PUBLIC_PINTEREST_SERVICE_URL"] ?? "",
                arenaToken: env["EXPO_PUBLIC_ARENA_ACCESS_TOKEN"] ?? "",
                googleApiKey: env["EXPO_PUBLIC_GOOGLE_API_KEY"] ?? "",
                googleSearchEngineId: env["EXPO_PUBLIC_GOOGLE_SEARCH_ENGINE_ID"] ?? ""
            )
        }

        private static func loadEnvironment() -> [String: String] {
            let paths = [
                "/Users/lucytrepanier/Code/capstone/.env.local",
                "/Users/lucytrepanier/Code/capstone/.env"
            ]

            for path in paths {
                if let data = try? String(contentsOfFile: path, encoding: .utf8) {
                    return parseEnvironment(data)
                }
            }

            // On device: try LocalSecrets.plist (gitignored) first, then Info.plist
            let plistKeys = [
                "EXPO_PUBLIC_ANTHROPIC_API_KEY",
                "EXPO_PUBLIC_PEXELS_API_KEY",
                "EXPO_PUBLIC_UNSPLASH_ACCESS_KEY",
                "EXPO_PUBLIC_PINTEREST_SERVICE_URL",
                "EXPO_PUBLIC_ARENA_ACCESS_TOKEN",
                "EXPO_PUBLIC_GOOGLE_API_KEY",
                "EXPO_PUBLIC_GOOGLE_SEARCH_ENGINE_ID"
            ]
            var result: [String: String] = [:]

            // LocalSecrets.plist is gitignored and holds the real keys
            if let url = Bundle.main.url(forResource: "LocalSecrets", withExtension: "plist"),
               let localSecrets = NSDictionary(contentsOf: url) as? [String: String] {
                for key in plistKeys {
                    if let value = localSecrets[key], !value.isEmpty {
                        result[key] = value
                    }
                }
                if !result.isEmpty { return result }
            }

            for key in plistKeys {
                if let value = Bundle.main.infoDictionary?[key] as? String, !value.isEmpty {
                    result[key] = value
                }
            }
            return result
        }

        private static func parseEnvironment(_ raw: String) -> [String: String] {
            raw
                .split(separator: "\n")
                .reduce(into: [:]) { partialResult, line in
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return }

                    let parts = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
                    guard parts.count == 2 else { return }
                    partialResult[parts[0]] = parts[1]
                }
        }
    }

    private struct TheColorAPISchemeResponse: Decodable {
        struct Entry: Decodable {
            struct Name: Decodable { let value: String? }
            struct Hex: Decodable { let value: String? }

            let name: Name?
            let hex: Hex?
        }

        let colors: [Entry]?
    }

    private struct TheColorAPIIDResponse: Decodable {
        struct Name: Decodable { let value: String? }
        let name: Name?
    }

    private struct ColormindResponse: Decodable {
        let result: [[Double]]?
    }

    private struct PexelsResponse: Decodable {
        struct Photo: Decodable {
            struct Source: Decodable {
                let large2x: String?
                let large: String?
                let medium: String?
            }

            let id: Int?
            let alt: String?
            let url: String?
            let photographer: String?
            let src: Source?
        }

        let photos: [Photo]?
    }

    private struct UnsplashResponse: Decodable {
        struct Photo: Decodable {
            struct Links: Decodable { let html: String? }
            struct User: Decodable { let name: String? }
            struct URLs: Decodable {
                let raw: String?
                let full: String?
                let regular: String?
                let small: String?
            }

            let id: String?
            let alt_description: String?
            let description: String?
            let links: Links?
            let user: User?
            let urls: URLs?
        }

        let results: [Photo]?
    }

    private struct ArenaResponse: Decodable {
        struct Block: Decodable {
            struct ArenaImage: Decodable {
                struct ImageFile: Decodable { let url: String? }
                let original: ImageFile?
                let display: ImageFile?
                let thumb: ImageFile?
            }
            struct Source: Decodable { let url: String? }

            let id: Int?
            let title: String?
            let blockClass: String?
            let image: ArenaImage?
            let source: Source?

            enum CodingKeys: String, CodingKey {
                case id, title, image, source
                case blockClass = "class"
            }
        }

        let blocks: [Block]?
    }

    private struct GoogleSearchResponse: Decodable {
        struct Item: Decodable {
            struct ImageInfo: Decodable {
                let thumbnailLink: String?
                let contextLink: String?
            }
            let title: String?
            let link: String?
            let image: ImageInfo?
        }
        let items: [Item]?
    }

    private struct ClaudeResponse: Decodable {
        struct ContentBlock: Decodable {
            let type: String?
            let text: String?
        }

        let content: [ContentBlock]?
    }

    private let keys = APIKeys.load()
    private let claudeModel = "claude-sonnet-4-6"
    private let claudeEndpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let colorAPIBase = URL(string: "https://www.thecolorapi.com")!
    private let colormindURL = URL(string: "https://colormind.io/api/")!
    private let pexelsBase = URL(string: "https://api.pexels.com/v1")!
    private let unsplashBase = URL(string: "https://api.unsplash.com")!
    private let arenaBase = URL(string: "https://api.are.na/v2")!
    private let googleSearchBase = URL(string: "https://www.googleapis.com/customsearch/v1")!
    private let claudeSystemPrompt = """
    You are a design artifact generator. The user will describe a design idea. You must ALWAYS respond with only valid HTML and CSS - never text, never questions, never explanations. This app supports exactly 3 board types: UI boards, photo boards, and color boards. Always return a complete, beautiful, self-contained HTML document with embedded CSS. Never ask for clarification. Just build it. Start your response directly with <!DOCTYPE html> and nothing else.

    UI layout is not rendered from your HTML in this app; ignore UI-specific HTML instructions in the user message when they conflict with the above.
    """

    /// Used only for structured UI concept generation. The native app renders from JSON (`draft-ui-options`), same as palette and photo artifacts.
    private let claudeUIStructuredSystemPrompt = """
    You are a product design writer. You respond with exactly one JSON object and nothing else: no markdown, no code fences, no explanations, no HTML.
    The JSON must be valid UTF-8 and parseable by a strict JSON decoder.
    """

    private let paletteKeywords: [String: String] = [
        // Basic color names — must be present so user prompts like "yellow and orange" seed correctly
        "yellow":     "#F5C518",
        "orange":     "#F08D3A",
        "red":        "#E82050",
        "green":      "#40C880",
        "blue":       "#4080C0",
        "purple":     "#9B3FC7",
        "pink":       "#F46FA9",
        "gold":       "#D4A017",
        "brown":      "#A07850",
        "grey":       "#909090",
        "gray":       "#909090",
        "teal":       "#2A9D8F",
        "cyan":       "#00B4D8",
        "indigo":     "#4B5EAA",
        "violet":     "#8A56D4",
        "magenta":    "#E040C0",
        "peach":      "#FFAD85",
        "coral":      "#FF6B6B",
        "sage":       "#77A17E",
        "olive":      "#8A8A4E",
        "tan":        "#C49A6C",
        "beige":      "#F2E0C8",
        "cream":      "#FFFDD0",
        "maroon":     "#800020",
        "navy":       "#1A2F6B",
        "burgundy":   "#800020",
        "terracotta": "#E2725B",
        "rust":       "#B7410E",
        "mustard":    "#FFDB58",
        "amber":      "#FFBF00",
        "lime":       "#32CD32",
        "emerald":    "#50C878",
        "cobalt":     "#0047AB",
        "sky":        "#87CEEB",
        "slate":      "#708090",
        "charcoal":   "#36454F",
        "sand":       "#C2B280",
        "copper":     "#B87333",
        "bronze":     "#CD7F32",
        "silver":     "#C0C0C0",
        // Descriptive / mood keywords
        "easter":     "#C8A0E8",
        "spring":     "#90D4A8",
        "floral":     "#F0A0C0",
        "lavender":   "#C8A0E8",
        "lilac":      "#C8A0E8",
        "mint":       "#90E4B0",
        "blush":      "#F4B8CC",
        "pastel":     "#F0C0DC",
        "neon":       "#554EF7",
        "rose":       "#EC6478",
        "sunset":     "#F08D3A",
        "saffron":    "#FBEBB0",
        "sea":        "#7EC8A8",
        "forest":     "#68865E",
        "midnight":   "#141826",
        "editorial":  "#D98752",
        "warm":       "#E8A070",
        "cool":       "#7090E0",
        "earth":      "#A07850",
        "ocean":      "#4080C0",
        "desert":     "#D09050",
        "autumn":     "#D06030",
        "summer":     "#F0B040",
        "tropical":   "#40C880",
        "bold":       "#E82050",
        "neutral":    "#A09080",
        "monochrome": "#606060",
    ]

    func generateArtifact(from prompt: String) async throws -> GeneratedArtifact {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let boardType = resolveBoardType(trimmedPrompt)

        let html: String
        switch boardType {
        case .color:
            html = try await generateColorArtifact(prompt: trimmedPrompt)
        case .image:
            html = try await generateImageArtifact(prompt: trimmedPrompt)
        case .moodboard:
            html = try await generateMoodboardArtifact(prompt: trimmedPrompt)
        case .ui:
            html = try await generateUIArtifact(prompt: trimmedPrompt)
        }

        return GeneratedArtifact(html: html)
    }

    private func resolveBoardType(_ transcript: String) -> BoardType {
        if isMoodboardPrompt(transcript) {
            return .moodboard
        }

        if isPalettePrompt(transcript) {
            return .color
        }

        if isPhotoPrompt(transcript) {
            return .image
        }

        // If the prompt mentions color at all without strong UI signals, route to palette —
        // never show a UI template for a color request.
        if looksLikeColorRequest(transcript) {
            return .color
        }

        return .ui
    }

    // Catches "give me warm autumn colors", "yellow and orange", "calm palette", "monochrome direction", etc.
    private func looksLikeColorRequest(_ transcript: String) -> Bool {
        guard !isUiPrompt(transcript) else { return false }

        // Explicit color/colours word
        if contains(transcript, pattern: #"(?i)\bcolou?rs?\b"#) { return true }

        // Specific color name(s) mentioned
        if contains(
            transcript,
            pattern: #"(?i)\b(yellow|orange|red|green|blue|purple|pink|gold|brown|grey|gray|teal|cyan|indigo|violet|magenta|peach|coral|sage|olive|tan|beige|cream|maroon|navy|burgundy|terracotta|rust|mustard|amber|lime|emerald|cobalt|silver|copper|bronze|lavender|lilac|mint|blush|rose|saffron|ochre|scarlet|crimson|turquoise|aqua|ivory|champagne|taupe|caramel)\b"#
        ), !isPhotoPrompt(transcript) { return true }

        // Mood/descriptor terms that map clearly to palette from semantic_core.csv
        // e.g. "calm", "earthy but not depressing", "girly but mature", "futuristic neon", "monochrome"
        let paletteDescriptors = #"(?i)\b(calm|soothing|relaxing|peaceful|serene|moody|earthy|natural|grounded|organic|feminine|girly|futuristic neon|cyber|monochrome|grayscale|black and white|pastel|neon|vivid|saturated|vibrant|playful bright|fun colors?|colorful|warm tones?|cool tones?|dark lux|muted|high contrast|low saturation|retro|vintage palette)\b"#
        if contains(transcript, pattern: paletteDescriptors), !isPhotoPrompt(transcript) { return true }

        // Season/nature color contexts when not a photo request
        let seasonalColor = #"(?i)\b(autumn (tones?|palette|colors?)|fall (tones?|palette|colors?)|spring (palette|tones?|colors?)|sunset (palette|tones?|colors?)|ocean palette|coastal (palette|tones?))\b"#
        if contains(transcript, pattern: seasonalColor) { return true }

        return false
    }

    private func generateColorArtifact(prompt: String) async throws -> String {
        let seedHex = inferSeedHex(prompt)

        do {
            async let analogic = getTheColorScheme(seedHex: seedHex, mode: "analogic")
            async let quad = getTheColorScheme(seedHex: seedHex, mode: "quad")
            async let colormind = getColormindPalette(seedHex: seedHex)

            let analogicSwatches = try await analogic
            let quadSwatches = try await quad
            let colormindSwatches = try await colormind

            let options = [
                PaletteOptionPayload(id: "palette-1", swatches: withFixedPaletteBase(analogicSwatches)),
                PaletteOptionPayload(id: "palette-2", swatches: withFixedPaletteBase(quadSwatches)),
                PaletteOptionPayload(id: "palette-3", swatches: withFixedPaletteBase(colormindSwatches))
            ]

            return buildPaletteArtifactHTML(options: options)
        } catch {
            let fallback = buildLocalPaletteOptions(seedHex: seedHex)
            return buildPaletteArtifactHTML(options: fallback)
        }
    }

    private func generateImageArtifact(prompt: String) async throws -> String {
        try await generatePhotoArtifact(prompt: prompt, displayMode: .image)
    }

    private func generateMoodboardArtifact(prompt: String) async throws -> String {
        try await generatePhotoArtifact(prompt: prompt, displayMode: .moodboard)
    }

    private func generatePhotoArtifact(prompt: String, displayMode: PhotoDisplayMode) async throws -> String {
        if !hasImageProviders {
            return try await photoArtifactFallback(prompt: prompt, displayMode: displayMode)
        }

        let requestSeed = hashSeed(prompt + "::native")
        let query = buildSearchQuery(prompt)
        let promptBundled = LibraryBundledPhotoMixer.photoPayloadsMatchingPrompt(prompt, limit: 18)

        async let pexelsPhotos = fetchPexelsPhotos(query: query, seed: requestSeed + 11)
        async let unsplashPhotos = fetchUnsplashPhotos(query: query, seed: requestSeed + 17)
        async let pinterestPhotos = fetchPinterestPhotos(query: query)
        async let arenaPhotos = fetchArenaPhotos(query: query)
        async let googlePhotos = fetchGooglePhotos(query: query)

        let pexels = promptBundled + (((try? await pexelsPhotos) ?? []) + (await pinterestPhotos))
        let unsplash = (try? await unsplashPhotos) ?? []
        let arena = await arenaPhotos
        let google = await googlePhotos
        let moodboardSwatches = displayMode == .moodboard
            ? await buildMoodboardSwatchSets(prompt: prompt)
            : [[]]

        let options = buildPhotoOptions(
            pexels: pexels,
            unsplash: unsplash,
            arena: arena,
            google: google,
            displayMode: displayMode,
            seed: requestSeed,
            swatchSets: moodboardSwatches
        )

        guard options.count == 3, options.allSatisfy({ $0.photos.count >= 5 }) else {
            return try await photoArtifactFallback(prompt: prompt, displayMode: displayMode)
        }

        return buildPhotoArtifactHTML(options: options)
    }

    private func generateUIArtifact(prompt: String) async throws -> String {
        if !keys.anthropic.isEmpty,
           let options = try? await generateClaudeStructuredUIOptions(prompt: prompt) {
            return buildUIArtifactHTML(options: options)
        }

        return buildUIArtifactHTML(options: buildUIOptions(prompt: prompt))
    }

    private func getTheColorScheme(seedHex: String, mode: String) async throws -> [PaletteSwatch] {
        let hex = seedHex.replacingOccurrences(of: "#", with: "")
        let url = makeURL(base: colorAPIBase, path: "/scheme", queryItems: [
            URLQueryItem(name: "hex", value: hex),
            URLQueryItem(name: "mode", value: mode),
            URLQueryItem(name: "count", value: "6")
        ])

        let response: TheColorAPISchemeResponse = try await fetchJSON(url: url)
        return (response.colors ?? [])
            .compactMap { entry in
                guard let name = entry.name?.value?.trimmingCharacters(in: .whitespacesAndNewlines),
                      let hexValue = entry.hex?.value?.uppercased(),
                      isHex(hexValue) else { return nil }
                return PaletteSwatch(name: name, hex: hexValue)
            }
            .prefix(6)
            .map { $0 }
    }

    private func getTheColorName(hex: String) async throws -> String {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        let url = makeURL(base: colorAPIBase, path: "/id", queryItems: [
            URLQueryItem(name: "hex", value: cleaned)
        ])

        let response: TheColorAPIIDResponse = try await fetchJSON(url: url)
        return response.name?.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Color \(cleaned.uppercased())"
    }

    private func getColormindPalette(seedHex: String) async throws -> [PaletteSwatch] {
        let rgb = hexToRGB(seedHex)
        let body: [String: Any] = [
            "model": "default",
            "input": [
                [rgb.r, rgb.g, rgb.b],
                "N", "N", "N", "N"
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: body)
        let response: ColormindResponse = try await fetchJSON(
            url: colormindURL,
            method: "POST",
            headers: ["Content-Type": "application/json"],
            body: data
        )

        let colors = Array((response.result ?? []).prefix(5))
        if colors.count < 5 {
            throw ArtifactGenerationError.unavailableBackend
        }

        var swatches: [PaletteSwatch] = [PaletteSwatch(name: try await getTheColorName(hex: seedHex), hex: seedHex)]
        for (index, color) in colors.enumerated().dropFirst() {
            let hex = rgbToHex(
                Int(color[safe: 0] ?? 0),
                Int(color[safe: 1] ?? 0),
                Int(color[safe: 2] ?? 0)
            )
            let name = try await getTheColorName(hex: hex)
            swatches.append(PaletteSwatch(name: index == 0 ? "Anchor" : name, hex: hex))
        }

        if let accent = colors.first {
            swatches.append(
                PaletteSwatch(
                    name: "Accent",
                    hex: rgbToHex(
                        Int(accent[safe: 0] ?? 0),
                        Int(accent[safe: 1] ?? 0),
                        Int(accent[safe: 2] ?? 0)
                    )
                )
            )
        }

        return Array(swatches.prefix(6))
    }

    private func fetchPexelsPhotos(query: String, seed: Int) async throws -> [PhotoItemPayload] {
        guard !keys.pexels.isEmpty else { return [] }

        let page = (abs(seed) % 3) + 1
        let url = makeURL(base: pexelsBase, path: "/search", queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "24"),
            URLQueryItem(name: "orientation", value: "portrait"),
            URLQueryItem(name: "size", value: "large"),
            URLQueryItem(name: "page", value: "\(page)")
        ])

        let response: PexelsResponse = try await fetchJSON(url: url, headers: [
            "Authorization": keys.pexels
        ])

        return (response.photos ?? []).compactMap { photo in
            guard let id = photo.id else { return nil }
            let imageURL = photo.src?.large2x ?? photo.src?.large ?? photo.src?.medium
            let thumbURL = photo.src?.large2x ?? photo.src?.large ?? photo.src?.medium
            guard let imageURL, let thumbURL else { return nil }

            return PhotoItemPayload(
                id: "pexels-\(id)",
                imageUrl: imageURL,
                thumbUrl: thumbURL,
                bundleImageName: nil,
                alt: photo.alt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Pexels inspiration image",
                source: .pexels,
                author: photo.photographer?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Pexels",
                detailUrl: photo.url ?? ""
            )
        }
    }

    private func fetchUnsplashPhotos(query: String, seed: Int) async throws -> [PhotoItemPayload] {
        guard !keys.unsplash.isEmpty else { return [] }

        let page = (abs(seed) % 3) + 1
        let url = makeURL(base: unsplashBase, path: "/search/photos", queryItems: [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "24"),
            URLQueryItem(name: "orientation", value: "portrait"),
            URLQueryItem(name: "page", value: "\(page)")
        ])

        let response: UnsplashResponse = try await fetchJSON(url: url, headers: [
            "Authorization": "Client-ID \(keys.unsplash)",
            "Accept-Version": "v1"
        ])

        return (response.results ?? []).compactMap { photo in
            guard let id = photo.id else { return nil }
            let imageURL = unsplashDisplayURL(
                raw: photo.urls?.raw,
                full: photo.urls?.full,
                regular: photo.urls?.regular,
                small: photo.urls?.small
            )
            let thumbURL = photo.urls?.regular ?? photo.urls?.small
            guard let imageURL, let thumbURL else { return nil }

            return PhotoItemPayload(
                id: "unsplash-\(id)",
                imageUrl: imageURL,
                thumbUrl: thumbURL,
                bundleImageName: nil,
                alt: photo.alt_description?.trimmingCharacters(in: .whitespacesAndNewlines)
                    ?? photo.description?.trimmingCharacters(in: .whitespacesAndNewlines)
                    ?? "Unsplash inspiration image",
                source: .unsplash,
                author: photo.user?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unsplash",
                detailUrl: photo.links?.html ?? ""
            )
        }
    }

    private func fetchArenaPhotos(query: String) async -> [PhotoItemPayload] {
        guard !keys.arenaToken.isEmpty else { return [] }

        let url = makeURL(base: arenaBase, path: "/search/blocks", queryItems: [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "per_page", value: "10")
        ])

        guard let response: ArenaResponse = try? await fetchJSON(url: url, headers: [
            "Authorization": "Bearer \(keys.arenaToken)"
        ]) else { return [] }

        return (response.blocks ?? []).compactMap { block in
            guard block.blockClass == "Image" else { return nil }
            let imageURL = block.image?.original?.url ?? block.image?.display?.url
            let thumbURL = block.image?.thumb?.url ?? block.image?.display?.url
            guard let imageURL, let thumbURL, !imageURL.isEmpty else { return nil }
            let id = block.id.map { "arena-\($0)" } ?? "arena-\(UUID().uuidString)"
            return PhotoItemPayload(
                id: id,
                imageUrl: imageURL,
                thumbUrl: thumbURL,
                bundleImageName: nil,
                alt: block.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Are.na inspiration",
                source: .arena,
                author: "Are.na",
                detailUrl: block.source?.url ?? ""
            )
        }
    }

    private func fetchGooglePhotos(query: String) async -> [PhotoItemPayload] {
        guard !keys.googleApiKey.isEmpty, !keys.googleSearchEngineId.isEmpty else { return [] }

        let url = makeURL(base: googleSearchBase, path: "", queryItems: [
            URLQueryItem(name: "key", value: keys.googleApiKey),
            URLQueryItem(name: "cx", value: keys.googleSearchEngineId),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "searchType", value: "image"),
            URLQueryItem(name: "num", value: "10"),
            URLQueryItem(name: "imgType", value: "photo"),
            URLQueryItem(name: "safe", value: "active")
        ])

        guard let response: GoogleSearchResponse = try? await fetchJSON(url: url) else { return [] }

        return (response.items ?? []).enumerated().compactMap { index, item in
            guard let imageURL = item.link, !imageURL.isEmpty else { return nil }
            let thumbURL = item.image?.thumbnailLink ?? imageURL
            return PhotoItemPayload(
                id: "google-\(index)-\(hashSeed(imageURL))",
                imageUrl: imageURL,
                thumbUrl: thumbURL,
                bundleImageName: nil,
                alt: item.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Google inspiration",
                source: .google,
                author: "Google",
                detailUrl: item.image?.contextLink ?? ""
            )
        }
    }

    private func buildPhotoOptions(
        pexels: [PhotoItemPayload],
        unsplash: [PhotoItemPayload],
        arena: [PhotoItemPayload],
        google: [PhotoItemPayload],
        displayMode: PhotoDisplayMode,
        seed: Int,
        swatchSets: [[PaletteSwatch]]
    ) -> [PhotoOptionPayload] {
        let merged = filterEditorialQuality(pexels + unsplash + arena + google)
        let masterPool = dedupePhotos(
            rankedPhotoPool(merged)
        )
        var photoGroups = disjointPhotoGroups(pool: masterPool, groupSize: 6, groupCount: 3, seed: seed)
        swapLowResBundleAssetsTowardThirdDirection(&photoGroups)

        let options = [
            PhotoOptionPayload(
                id: "photos-editorial",
                displayMode: displayMode,
                source: photoGroups[0].first?.source ?? .mixed,
                direction: "editorial",
                photos: photoGroups[0],
                swatches: displayMode == .moodboard ? swatchSet(at: 0, in: swatchSets) : nil
            ),
            PhotoOptionPayload(
                id: "photos-clean",
                displayMode: displayMode,
                source: photoGroups[1].first?.source ?? .mixed,
                direction: "clean",
                photos: photoGroups[1],
                swatches: displayMode == .moodboard ? (swatchSet(at: 1, in: swatchSets) ?? swatchSet(at: 0, in: swatchSets)) : nil
            ),
            PhotoOptionPayload(
                id: "photos-experimental",
                displayMode: displayMode,
                source: photoGroups[2].first?.source ?? .mixed,
                direction: "experimental",
                photos: photoGroups[2],
                swatches: displayMode == .moodboard ? (swatchSet(at: 2, in: swatchSets) ?? swatchSet(at: 0, in: swatchSets)) : nil
            )
        ]

        return options.filter { $0.photos.count >= 5 }
    }

    /// Picks `groupCount` lists of `groupSize` photos from `pool`, reusing images across groups only after
    /// unique photos are exhausted so each direction stays visually distinct when enough results exist.
    private func disjointPhotoGroups(
        pool: [PhotoItemPayload],
        groupSize: Int,
        groupCount: Int,
        seed: Int
    ) -> [[PhotoItemPayload]] {
        guard groupSize > 0, groupCount > 0 else {
            return Array(repeating: [], count: max(0, groupCount))
        }

        let master = dedupePhotos(pool)
        guard !master.isEmpty else {
            return Array(repeating: [], count: groupCount)
        }

        var usedGlobally = Set<String>()
        var photographersGloballyUsed = Set<String>()
        var groups: [[PhotoItemPayload]] = []
        groups.reserveCapacity(groupCount)

        for g in 0..<groupCount {
            let rotated = shuffle(master, seed: seed &+ 104729 &* (g &+ 1))
            var group: [PhotoItemPayload] = []
            for photo in rotated where group.count < groupSize {
                let key = photo.id + photo.imageUrl
                if usedGlobally.contains(key) { continue }
                if blocksPhotographerDiversity(
                    group: group,
                    candidate: photo,
                    photographersGloballyUsed: photographersGloballyUsed,
                    enforceGlobalUniqueness: true
                ) { continue }
                if group.contains(where: { nearDuplicatePhotos($0, photo) }) { continue }
                usedGlobally.insert(key)
                group.append(photo)
                if let pk = namedPhotographerKey(photo) { photographersGloballyUsed.insert(pk) }
            }

            if group.count < groupSize {
                let fillerOrder = shuffle(master, seed: seed &+ 5011 &+ g &* 199)
                for photo in fillerOrder where group.count < groupSize {
                    let key = photo.id + photo.imageUrl
                    if group.contains(where: { $0.id == photo.id && $0.imageUrl == photo.imageUrl }) {
                        continue
                    }
                    if usedGlobally.contains(key) { continue }
                    if blocksPhotographerDiversity(
                        group: group,
                        candidate: photo,
                        photographersGloballyUsed: photographersGloballyUsed,
                        enforceGlobalUniqueness: true
                    ) { continue }
                    if group.contains(where: { nearDuplicatePhotos($0, photo) }) { continue }
                    usedGlobally.insert(key)
                    group.append(photo)
                    if let pk = namedPhotographerKey(photo) { photographersGloballyUsed.insert(pk) }
                }
            }

            if group.count < groupSize, !master.isEmpty {
                let pad = shuffle(master, seed: seed &+ 11_093 &+ g &* 47)
                var i = 0
                var guardrails = 0
                let maxPadSteps = max(pad.count * 8, groupSize * 12)
                while group.count < groupSize, guardrails < maxPadSteps {
                    let photo = pad[i % pad.count]
                    let key = photo.id + photo.imageUrl
                    if usedGlobally.contains(key) {
                        i += 1
                        guardrails += 1
                        continue
                    }
                    let enforceGlobalPhotographer = guardrails < maxPadSteps / 2
                    if blocksPhotographerDiversity(
                        group: group,
                        candidate: photo,
                        photographersGloballyUsed: photographersGloballyUsed,
                        enforceGlobalUniqueness: enforceGlobalPhotographer
                    ) {
                        i += 1
                        guardrails += 1
                        continue
                    }
                    if group.contains(where: { nearDuplicatePhotos($0, photo) }) {
                        i += 1
                        guardrails += 1
                        continue
                    }
                    usedGlobally.insert(key)
                    group.append(photo)
                    if let pk = namedPhotographerKey(photo) { photographersGloballyUsed.insert(pk) }
                    i += 1
                    guardrails += 1
                }
            }

            groups.append(group)
        }

        return groups
    }

    /// Swaps small on-device assets out of directions 1–2 when possible so they land on the third pager.
    private func swapLowResBundleAssetsTowardThirdDirection(_ groups: inout [[PhotoItemPayload]], threshold: Int = 1200) {
        guard groups.count == 3 else { return }

        func isLowResBundle(_ p: PhotoItemPayload) -> Bool {
            guard let b = p.bundleImageName, !b.isEmpty else { return false }
            guard let d = p.maxPixelDimension else { return true }
            return d < threshold
        }

        for gi in 0..<2 {
            var i = 0
            while i < groups[gi].count {
                guard isLowResBundle(groups[gi][i]) else {
                    i += 1
                    continue
                }
                guard let j = groups[2].firstIndex(where: { !isLowResBundle($0) }) else {
                    i += 1
                    continue
                }
                let a = groups[gi][i]
                groups[gi][i] = groups[2][j]
                groups[2][j] = a
                i += 1
            }
        }
    }

    private func buildUIOptions(prompt: String) -> [UIOptionPayload] {
        let productName = buildUIConceptName(prompt: prompt)
        let subject = inferUISubject(prompt: prompt)
        let feature = inferUIFeature(prompt: prompt)

        return [
            UIOptionPayload(
                id: "ui-1",
                direction: .editorial,
                label: "Editorial",
                productName: productName,
                headline: "A dramatic \(subject) with layered storytelling",
                supportingText: "Strong hierarchy, image-led composition, and premium pacing built for a first-impression concept.",
                primaryCta: "Explore concept",
                secondaryCta: "View story",
                accent: "#D98752",
                background: "#F6ECDD",
                surface: "#FFF9F2",
                mutedSurface: "#EEDBC5",
                text: "#1D120A",
                mutedText: "rgba(29,18,10,0.62)",
                featureKind: feature.kind,
                featureTitle: feature.title,
                featureItems: feature.items
            ),
            UIOptionPayload(
                id: "ui-2",
                direction: .minimal,
                label: "Minimal",
                productName: productName,
                headline: "A clear \(subject) system with calm spacing",
                supportingText: "Minimal framing, crisp modules, and a quieter visual rhythm for a refined polished direction.",
                primaryCta: "See layout",
                secondaryCta: "Read details",
                accent: "#6D8CFF",
                background: "#EEF3FF",
                surface: "#FFFFFF",
                mutedSurface: "#E1E9FF",
                text: "#111827",
                mutedText: "rgba(17,24,39,0.62)",
                featureKind: feature.kind,
                featureTitle: feature.title,
                featureItems: feature.items
            ),
            UIOptionPayload(
                id: "ui-3",
                direction: .bold,
                label: "Bold",
                productName: productName,
                headline: "A high-energy \(subject) with punchy motion cues",
                supportingText: "Asymmetry, larger moments, and brighter contrast for a more expressive concept direction.",
                primaryCta: "Launch idea",
                secondaryCta: "See modules",
                accent: "#F46FA9",
                background: "#111111",
                surface: "#1F1F1F",
                mutedSurface: "#2A2A2A",
                text: "#FFFFFF",
                mutedText: "rgba(255,255,255,0.62)",
                featureKind: feature.kind,
                featureTitle: feature.title,
                featureItems: feature.items
            )
        ]
    }

    private func inferUIFeature(prompt: String) -> (kind: UIFeatureKind, title: String, items: [String]) {
        let lowered = prompt.lowercased()

        if contains(lowered, pattern: #"(?i)(toggle|toggles|switch|switches|selection states?)"#) {
            return (.toggles, "Control States", ["Enabled", "Muted", "Focused"])
        }

        if contains(lowered, pattern: #"(?i)(picker|segment|segmented|tab|tabs|filter|chip|chips|dropdown)"#) {
            return (.picker, "Selection System", ["For You", "Popular", "Saved"])
        }

        if contains(lowered, pattern: #"(?i)(button|buttons|cta|call to action)"#) {
            return (.buttons, "Action Set", ["Primary", "Secondary", "Ghost"])
        }

        return (.cards, "Feature Modules", ["Overview", "Details", "Saved"])
    }

    private func buildPaletteArtifactHTML(options: [PaletteOptionPayload]) -> String {
        let payload = ["kind": "palette-options"]
        let data = try? JSONEncoder().encode(EmbeddedPayload(kind: payload["kind"]!, options: options))
        let json = data.flatMap { String(data: $0, encoding: .utf8) } ?? "{\"kind\":\"palette-options\",\"options\":[]}"

        return """
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover" />
            <script id="draft-palette-options" type="application/json">\(json)</script>
          </head>
          <body style="margin:0;background:#000;color:#fff;font-family:-apple-system,'SF Pro',sans-serif;">
            <div style="padding:28px 20px;">
              <div style="font-size:40px;font-weight:700;">Draft</div>
              <div style="font-size:20px;opacity:0.82;">Color Palette</div>
              <div style="margin-top:20px;font-size:15px;opacity:0.62;">Preparing native palette output...</div>
            </div>
          </body>
        </html>
        """
    }

    private func buildPhotoArtifactHTML(options: [PhotoOptionPayload]) -> String {
        let data = try? JSONEncoder().encode(EmbeddedPayload(kind: "photo-options", options: options))
        let json = data.flatMap { String(data: $0, encoding: .utf8) } ?? "{\"kind\":\"photo-options\",\"options\":[]}"

        return """
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover" />
            <script id="draft-photo-options" type="application/json">\(json)</script>
          </head>
          <body style="margin:0;background:#000;color:#fff;font-family:-apple-system,'SF Pro',sans-serif;">
            <div style="padding:28px 20px;">
              <div style="font-size:40px;font-weight:700;">Draft</div>
              <div style="font-size:20px;opacity:0.82;">\(options.first?.displayMode == .image ? "Image Gathering" : "Moodboard")</div>
              <div style="margin-top:20px;font-size:15px;opacity:0.62;">Preparing native \(options.first?.displayMode == .image ? "image" : "moodboard") output...</div>
            </div>
          </body>
        </html>
        """
    }

    private func buildUIArtifactHTML(options: [UIOptionPayload]) -> String {
        let data = try? JSONEncoder().encode(EmbeddedPayload(kind: "ui-options", options: options))
        let json = data.flatMap { String(data: $0, encoding: .utf8) } ?? "{\"kind\":\"ui-options\",\"options\":[]}"

        return """
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover" />
            <script id="draft-ui-options" type="application/json">\(json)</script>
          </head>
          <body style="margin:0;background:#000;color:#fff;font-family:-apple-system,'SF Pro',sans-serif;">
            <div style="padding:28px 20px;">
              <div style="font-size:40px;font-weight:700;">Draft</div>
              <div style="font-size:20px;opacity:0.82;">UI</div>
              <div style="margin-top:20px;font-size:15px;opacity:0.62;">Preparing native UI output...</div>
            </div>
          </body>
        </html>
        """
    }

    private func inferSeedHex(_ transcript: String) -> String {
        let lowered = transcript.lowercased()

        for (keyword, hex) in paletteKeywords where lowered.contains(keyword) {
            return hex
        }

        let hash = hashSeed(lowered)
        let r = 48 + (hash & 0x7f)
        let g = 48 + ((hash >> 7) & 0x7f)
        let b = 48 + ((hash >> 14) & 0x7f)
        return rgbToHex(r, g, b)
    }

    private func buildSearchQuery(_ prompt: String) -> String {
        prompt
            .lowercased()
            .replacingOccurrences(of: #"\b(can you|could you|would you|i want|i need|help me|show me|give me|find me|make me|please|curate|put together|bring together|draft)\b"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\b(some|a set of|set of|collection of)\b"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\b(reference images?|reference photos?|image references?|photo references?|images?|photos?|imagery|art direction|moodboard)\b"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[.,!?;:()\[\]"]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func requestClaudeArtifact(
        transcript: String,
        extraInstruction: String? = nil,
        maxTokens: Int = 2400,
        systemPrompt: String? = nil,
        treatResponseAsHTML: Bool = true
    ) async throws -> String {
        guard !keys.anthropic.isEmpty else {
            throw ArtifactGenerationError.unavailableBackend
        }

        let userContent = extraInstruction.map {
            "\(transcript)\n\nAdditional hard requirements:\n\($0)"
        } ?? transcript

        let system = systemPrompt ?? claudeSystemPrompt

        let payload: [String: Any] = [
            "model": claudeModel,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [
                [
                    "role": "user",
                    "content": userContent
                ]
            ]
        ]

        let body = try JSONSerialization.data(withJSONObject: payload)
        let response: ClaudeResponse = try await fetchJSON(
            url: claudeEndpoint,
            method: "POST",
            headers: [
                "x-api-key": keys.anthropic,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json"
            ],
            body: body
        )

        let text = (response.content ?? [])
            .filter { $0.type == "text" }
            .compactMap(\.text)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            throw ArtifactGenerationError.unavailableBackend
        }

        return cleanClaudeHTML(text, extractHTMLFragment: treatResponseAsHTML)
    }

    /// Asks Claude for three `UIOptionPayload` directions as JSON; merged with a local template for missing fields.
    private func generateClaudeStructuredUIOptions(prompt: String) async throws -> [UIOptionPayload]? {
        guard !keys.anthropic.isEmpty else { return nil }

        let uiInstructions = """
        Return ONLY a single JSON object (no markdown code fences, no text before or after) with this shape:
        { "kind": "ui-options", "options": [ { ... }, { ... }, { ... } ] }

        Include exactly 3 objects in "options". Each object MUST have these keys (all string values except featureItems):
        "id", "direction", "label", "productName", "headline", "supportingText", "primaryCta", "secondaryCta",
        "accent", "background", "surface", "mutedSurface", "text", "mutedText",
        "featureKind", "featureTitle", "featureItems"

        Rules:
        - direction must be lowercase: editorial, minimal, or bold (use all three once, in that order).
        - featureKind must be lowercase: toggles, buttons, picker, or cards.
        - featureItems must be an array of exactly 3 short strings.
        - Colors: use #RRGGBB for solid fills; mutedText may be rgba(...) if needed.
        - The three options must be genuinely different creative directions for the user's request—not the same structure with only color changes.
        """

        let raw = try await requestClaudeArtifact(
            transcript: prompt,
            extraInstruction: uiInstructions,
            maxTokens: 2800,
            systemPrompt: claudeUIStructuredSystemPrompt,
            treatResponseAsHTML: false
        )

        guard let data = extractJSONObjectData(from: raw) else { return nil }
        let dto = try JSONDecoder().decode(ClaudeUIPayloadDTO.self, from: data)
        guard dto.kind?.lowercased() == "ui-options", let optionDTOs = dto.options, optionDTOs.count == 3 else {
            return nil
        }

        return uiOptionsFromClaudeDTOs(optionDTOs, prompt: prompt)
    }

    private func generateClaudePhotoArtifact(prompt: String, displayMode: PhotoDisplayMode) async throws -> String? {
        guard !keys.anthropic.isEmpty else { return nil }

        let requestLabel = displayMode == .image ? "image" : "moodboard"
        let instructions = [
            "This is an \(requestLabel) request.",
            "Do not rely on external image URLs, stock APIs, or remote assets.",
            "Create a self-contained visual artifact with 3 swipeable directions using gradients, shapes, captions, and art-direction treatments.",
            "Treat each option as a different image-generation direction or moodboard concept for the same request.",
            "If photos would normally appear, simulate them with polished abstract editorial placeholders instead."
        ].joined(separator: "\n")

        return try await requestClaudeArtifact(
            transcript: prompt,
            extraInstruction: instructions,
            maxTokens: 1600
        )
    }

    private func photoArtifactFallback(prompt: String, displayMode: PhotoDisplayMode) async throws -> String {
        let localOptions = buildLocalPhotoOptions(prompt: prompt, displayMode: displayMode)
        if localOptions.count == 3, localOptions.allSatisfy({ $0.photos.count >= 5 }) {
            return buildPhotoArtifactHTML(options: localOptions)
        }

        if let claudeFallback = try await generateClaudePhotoArtifact(prompt: prompt, displayMode: displayMode) {
            return claudeFallback
        }

        throw ArtifactGenerationError.unavailableImageGeneration
    }

    private func cleanClaudeHTML(_ text: String, extractHTMLFragment: Bool = true) -> String {
        var cleaned = text
            .replacingOccurrences(of: #"^```html\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^```json\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^```\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*```$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if extractHTMLFragment, let firstTag = cleaned.firstIndex(of: "<"), firstTag > cleaned.startIndex {
            cleaned = String(cleaned[firstTag...])
        }

        return cleaned
    }

    /// First balanced `{ ... }` slice as UTF-8 data (for Claude JSON replies).
    private func extractJSONObjectData(from text: String) -> Data? {
        let trimmed = cleanClaudeHTML(text, extractHTMLFragment: false)
        guard let start = trimmed.firstIndex(of: "{"),
              let end = trimmed.lastIndex(of: "}"),
              start <= end else { return nil }
        return String(trimmed[start...end]).data(using: .utf8)
    }

    private func uiOptionsFromClaudeDTOs(_ dtos: [ClaudeUIOptionDTO], prompt: String) -> [UIOptionPayload]? {
        guard dtos.count == 3 else { return nil }
        let template = buildUIOptions(prompt: prompt)

        func pick(_ value: String?, fallback: String) -> String {
            let v = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return v.isEmpty ? fallback : v
        }

        return (0..<3).map { index in
            let c = dtos[index]
            let t = template[index]

            let dirRaw = c.direction?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
            let direction = UIDirection(rawValue: dirRaw) ?? t.direction

            let fkRaw = c.featureKind?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
            let featureKind = UIFeatureKind(rawValue: fkRaw) ?? t.featureKind

            let rawItems = (c.featureItems ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            let featureItems: [String] = {
                if rawItems.count >= 3 { return Array(rawItems.prefix(3)) }
                var merged = rawItems
                var ti = 0
                while merged.count < 3 {
                    merged.append(ti < t.featureItems.count ? t.featureItems[ti] : "Module \(merged.count + 1)")
                    ti += 1
                }
                return merged
            }()

            return UIOptionPayload(
                id: pick(c.id, fallback: t.id),
                direction: direction,
                label: pick(c.label, fallback: t.label),
                productName: pick(c.productName, fallback: t.productName),
                headline: pick(c.headline, fallback: t.headline),
                supportingText: pick(c.supportingText, fallback: t.supportingText),
                primaryCta: pick(c.primaryCta, fallback: t.primaryCta),
                secondaryCta: pick(c.secondaryCta, fallback: t.secondaryCta),
                accent: pick(c.accent, fallback: t.accent),
                background: pick(c.background, fallback: t.background),
                surface: pick(c.surface, fallback: t.surface),
                mutedSurface: pick(c.mutedSurface, fallback: t.mutedSurface),
                text: pick(c.text, fallback: t.text),
                mutedText: pick(c.mutedText, fallback: t.mutedText),
                featureKind: featureKind,
                featureTitle: pick(c.featureTitle, fallback: t.featureTitle),
                featureItems: featureItems
            )
        }
    }

    private func buildUIConceptName(prompt: String) -> String {
        let cleaned = prompt
            .lowercased()
            .replacingOccurrences(of: #"\b(generate|design|create|build|make|show|give|app|screen|interface|ui|dashboard|landing page|mobile|website|site|header|hero|section|layout|ideas|concept|for|with|a|an|the)\b"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[^\w\s]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let base = cleaned
            .split(separator: " ")
            .prefix(2)
            .map { $0.capitalized }
            .joined(separator: " ")

        let name = base.isEmpty ? "Studio" : base
        return name.replacingOccurrences(of: " Concept", with: "")
    }

    private func inferUISubject(prompt: String) -> String {
        let cleaned = prompt
            .lowercased()
            .replacingOccurrences(of: #"\b(generate|design|create|build|make|show|give|ideas|inspiration|creative direction|for|a|an|the)\b"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"[^\w\s]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? "digital experience" : cleaned
    }

    private func buildLocalPaletteOptions(seedHex: String) -> [PaletteOptionPayload] {
        // Three clearly different directions (warm seed-led, cool shifted, deep contrast) — not three pale washes of the same hue.
        let warmSpectrum = [
            PaletteSwatch(name: "Anchor", hex: seedHex),
            PaletteSwatch(name: "Ember", hex: mixHex(seedHex, "#E85D4C", 0.40)),
            PaletteSwatch(name: "Sand", hex: mixHex(seedHex, "#F4E4C1", 0.52)),
            PaletteSwatch(name: "Cinnamon", hex: mixHex(seedHex, "#7D4B2A", 0.44)),
            PaletteSwatch(name: "Blush", hex: mixHex(seedHex, "#F6A6A6", 0.42)),
            PaletteSwatch(name: "Olive", hex: mixHex(seedHex, "#5C6F4A", 0.36)),
        ]

        let coolMoon = [
            PaletteSwatch(name: "Beacon", hex: mixHex(seedHex, "#2DD4BF", 0.50)),
            PaletteSwatch(name: "Ice", hex: mixHex(seedHex, "#E0F2FE", 0.68)),
            PaletteSwatch(name: "Harbor", hex: mixHex(seedHex, "#1E3A5F", 0.46)),
            PaletteSwatch(name: "Pigeon", hex: mixHex(seedHex, "#94A3B8", 0.38)),
            PaletteSwatch(name: "Lavender", hex: mixHex(seedHex, "#DDD6FE", 0.48)),
            PaletteSwatch(name: "Seafoam", hex: mixHex(seedHex, "#CCFBF1", 0.60)),
        ]

        let studioContrast = [
            PaletteSwatch(name: "Obsidian", hex: mixHex(seedHex, "#0F172A", 0.74)),
            PaletteSwatch(name: "Linen", hex: "#F8FAFC"),
            PaletteSwatch(name: "Pulse", hex: mixHex(seedHex, "#EC4899", 0.58)),
            PaletteSwatch(name: "Steel", hex: mixHex(seedHex, "#64748B", 0.42)),
            PaletteSwatch(name: "Voltage", hex: mixHex(seedHex, "#EAB308", 0.48)),
            PaletteSwatch(name: "Mist", hex: mixHex(seedHex, "#E2E8F0", 0.58)),
        ]

        return [
            PaletteOptionPayload(id: "palette-local-1", swatches: withFixedPaletteBase(warmSpectrum)),
            PaletteOptionPayload(id: "palette-local-2", swatches: withFixedPaletteBase(coolMoon)),
            PaletteOptionPayload(id: "palette-local-3", swatches: withFixedPaletteBase(studioContrast)),
        ]
    }

    private func buildLocalPhotoOptions(prompt: String, displayMode: PhotoDisplayMode) -> [PhotoOptionPayload] {
        let candidateBoards = LibrarySeedData.boards.filter { board in
            board.items.filter { $0.kind == .image && $0.bundleImageName != nil }.count >= 5
        }

        let scoredBoards = candidateBoards
            .map { board in (board: board, score: localPhotoBoardScore(board: board, prompt: prompt)) }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.board.id < rhs.board.id
                }
                return lhs.score > rhs.score
            }
            .map(\.board)

        let orderedBoards = Array(scoredBoards.prefix(3))
        guard orderedBoards.count == 3 else { return [] }

        let swatchSets = displayMode == .moodboard
            ? orderedBoards.map(localMoodboardSwatches(for:))
            : Array(repeating: [], count: orderedBoards.count)

        let directions = ["editorial", "clean", "experimental"]
        let promptMatchedBundled = LibraryBundledPhotoMixer.photoPayloadsMatchingPrompt(prompt, limit: 12)

        return orderedBoards.enumerated().map { index, board in
            let boardPhotos = board.items
                .filter { $0.kind == .image }
                .enumerated()
                .map { photoIndex, item in
                    PhotoItemPayload(
                        id: "\(board.id)-local-\(photoIndex)",
                        imageUrl: "",
                        thumbUrl: "",
                        bundleImageName: item.bundleImageName,
                        maxPixelDimension: item.bundleImageName.flatMap { LibraryBundledPhotoMixer.maxPixelDimensionForAsset(named: $0) },
                        alt: item.alt ?? item.label,
                        source: photoSource(from: item.source),
                        author: item.author ?? board.promptTitle,
                        detailUrl: ""
                    )
                }

            let photos = Array(dedupePhotos(promptMatchedBundled + boardPhotos).prefix(6))

            return PhotoOptionPayload(
                id: "local-\(board.id)",
                displayMode: displayMode,
                source: photos.first?.source ?? .mixed,
                direction: index < directions.count ? directions[index] : directions[0],
                photos: photos,
                swatches: displayMode == .moodboard && index < swatchSets.count ? swatchSets[index] : nil
            )
        }
    }

    private func localPhotoBoardScore(board: LibraryBoard, prompt: String) -> Int {
        let promptTerms = normalizedTerms(prompt)
        guard !promptTerms.isEmpty else { return 0 }

        let boardTerms = normalizedTerms(
            ([board.promptTitle] + board.items.flatMap(localRetrievalTerms(for:)))
                .joined(separator: " ")
        )

        return promptTerms.reduce(into: 0) { score, term in
            if boardTerms.contains(term) {
                score += term.count > 5 ? 3 : 2
            }
        }
    }

    private func normalizedTerms(_ text: String) -> Set<String> {
        let normalized = text
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9\s]"#, with: " ", options: .regularExpression)
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .filter { $0.count > 2 }

        return Set(normalized)
    }

    private func localRetrievalTerms(for item: LibraryItem) -> [String] {
        var terms = [item.label, item.alt ?? "", item.author ?? "", item.bundleImageName ?? ""]

        if item.kind == .image {
            terms.append("image photo photography reference inspiration moodboard")
        }

        let bundleName = item.bundleImageName ?? ""
        let isUIReference =
            item.id.hasPrefix("ui-") ||
            item.generationID.hasPrefix("gen-ui-") ||
            bundleName.contains("ui") ||
            bundleName.contains("soft-spatial")

        if isUIReference {
            terms.append("ui interface app mobile screen control button toggle component dashboard")
        }

        if item.kind == .palette {
            terms.append("color palette swatch solid hue")
        }

        return terms
    }

    private func localMoodboardSwatches(for board: LibraryBoard) -> [PaletteSwatch] {
        Array(
            board.items
                .filter { $0.kind == .image }
                .prefix(4)
                .enumerated()
                .map { index, item in
                    PaletteSwatch(
                        name: index == 0 ? "Anchor" : item.label,
                        hex: String(format: "#%06X", item.previewColorHex)
                    )
                }
        )
    }

    private func photoSource(from source: LibrarySource?) -> PhotoSource {
        switch source {
        case .pexels:
            return .pexels
        case .unsplash:
            return .unsplash
        case .pinterest:
            return .pinterest
        case .arena:
            return .arena
        case .google:
            return .google
        case nil:
            return .mixed
        }
    }

    private func buildMoodboardSwatchSets(prompt: String) async -> [[PaletteSwatch]] {
        let seedHex = inferSeedHex(prompt)

        do {
            async let analogic = getTheColorScheme(seedHex: seedHex, mode: "analogic")
            async let quad = getTheColorScheme(seedHex: seedHex, mode: "quad")
            async let colormind = getColormindPalette(seedHex: seedHex)

            let fetched = [
                try await analogic,
                try await quad,
                try await colormind
            ]
            let mapped = fetched.map(compactMoodboardSwatches)
            if mapped.allSatisfy({ $0.count >= 4 }) {
                return mapped
            }
        } catch {
            // Fall back to deterministic local palettes when network-backed color APIs miss.
        }

        return buildLocalPaletteOptions(seedHex: seedHex)
            .map { compactMoodboardSwatches($0.swatches) }
    }

    private func swatchSet(at index: Int, in sets: [[PaletteSwatch]]) -> [PaletteSwatch]? {
        guard sets.indices.contains(index) else { return nil }
        return sets[index]
    }

    private func compactMoodboardSwatches(_ swatches: [PaletteSwatch]) -> [PaletteSwatch] {
        let filtered = swatches.filter { swatch in
            let name = swatch.name.lowercased()
            return name != "night" && name != "seasalt"
        }

        return Array(filtered.prefix(4))
    }

    private func withFixedPaletteBase(_ swatches: [PaletteSwatch]) -> [PaletteSwatch] {
        Array(swatches.prefix(6)) + [
            PaletteSwatch(name: "Night", hex: "#000000"),
            PaletteSwatch(name: "Seasalt", hex: "#F7F7F9")
        ]
    }

    private var hasImageProviders: Bool {
        !keys.pexels.isEmpty || !keys.unsplash.isEmpty || !keys.pinterestServiceURL.isEmpty
            || !keys.arenaToken.isEmpty || !keys.googleApiKey.isEmpty
    }

    private func fetchPinterestPhotos(query: String) async -> [PhotoItemPayload] {
        guard !keys.pinterestServiceURL.isEmpty,
              let baseURL = URL(string: keys.pinterestServiceURL) else { return [] }

        var components = URLComponents(url: baseURL.appendingPathComponent("search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "max", value: "10")
        ]

        guard let url = components?.url else { return [] }

        struct PinterestPhoto: Decodable {
            let id: String?
            let imageUrl: String?
            let thumbUrl: String?
            let alt: String?
            let author: String?
            let detailUrl: String?
        }
        struct PinterestResponse: Decodable {
            let photos: [PinterestPhoto]?
        }

        guard let response: PinterestResponse = try? await fetchJSON(url: url) else { return [] }

        return (response.photos ?? []).compactMap { photo in
            guard let id = photo.id,
                  let imageUrl = photo.imageUrl, !imageUrl.isEmpty,
                  let thumbUrl = photo.thumbUrl, !thumbUrl.isEmpty else { return nil }
            return PhotoItemPayload(
                id: id,
                imageUrl: imageUrl,
                thumbUrl: thumbUrl,
                bundleImageName: nil,
                alt: photo.alt ?? "Pinterest inspiration",
                source: .pinterest,
                author: photo.author ?? "Pinterest",
                detailUrl: photo.detailUrl ?? ""
            )
        }
    }

    private func isPalettePrompt(_ transcript: String) -> Bool {
        contains(
            transcript,
            pattern: #"(?i)(color palette|colour palette|palette|palettes|color scheme|colour scheme|brand colou?rs?|color direction|colour direction|color story|colour story|color system|colour system)"#
        )
    }

    private func isMoodboardPrompt(_ transcript: String) -> Bool {
        contains(transcript, pattern: #"(?i)(mood\s*board|moodboard)"#)
    }

    // Matches any clear UI / interface / screen / product request
    private func isUiPrompt(_ transcript: String) -> Bool {
        contains(
            transcript,
            pattern: #"(?i)\b(ui|ux|app screen|interface|product concept|visual design mock|dashboard|landing page|mobile app|screen design|app design|build a screen|generate a screen|home screen|design an app|design a mobile app|design a dashboard|design a landing page|website|web page|webpage|site|header|hero section|section design|layout concept|toggle|toggles|switch|switches|button|buttons|cta|picker|segment|segmented|tab bar|chip|chips|filter|dropdown|slider|stepper|bottom sheet|drawer|modal|form|settings screen|profile screen|onboarding|selection states?)\b"#
        )
        ||
        // App-first domain terms that map clearly to UI generation
        contains(
            transcript,
            pattern: #"(?i)\b(fitness (app|tracker)|wellness app|meditation app|music app|travel app|shopping app|ecommerce app|finance (app|dashboard)|social app|community app|creator (app|tool)|productivity (app|tool)|task app|planner app|investing (app|dashboard)|luxury app|playful app)\b"#
        )
    }

    // Matches photo/imagery/moodboard requests
    private func isPhotoPrompt(_ transcript: String) -> Bool {
        if isMoodboardPrompt(transcript) { return true }

        // Direct photo request words
        if contains(
            transcript,
            pattern: #"(?i)\b(photo|photos|photography|imagery|images|art direction|inspiration|reference images?|inspo|visual references?|photo references?|image references?)\b"#
        ), !isUiPrompt(transcript) {
            return true
        }

        // Photo-only domains from semantic_core.csv
        if contains(
            transcript,
            pattern: #"(?i)(fashion editorial|editorial fashion|magazine shoot|interior inspo|interior design|home moodboard|food shoot|food photography|recipe images|restaurant vibe|texture references|material moodboard|surfaces moodboard|street style|urban culture|city energy|misty forest|coastal cliffs|quiet nature|nature moodboard|portrait inspo|beauty references|face.focused shoot|concert vibe|festival mood|event (vibe|mood|energy)|workspace (moodboard|inspo)|desk setup|brand (shoot|campaign)|campaign references|travel (inspo|inspiration|moodboard)|wanderlust|creative collage|experimental image|luxury product (references|shoot|images))"#
        ) { return true }

        if isPalettePrompt(transcript) || isUiPrompt(transcript) { return false }

        return false
    }

    private func fetchJSON<T: Decodable>(
        url: URL,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 20
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ArtifactGenerationError.unavailableBackend
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    private func shuffle<T>(_ items: [T], seed: Int) -> [T] {
        guard items.count > 1 else { return items }

        var copy = items
        var state = max(seed, 1)

        for index in stride(from: copy.count - 1, through: 1, by: -1) {
            state = (state &* 1664525 &+ 1013904223) & 0x7fffffff
            let swapIndex = state % (index + 1)
            copy.swapAt(index, swapIndex)
        }

        return copy
    }

    private func rankedPhotoPool(_ photos: [PhotoItemPayload]) -> [PhotoItemPayload] {
        photos
            .enumerated()
            .sorted { lhs, rhs in
                let lr = sourceQualityRank(lhs.element.source)
                let rr = sourceQualityRank(rhs.element.source)
                if lr != rr { return lr < rr }
                let ld = lhs.element.maxPixelDimension ?? Int.max
                let rd = rhs.element.maxPixelDimension ?? Int.max
                if ld != rd { return ld > rd }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    /// Lower sorts earlier (preferred). API order within a source is preserved via `rankedPhotoPool` input index.
    private func sourceQualityRank(_ source: PhotoSource) -> Int {
        switch source {
        case .mixed:
            return 0
        case .unsplash:
            return 1
        case .pexels:
            return 2
        case .arena:
            return 3
        case .pinterest:
            return 4
        case .google:
            return 5
        }
    }

    private func unsplashDisplayURL(raw: String?, full: String?, regular: String?, small: String?) -> String? {
        if let raw, !raw.isEmpty {
            return raw.contains("?")
                ? "\(raw)&w=2400&q=85&auto=format&fit=max"
                : "\(raw)?w=2400&q=85&auto=format&fit=max"
        }
        if let full, !full.isEmpty { return full }
        return regular ?? small
    }

    /// Removes low-trust or low-quality remote URLs so editorial output stays clean. On-device bundle images always pass.
    private func filterEditorialQuality(_ photos: [PhotoItemPayload]) -> [PhotoItemPayload] {
        photos.filter { passesEditorialImagePolicy($0) }
    }

    private func passesEditorialImagePolicy(_ photo: PhotoItemPayload) -> Bool {
        if let bundle = photo.bundleImageName, !bundle.isEmpty {
            return true
        }

        let raw = photo.imageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, URL(string: raw) != nil else { return false }

        let lowered = raw.lowercased()
        guard lowered.hasPrefix("https://") else { return false }
        guard !lowered.hasSuffix(".svg") else { return false }
        if lowered.contains(".svg?") { return false }

        let junkMarkers = [
            "favicon", "sprite", "emoji", "/icons/", "icon.png", "1x1", "pixel.gif",
            "spacer.gif", "blank.gif", "transparent.gif", "placeholder", "loading.gif",
            "qrcode", "qr-code"
        ]
        if junkMarkers.contains(where: { lowered.contains($0) }) { return false }

        // Google Programmable Search image results are often scraper pages, icons, or odd crops.
        if photo.source == .google {
            return false
        }

        if lowered.contains("googleusercontent.com") || lowered.contains("ggpht.com") {
            if lowered.range(of: #"=s\d{1,3}(-c)?"#, options: .regularExpression) != nil {
                return false
            }
        }

        switch photo.source {
        case .pinterest:
            if !passesPinterestPipelineURL(lowered) { return false }
        case .pexels:
            guard lowered.contains("pexels.com") else { return false }
        case .unsplash:
            guard lowered.contains("unsplash.com") else { return false }
        case .arena:
            if lowered.contains("_thumb.") || lowered.contains("/thumb/") || lowered.contains("thumb.png") {
                return false
            }
            guard lowered.contains("are.na") || passesTrustedImageURLHost(lowered) else { return false }
        case .google:
            return false
        case .mixed:
            guard passesTrustedImageURLHost(lowered) else { return false }
        }

        return true
    }

    /// Pinterest service responses should only surface known-good delivery URLs (or major stock hosts).
    private func passesPinterestPipelineURL(_ lowered: String) -> Bool {
        if lowered.contains("pinimg.com") { return true }
        if lowered.range(of: #"(\.|//)pinterest\.[a-z.]{2,}/"#, options: .regularExpression) != nil { return true }
        if lowered.contains("pexels.com") || lowered.contains("unsplash.com") { return true }
        if imageLikePathSuffix(lowered) {
            return passesTrustedImageURLHost(lowered)
        }
        return false
    }

    private func imageLikePathSuffix(_ lowered: String) -> Bool {
        guard let path = lowered.split(separator: "?").first.map(String.init) else { return false }
        let p = path.lowercased()
        return [".jpg", ".jpeg", ".png", ".webp"].contains { p.hasSuffix($0) }
    }

    private func passesTrustedImageURLHost(_ lowered: String) -> Bool {
        guard let host = URL(string: lowered)?.host?.lowercased(), host.contains(".") else { return false }
        let denyFragments = [
            "gravatar.com", "reddit.com", "redd.it", "tiktokcdn", "twimg.com",
            "fbcdn.net", "facebook.com", "instagram.com", "cdninstagram.com",
            "giphy.com", "ebayimg.com", "pin.it", "bit.ly", "t.co"
        ]
        if denyFragments.contains(where: { host.contains($0) }) { return false }
        return true
    }

    private func dedupePhotos(_ photos: [PhotoItemPayload]) -> [PhotoItemPayload] {
        var seen = Set<String>()
        var pass1: [PhotoItemPayload] = []
        for photo in photos {
            let key: String
            if let bundle = photo.bundleImageName, !bundle.isEmpty {
                key = "bundle:\(bundle)"
            } else {
                key = canonicalImageResourceKey(photo.imageUrl)
            }
            if seen.contains(key) { continue }
            seen.insert(key)
            pass1.append(photo)
        }
        return dedupeNearDuplicateAlts(pass1)
    }

    private func canonicalImageResourceKey(_ urlString: String) -> String {
        guard let url = URL(string: urlString) else { return urlString.lowercased() }
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()
        if host.contains("pexels.com"), path.contains("/photos/") {
            if let range = path.range(of: #"/photos/\d+"#, options: .regularExpression) {
                return host + String(path[range])
            }
        }
        return host + path
    }

    private func altTokenSet(_ alt: String) -> Set<String> {
        let normalized = alt
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9\s]"#, with: " ", options: .regularExpression)
        return Set(
            normalized
                .split(whereSeparator: \.isWhitespace)
                .map(String.init)
                .filter { $0.count > 2 }
        )
    }

    private func meaningfulAltTokens(_ alt: String) -> Set<String> {
        altTokenSet(alt).subtracting(ShootClustering.noiseTokens)
    }

    private func jaccard(_ a: Set<String>, _ b: Set<String>) -> Double {
        let union = a.union(b).count
        guard union > 0 else { return 0 }
        return Double(a.intersection(b).count) / Double(union)
    }

    private func isGenericStockAttribution(_ author: String) -> Bool {
        let a = author.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let generic: Set<String> = [
            "pexels", "unsplash", "pinterest", "google", "are.na", "arena",
            "pexels inspiration image", "unsplash inspiration image", "pinterest inspiration",
            "google inspiration", "are.na inspiration"
        ]
        return generic.contains(a) || a.hasPrefix("pexels ") || a.hasPrefix("unsplash ")
    }

    private func namedPhotographerKey(_ photo: PhotoItemPayload) -> String? {
        let raw = photo.author.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, !isGenericStockAttribution(photo.author) else { return nil }
        return raw.lowercased()
    }

    /// Blocks a candidate if a credited photographer already appears in this group, or (when `enforceGlobalUniqueness`)
    /// anywhere on the three-direction board — reducing same-shoot clusters from one creator across the pager.
    private func blocksPhotographerDiversity(
        group: [PhotoItemPayload],
        candidate: PhotoItemPayload,
        photographersGloballyUsed: Set<String>,
        enforceGlobalUniqueness: Bool
    ) -> Bool {
        guard let pk = namedPhotographerKey(candidate) else { return false }
        if group.contains(where: { namedPhotographerKey($0) == pk }) { return true }
        if enforceGlobalUniqueness, photographersGloballyUsed.contains(pk) { return true }
        return false
    }

    /// Drops near-duplicates (same URL resource, bundle, or same creator + very similar alt), keeping the first (highest-ranked) row.
    private func dedupeNearDuplicateAlts(_ photos: [PhotoItemPayload]) -> [PhotoItemPayload] {
        var out: [PhotoItemPayload] = []
        for photo in photos {
            if out.contains(where: { nearDuplicatePhotos($0, photo) }) { continue }
            out.append(photo)
        }
        return out
    }

    private func nearDuplicatePhotos(_ a: PhotoItemPayload, _ b: PhotoItemPayload) -> Bool {
        if let ba = a.bundleImageName, let bb = b.bundleImageName, !ba.isEmpty, ba == bb {
            return true
        }
        if canonicalImageResourceKey(a.imageUrl) == canonicalImageResourceKey(b.imageUrl) {
            return true
        }
        return samePhotoshootCluster(a, b)
    }

    /// Heuristic cluster for “same shoot / same batch”: overlapping scene keywords or same credited photographer + similar copy.
    private func samePhotoshootCluster(_ a: PhotoItemPayload, _ b: PhotoItemPayload) -> Bool {
        let authorA = a.author.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let authorB = b.author.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let genA = authorA.isEmpty || isGenericStockAttribution(a.author)
        let genB = authorB.isEmpty || isGenericStockAttribution(b.author)
        let ma = meaningfulAltTokens(a.alt)
        let mb = meaningfulAltTokens(b.alt)
        let fullA = altTokenSet(a.alt)
        let fullB = altTokenSet(b.alt)

        if !genA && !genB, authorA == authorB {
            if ma.count >= 2, mb.count >= 2 {
                let ij = ma.intersection(mb).count
                if ij >= 2, jaccard(ma, mb) >= 0.18 { return true }
                if ij >= 3 { return true }
            }
            if fullA.count >= 4, fullB.count >= 4, jaccard(fullA, fullB) >= 0.32 { return true }
        }

        if genA && genB, ma.count >= 3, mb.count >= 3 {
            if ma == mb { return true }
            let ij = ma.intersection(mb).count
            if ij >= 5 { return true }
            if jaccard(ma, mb) >= 0.48, ij >= 4 { return true }
        }

        if genA && genB, a.source == b.source, ma.count >= 4, mb.count >= 4 {
            let sa = ma.sorted().joined(separator: "+")
            let sb = mb.sorted().joined(separator: "+")
            if !sa.isEmpty, sa == sb { return true }
        }

        return false
    }

    private func mixHex(_ base: String, _ target: String, _ amount: Double) -> String {
        let from = hexToRGB(base)
        let to = hexToRGB(target)
        let mix = { (start: Int, end: Int) in
            Int(round(Double(start) + (Double(end - start) * amount)))
        }

        return rgbToHex(mix(from.r, to.r), mix(from.g, to.g), mix(from.b, to.b))
    }

    private func contains(_ text: String, pattern: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }

    private func matches(for pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let matchRange = Range(match.range, in: text) else { return nil }
            return String(text[matchRange])
        }
    }

    private func makeURL(base: URL, path: String, queryItems: [URLQueryItem] = []) -> URL {
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        let basePath = components?.path ?? ""
        components?.path = basePath + path
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        return components?.url ?? base
    }

    private func isHex(_ value: String) -> Bool {
        value.range(of: #"^#[0-9A-F]{6}$"#, options: .regularExpression) != nil
    }

    private func hashSeed(_ input: String) -> Int {
        input.unicodeScalars.reduce(5381) { partialResult, scalar in
            ((partialResult << 5) &+ partialResult) &+ Int(scalar.value)
        }
    }

    private func hexToRGB(_ hex: String) -> (r: Int, g: Int, b: Int) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        let r = Int(cleaned.prefix(2), radix: 16) ?? 0
        let g = Int(cleaned.dropFirst(2).prefix(2), radix: 16) ?? 0
        let b = Int(cleaned.dropFirst(4).prefix(2), radix: 16) ?? 0
        return (r, g, b)
    }

    private func rgbToHex(_ r: Int, _ g: Int, _ b: Int) -> String {
        String(format: "#%02X%02X%02X", clamp(r), clamp(g), clamp(b))
    }

    private func clamp(_ value: Int) -> Int {
        min(max(value, 0), 255)
    }
}

private struct ClaudeUIPayloadDTO: Decodable {
    let kind: String?
    let options: [ClaudeUIOptionDTO]?
}

private struct ClaudeUIOptionDTO: Decodable {
    let id: String?
    let direction: String?
    let label: String?
    let productName: String?
    let headline: String?
    let supportingText: String?
    let primaryCta: String?
    let secondaryCta: String?
    let accent: String?
    let background: String?
    let surface: String?
    let mutedSurface: String?
    let text: String?
    let mutedText: String?
    let featureKind: String?
    let featureTitle: String?
    let featureItems: [String]?
}

private struct EmbeddedPayload<T: Encodable>: Encodable {
    let kind: String
    let options: [T]
}

private extension Array where Element == Double {
    subscript(safe index: Int) -> Double? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
