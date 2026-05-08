import Foundation

enum LibraryItemKind: String, Hashable {
    case palette
    case image
}

enum LibrarySource: String, Hashable {
    case pexels
    case unsplash
    case pinterest
    case arena
    case google
}

struct LibraryItem: Identifiable, Hashable {
    let id: String
    let kind: LibraryItemKind
    let label: String
    let previewColorHex: UInt
    let secondaryColorHex: UInt
    let generationID: String
    let imageURL: URL?
    let thumbnailURL: URL?
    let bundleImageName: String?
    let alt: String?
    let source: LibrarySource?
    let author: String?

    init(
        id: String,
        kind: LibraryItemKind,
        label: String,
        previewColorHex: UInt,
        secondaryColorHex: UInt,
        generationID: String,
        imageURL: String? = nil,
        thumbnailURL: String? = nil,
        bundleImageName: String? = nil,
        alt: String? = nil,
        source: LibrarySource? = nil,
        author: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.label = label
        self.previewColorHex = previewColorHex
        self.secondaryColorHex = secondaryColorHex
        self.generationID = generationID
        self.imageURL = imageURL.flatMap(URL.init(string:))
        self.thumbnailURL = thumbnailURL.flatMap(URL.init(string:))
        self.bundleImageName = bundleImageName
        self.alt = alt
        self.source = source
        self.author = author
    }
}

struct LibraryBoard: Identifiable, Hashable {
    let id: String
    let promptTitle: String
    let itemCount: Int
    let updatedAtLabel: String
    let generationID: String
    let items: [LibraryItem]

    var subtitle: String {
        if items.allSatisfy({ $0.kind == .palette }) {
            return "Color palette"
        }
        if id == "ui-controls-board" {
            return "Interface studies"
        }
        return "Saved inspiration"
    }
    var previewItems: [LibraryItem] { Array(items.prefix(4)) }
}

struct LibraryCollection: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let countLabel: String
    let description: String
    let boardIDs: [String]
}

enum LibrarySeedData {
    static let boards: [LibraryBoard] = [
        LibraryBoard(
            id: "rosewood-palette-board",
            promptTitle: "Rosewood Palette",
            itemCount: 5,
            updatedAtLabel: "Saved today",
            generationID: "gen-rosewood-palette",
            items: [
                .init(id: "rosewood-1", kind: .palette, label: "Soft cream", previewColorHex: 0xF5E8DE, secondaryColorHex: 0xFFF8F2, generationID: "gen-rosewood-palette"),
                .init(id: "rosewood-2", kind: .palette, label: "Blush clay", previewColorHex: 0xE8B8A6, secondaryColorHex: 0xF2D0C3, generationID: "gen-rosewood-palette"),
                .init(id: "rosewood-3", kind: .palette, label: "Rosewood", previewColorHex: 0xA66C66, secondaryColorHex: 0xC88D87, generationID: "gen-rosewood-palette"),
                .init(id: "rosewood-4", kind: .palette, label: "Sage", previewColorHex: 0x8FA39A, secondaryColorHex: 0xB2C4BC, generationID: "gen-rosewood-palette"),
                .init(id: "rosewood-5", kind: .palette, label: "Midnight", previewColorHex: 0x1E2430, secondaryColorHex: 0x384252, generationID: "gen-rosewood-palette"),
            ]
        ),
        LibraryBoard(
            id: "ui-controls-board",
            promptTitle: "Soft Spatial UI",
            itemCount: 4,
            updatedAtLabel: "Saved today",
            generationID: "gen-soft-spatial-ui",
            items: [
                .init(id: "ui-controls-1", kind: .image, label: "Avatar cluster", previewColorHex: 0xF3E9D9, secondaryColorHex: 0xF39B2C, generationID: "gen-soft-spatial-ui", alt: "Avatar cluster with tooltip and soft floating profile circles", source: nil, author: "Draft"),
                .init(id: "ui-controls-2", kind: .image, label: "Floating cards", previewColorHex: 0xF8F3EA, secondaryColorHex: 0xFF8B26, generationID: "gen-soft-spatial-ui", alt: "Editorial UI composition with floating marketplace cards around centered copy", source: nil, author: "Draft"),
                .init(id: "ui-controls-3", kind: .image, label: "Interest picker", previewColorHex: 0xF7F3EB, secondaryColorHex: 0xB62D1F, generationID: "gen-soft-spatial-ui", alt: "Soft spatial onboarding screen with floating rounded image cards and a central selection tray", source: nil, author: "Draft"),
                .init(id: "ui-controls-4", kind: .image, label: "Selection states", previewColorHex: 0xF5F2E9, secondaryColorHex: 0xCAA968, generationID: "gen-soft-spatial-ui", alt: "Minimal onboarding card with selected and empty states in a floating spatial layout", source: nil, author: "Draft"),
            ]
        ),
        LibraryBoard(
            id: "warm-kitchen-palette",
            promptTitle: "Warm Kitchen Palette",
            itemCount: 6,
            updatedAtLabel: "Saved today",
            generationID: "gen-kitchen-palette",
            items: [
                .init(id: "kitchen-1", kind: .palette, label: "Butter yellow", previewColorHex: 0xC8873A, secondaryColorHex: 0xE6BC65, generationID: "gen-kitchen-palette"),
                .init(id: "kitchen-2", kind: .palette, label: "Soft cream", previewColorHex: 0xE8D2A5, secondaryColorHex: 0xF3E7CA, generationID: "gen-kitchen-palette"),
                .init(id: "kitchen-3", kind: .image, label: "Tile reference", previewColorHex: 0x8A6F52, secondaryColorHex: 0xB2936B, generationID: "gen-kitchen-palette", imageURL: "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80", thumbnailURL: "https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=600&q=80", alt: "Warm kitchen interior with natural wood and stone surfaces", source: .unsplash, author: "Unsplash"),
                .init(id: "kitchen-4", kind: .image, label: "Cabinet detail", previewColorHex: 0x6E5B43, secondaryColorHex: 0x8F7A5F, generationID: "gen-kitchen-palette", imageURL: "https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80", thumbnailURL: "https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=600&q=80", alt: "Kitchen cabinetry detail with warm wood tones", source: .unsplash, author: "Unsplash"),
                .init(id: "kitchen-5", kind: .palette, label: "Olive accent", previewColorHex: 0x6F7152, secondaryColorHex: 0x8C8E6A, generationID: "gen-kitchen-palette"),
                .init(id: "kitchen-6", kind: .image, label: "Lighting", previewColorHex: 0xAF8454, secondaryColorHex: 0xD6A36A, generationID: "gen-kitchen-palette", imageURL: "https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80", thumbnailURL: "https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=600&q=80", alt: "Kitchen pendant lighting over a warm interior", source: .unsplash, author: "Unsplash"),
            ]
        ),
        LibraryBoard(
            id: "yellow-kitchen-refresh",
            promptTitle: "Desert Dreams",
            itemCount: 5,
            updatedAtLabel: "Saved today",
            generationID: "gen-desert-dreams",
            items: [
                .init(id: "desert-1", kind: .image, label: "Sandstone portal", previewColorHex: 0xBA7A47, secondaryColorHex: 0xE5A16A, generationID: "gen-desert-dreams", bundleImageName: "desert-dreams-1", alt: "Warm desert interior framing a sunset landscape", source: nil, author: "Direction 1"),
                .init(id: "desert-2", kind: .image, label: "Mirage runway", previewColorHex: 0xD8875E, secondaryColorHex: 0xF3B27E, generationID: "gen-desert-dreams", bundleImageName: "desert-dreams-2", alt: "Figure walking through a minimal desert scene at sunset", source: nil, author: "Direction 1"),
                .init(id: "desert-3", kind: .image, label: "Ochre chamber", previewColorHex: 0xB55E2F, secondaryColorHex: 0xE3894A, generationID: "gen-desert-dreams", bundleImageName: "desert-dreams-3", alt: "Immersive installation glowing with orange desert light", source: nil, author: "Direction 1"),
                .init(id: "desert-4", kind: .image, label: "Solar gesture", previewColorHex: 0xC65A1B, secondaryColorHex: 0xFFB14C, generationID: "gen-desert-dreams", bundleImageName: "desert-dreams-4", alt: "Silhouetted hands against a radiant amber background", source: nil, author: "Direction 1"),
                .init(id: "desert-5", kind: .image, label: "Quiet horizon", previewColorHex: 0xD3A184, secondaryColorHex: 0xF0D1C1, generationID: "gen-desert-dreams", bundleImageName: "desert-dreams-5", alt: "Solitary figure overlooking a pastel desert expanse", source: nil, author: "Direction 1"),
            ]
        ),
        LibraryBoard(
            id: "calm-bedroom-board",
            promptTitle: "Open Court Energy",
            itemCount: 7,
            updatedAtLabel: "Saved today",
            generationID: "gen-open-court-energy",
            items: [
                .init(id: "open-court-1", kind: .image, label: "Sky sole", previewColorHex: 0x5DB7EA, secondaryColorHex: 0x97D8F6, generationID: "gen-open-court-energy", bundleImageName: "open-court-1", alt: "Low-angle fashion image with oversized shoes against a bright sky", source: nil, author: "Direction 2"),
                .init(id: "open-court-2", kind: .image, label: "Parking lot chrome", previewColorHex: 0x88B8D7, secondaryColorHex: 0xCFDFEA, generationID: "gen-open-court-energy", bundleImageName: "open-court-2", alt: "Sporty outdoor portrait with metallic sneakers and a parking lot backdrop", source: nil, author: "Direction 2"),
                .init(id: "open-court-3", kind: .image, label: "Baseline chic", previewColorHex: 0x2A5E9A, secondaryColorHex: 0x75B4FF, generationID: "gen-open-court-energy", bundleImageName: "open-court-3", alt: "Editorial tennis fashion on a bright blue court", source: nil, author: "Direction 2"),
                .init(id: "open-court-4", kind: .image, label: "Sun visor serve", previewColorHex: 0x8EB53F, secondaryColorHex: 0xD6E86C, generationID: "gen-open-court-energy", bundleImageName: "open-court-4", alt: "Outdoor tennis scene with lime court tones and sunlit styling", source: nil, author: "Direction 2"),
                .init(id: "open-court-5", kind: .image, label: "Club colors", previewColorHex: 0xE0D58B, secondaryColorHex: 0xF7F0B7, generationID: "gen-open-court-energy", bundleImageName: "open-court-5", alt: "Group portrait featuring colorful football-inspired streetwear", source: nil, author: "Direction 2"),
                .init(id: "open-court-6", kind: .image, label: "Court edge", previewColorHex: 0x3A6EA8, secondaryColorHex: 0x6FA8DC, generationID: "gen-open-court-energy", bundleImageName: "open-court-6", alt: "Outdoor court fashion editorial", source: nil, author: "Direction 2"),
                .init(id: "open-court-7", kind: .image, label: "Drop serve", previewColorHex: 0x5A8CC2, secondaryColorHex: 0x9DC0E8, generationID: "gen-open-court-energy", bundleImageName: "open-court-7", alt: "Dynamic sportswear editorial", source: nil, author: "Direction 2"),
            ]
        ),
        LibraryBoard(
            id: "recipe-app-concept",
            promptTitle: "Recipe App Concept",
            itemCount: 4,
            updatedAtLabel: "Saved today",
            generationID: "gen-recipe-app-concept",
            items: [
                .init(id: "recipe-app-concept-1", kind: .image, label: "Gem grin", previewColorHex: 0xFF5C8A, secondaryColorHex: 0xFFC145, generationID: "gen-recipe-app-concept", bundleImageName: "recipe-app-concept-1", alt: "Close-up beauty image with colorful gems and playful styling", source: nil, author: "Direction 4"),
                .init(id: "recipe-app-concept-2", kind: .image, label: "Pop orbit", previewColorHex: 0xFF7A1A, secondaryColorHex: 0xA86DFF, generationID: "gen-recipe-app-concept", bundleImageName: "recipe-app-concept-2", alt: "Playful campaign collage with objects orbiting around bold copy", source: nil, author: "Direction 4"),
                .init(id: "recipe-app-concept-3", kind: .image, label: "Tree scene", previewColorHex: 0x7BBE4E, secondaryColorHex: 0xB8D97D, generationID: "gen-recipe-app-concept", bundleImageName: "recipe-app-concept-3", alt: "Stylized outdoor tableau with figures perched in a tree", source: nil, author: "Direction 4"),
                .init(id: "recipe-app-concept-4", kind: .image, label: "Air motion", previewColorHex: 0x7198FF, secondaryColorHex: 0xF49AE1, generationID: "gen-recipe-app-concept", bundleImageName: "recipe-app-concept-4", alt: "Dynamic fashion figures suspended mid-air against a gradient sky", source: nil, author: "Direction 4"),
            ]
        ),
        LibraryBoard(
            id: "nike-editorial-board",
            promptTitle: "Nike Editorial",
            itemCount: 5,
            updatedAtLabel: "Saved today",
            generationID: "gen-nike-editorial",
            items: [
                .init(id: "nike-editorial-1", kind: .image, label: "Nike portrait", previewColorHex: 0xF3D11E, secondaryColorHex: 0xA83B25, generationID: "gen-nike-editorial", bundleImageName: "nike-editorial-1", alt: "Profile portrait with oversized Nike wordmark and bright cyan hair against a red background", source: nil, author: "Direction 5"),
                .init(id: "nike-editorial-2", kind: .image, label: "City tote", previewColorHex: 0xF3D11E, secondaryColorHex: 0x7CB6F7, generationID: "gen-nike-editorial", bundleImageName: "nike-editorial-2", alt: "Low-angle street fashion image with a sculptural yellow bag in Times Square", source: nil, author: "Direction 5"),
                .init(id: "nike-editorial-3", kind: .image, label: "Lime motion", previewColorHex: 0xE4D01D, secondaryColorHex: 0xACB4C1, generationID: "gen-nike-editorial", bundleImageName: "nike-editorial-3", alt: "Dynamic low-angle fashion shot with a neon yellow garment against a pale sky", source: nil, author: "Direction 5"),
                .init(id: "nike-editorial-4", kind: .image, label: "Typographic lockup", previewColorHex: 0xF0CE18, secondaryColorHex: 0x111111, generationID: "gen-nike-editorial", bundleImageName: "nike-editorial-4", alt: "Bold black typographic lockup on a bright yellow field", source: nil, author: "Direction 5"),
                .init(id: "nike-editorial-5", kind: .image, label: "Get Into It", previewColorHex: 0xD9DA8A, secondaryColorHex: 0xD85A23, generationID: "gen-nike-editorial", bundleImageName: "nike-editorial-5", alt: "Poster-style campaign image with GET INTO IT typography and a model in yellow activewear", source: nil, author: "Direction 5"),
            ]
        ),
    ]

    static let collections: [LibraryCollection] = [
        .init(
            id: "latest",
            title: "Latest",
            subtitle: "Recent generations ready to revisit",
            countLabel: "\(boards.count) boards",
            description: "Browse the most recent generations and continue sorting saves.",
            boardIDs: boards.map(\.id)
        ),
        .init(
            id: "individual",
            title: "Individual",
            subtitle: "Single saved images and swatches",
            countLabel: "\(boards.reduce(0) { $0 + $1.itemCount }) items",
            description: "Single pieces from a generation can live outside a full board.",
            boardIDs: boards.filter { $0.items.contains(where: { $0.kind == .image }) }.map(\.id)
        ),
    ]

    static func board(id: String) -> LibraryBoard? {
        boards.first(where: { $0.id == id })
    }

    static func collection(id: String) -> LibraryCollection? {
        collections.first(where: { $0.id == id })
    }
}
