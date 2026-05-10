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
        if id.hasPrefix("ui-") {
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
    static let boards: [LibraryBoard] = baseBoards + LocalGalleryImports.boards

    private static let baseBoards: [LibraryBoard] = [
        LibraryBoard(
            id: "yellow-kitchen-refresh",
            promptTitle: "Desert Dreams",
            itemCount: 6,
            updatedAtLabel: "Saved today",
            generationID: "gen-desert-dreams",
            items: [
                .init(id: "desert-1", kind: .image, label: "Sandstone portal", previewColorHex: 0xBA7A47, secondaryColorHex: 0xE5A16A, generationID: "gen-desert-dreams", bundleImageName: "desert-dreams-1", alt: "Warm desert interior framing a sunset landscape", source: nil, author: "Direction 1"),
                .init(id: "desert-2", kind: .image, label: "Mirage runway", previewColorHex: 0xD8875E, secondaryColorHex: 0xF3B27E, generationID: "gen-desert-dreams", bundleImageName: "desert-dreams-2", alt: "Figure walking through a minimal desert scene at sunset", source: nil, author: "Direction 1"),
                .init(id: "desert-3", kind: .image, label: "Ochre chamber", previewColorHex: 0xB55E2F, secondaryColorHex: 0xE3894A, generationID: "gen-desert-dreams", bundleImageName: "desert-dreams-3", alt: "Immersive installation glowing with orange desert light", source: nil, author: "Direction 1"),
                .init(id: "desert-4", kind: .image, label: "Solar gesture", previewColorHex: 0xC65A1B, secondaryColorHex: 0xFFB14C, generationID: "gen-desert-dreams", bundleImageName: "desert-dreams-4", alt: "Silhouetted hands against a radiant amber background", source: nil, author: "Direction 1"),
                .init(id: "desert-4a", kind: .palette, label: "Frost moth", previewColorHex: 0xC65A1B, secondaryColorHex: 0xFFB14C, generationID: "gen-desert-dreams"),
                .init(id: "desert-5", kind: .image, label: "Quiet horizon", previewColorHex: 0xD3A184, secondaryColorHex: 0xF0D1C1, generationID: "gen-desert-dreams", bundleImageName: "desert-dreams-5", alt: "Solitary figure overlooking a pastel desert expanse", source: nil, author: "Direction 1"),
            ]
        ),
        LibraryBoard(
            id: "neon-signals-board",
            promptTitle: "Neon Signals",
            itemCount: 5,
            updatedAtLabel: "Saved today",
            generationID: "gen-neon-signals",
            items: [
                .init(id: "neon-1", kind: .image, label: "ArcMatrix", previewColorHex: 0x70E010, secondaryColorHex: 0xA8FF50, generationID: "gen-neon-signals", bundleImageName: "home-arcmatrix", alt: "Lime green halftone abstract", source: nil, author: "Saved"),
                .init(id: "neon-3", kind: .image, label: "Grid flower", previewColorHex: 0x1840E0, secondaryColorHex: 0x4070FF, generationID: "gen-neon-signals", bundleImageName: "home-grid-flower", alt: "Electric blue pixel grid flower", source: nil, author: "Saved"),
                .init(id: "neon-4", kind: .palette, label: "Burnt amber", previewColorHex: 0xC45A22, secondaryColorHex: 0xE48244, generationID: "gen-neon-signals"),
                .init(id: "neon-5", kind: .image, label: "Aura glow", previewColorHex: 0xC06020, secondaryColorHex: 0xE89050, generationID: "gen-neon-signals", bundleImageName: "home-aura-orange", alt: "Warm orange aura gradient", source: nil, author: "Saved"),
                .init(id: "neon-6", kind: .palette, label: "Sunset clay", previewColorHex: 0xB35238, secondaryColorHex: 0xD8785A, generationID: "gen-neon-signals"),
            ]
        ),
        LibraryBoard(
            id: "street-motion-board",
            promptTitle: "Street & Motion",
            itemCount: 7,
            updatedAtLabel: "Saved today",
            generationID: "gen-street-motion",
            items: [
                .init(id: "street-1", kind: .image, label: "Orange cruiser", previewColorHex: 0xE8600A, secondaryColorHex: 0xFF9040, generationID: "gen-street-motion", bundleImageName: "home-orange-car", alt: "Classic orange car on a sunny street", source: nil, author: "Saved"),
                .init(id: "street-2", kind: .image, label: "Jump cut", previewColorHex: 0x87AECF, secondaryColorHex: 0xB0D0E8, generationID: "gen-street-motion", bundleImageName: "home-jumping", alt: "Two models jumping outdoors", source: nil, author: "Saved"),
                .init(id: "street-3", kind: .palette, label: "Volt", previewColorHex: 0xCCCC00, secondaryColorHex: 0xE8E840, generationID: "gen-street-motion"),
                .init(id: "street-4", kind: .image, label: "Neon grid", previewColorHex: 0x1A1050, secondaryColorHex: 0x3030A0, generationID: "gen-street-motion", bundleImageName: "home-neon-rays", alt: "Neon gradient rays in dark setting", source: nil, author: "Saved"),
                .init(id: "street-5", kind: .image, label: "Desert art", previewColorHex: 0xC0280A, secondaryColorHex: 0xE04020, generationID: "gen-street-motion", bundleImageName: "home-desert-art", alt: "Illustrated desert sunset", source: nil, author: "Saved"),
                .init(id: "street-6", kind: .palette, label: "Ember", previewColorHex: 0xE84010, secondaryColorHex: 0xFF6030, generationID: "gen-street-motion"),
                .init(id: "street-7", kind: .image, label: "Crimson athlete", previewColorHex: 0xA82010, secondaryColorHex: 0xD04030, generationID: "gen-street-motion", bundleImageName: "home-athlete-red", alt: "Athletic portrait on deep red gradient", source: nil, author: "Saved"),
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
            id: "field-energy-board",
            promptTitle: "Field Energy",
            itemCount: 6,
            updatedAtLabel: "Saved today",
            generationID: "gen-field-energy",
            items: [
                .init(id: "field-1", kind: .image, label: "Athletic edit", previewColorHex: 0x1E6EB0, secondaryColorHex: 0x4898D8, generationID: "gen-field-energy", bundleImageName: "dir3-athletic", alt: "Athletic fashion editorial in deep blue", source: nil, author: "Direction 3"),
                .init(id: "field-2", kind: .palette, label: "Track green", previewColorHex: 0x3A9E3A, secondaryColorHex: 0x5AB85A, generationID: "gen-field-energy"),
                .init(id: "field-3", kind: .image, label: "Aerial track", previewColorHex: 0x4A90D9, secondaryColorHex: 0x7ABCE8, generationID: "gen-field-energy", bundleImageName: "dir3-track", alt: "Aerial view of a running track", source: nil, author: "Direction 3"),
                .init(id: "field-4", kind: .image, label: "Stadium lone", previewColorHex: 0x3A9E3A, secondaryColorHex: 0x60B860, generationID: "gen-field-energy", bundleImageName: "home-stadium", alt: "Single figure in an empty stadium", source: nil, author: "Saved"),
                .init(id: "field-5", kind: .palette, label: "Sky blue", previewColorHex: 0x4A90D9, secondaryColorHex: 0x7ABCE8, generationID: "gen-field-energy"),
                .init(id: "field-6", kind: .image, label: "Open run", previewColorHex: 0x5BA8D8, secondaryColorHex: 0x8ACBE8, generationID: "gen-field-energy", bundleImageName: "home-running", alt: "Figures running across an open field", source: nil, author: "Saved"),
            ]
        ),
        LibraryBoard(
            id: "nike-editorial-board",
            promptTitle: "Nike Editorial",
            itemCount: 7,
            updatedAtLabel: "Saved today",
            generationID: "gen-nike-editorial",
            items: [
                .init(id: "nike-editorial-1", kind: .image, label: "Nike portrait", previewColorHex: 0xF3D11E, secondaryColorHex: 0xA83B25, generationID: "gen-nike-editorial", bundleImageName: "nike-editorial-1", alt: "Profile portrait with oversized Nike wordmark and bright cyan hair against a red background", source: nil, author: "Direction 5"),
                .init(id: "nike-editorial-2", kind: .image, label: "City tote", previewColorHex: 0xF3D11E, secondaryColorHex: 0x7CB6F7, generationID: "gen-nike-editorial", bundleImageName: "nike-editorial-2", alt: "Low-angle street fashion image with a sculptural yellow bag in Times Square", source: nil, author: "Direction 5"),
                .init(id: "nike-editorial-3", kind: .image, label: "Lime motion", previewColorHex: 0xE4D01D, secondaryColorHex: 0xACB4C1, generationID: "gen-nike-editorial", bundleImageName: "nike-editorial-3", alt: "Dynamic low-angle fashion shot with a neon yellow garment against a pale sky", source: nil, author: "Direction 5"),
                .init(id: "nike-editorial-4", kind: .image, label: "Typographic lockup", previewColorHex: 0xF0CE18, secondaryColorHex: 0x111111, generationID: "gen-nike-editorial", bundleImageName: "nike-editorial-4", alt: "Bold black typographic lockup on a bright yellow field", source: nil, author: "Direction 5"),
                .init(id: "nike-editorial-5", kind: .image, label: "Get Into It", previewColorHex: 0xD9DA8A, secondaryColorHex: 0xD85A23, generationID: "gen-nike-editorial", bundleImageName: "nike-editorial-5", alt: "Poster-style campaign image with GET INTO IT typography and a model in yellow activewear", source: nil, author: "Direction 5"),
                .init(id: "nike-editorial-6", kind: .image, label: "Backlit athlete", previewColorHex: 0x302818, secondaryColorHex: 0x604830, generationID: "gen-nike-editorial", bundleImageName: "home-nike-athlete", alt: "Moody backlit Nike athlete portrait", source: nil, author: "Saved"),
                .init(id: "nike-editorial-7", kind: .image, label: "Find Your Rhythm", previewColorHex: 0x905010, secondaryColorHex: 0xC07830, generationID: "gen-nike-editorial", bundleImageName: "home-nike-rhythm", alt: "Nike Find Your Rhythm editorial triptych", source: nil, author: "Saved"),
            ]
        ),
        LibraryBoard(
            id: "recipe-app-concept",
            promptTitle: "Recipe App Concept",
            itemCount: 4,
            updatedAtLabel: "Saved today",
            generationID: "gen-recipe-app-concept",
            items: [
                .init(id: "recipe-app-concept-2", kind: .image, label: "Pop orbit", previewColorHex: 0xFF7A1A, secondaryColorHex: 0xA86DFF, generationID: "gen-recipe-app-concept", bundleImageName: "recipe-app-concept-2", alt: "Playful campaign collage with objects orbiting around bold copy", source: nil, author: "Direction 4"),
                .init(id: "recipe-app-concept-3", kind: .image, label: "Tree scene", previewColorHex: 0x7BBE4E, secondaryColorHex: 0xB8D97D, generationID: "gen-recipe-app-concept", bundleImageName: "recipe-app-concept-3", alt: "Stylized outdoor tableau with figures perched in a tree", source: nil, author: "Direction 4"),
                .init(id: "recipe-app-concept-4", kind: .image, label: "Air motion", previewColorHex: 0x7198FF, secondaryColorHex: 0xF49AE1, generationID: "gen-recipe-app-concept", bundleImageName: "recipe-app-concept-4", alt: "Dynamic fashion figures suspended mid-air against a gradient sky", source: nil, author: "Direction 4"),
                .init(id: "recipe-app-concept-5", kind: .image, label: "Frisbee crew", previewColorHex: 0x7088D8, secondaryColorHex: 0xA8B8F0, generationID: "gen-recipe-app-concept", bundleImageName: "recipe-app-concept-5", alt: "Group of friends jumping for a frisbee at sunset", source: nil, author: "Direction 4"),
            ]
        ),
        LibraryBoard(
            id: "vivid-summer-board",
            promptTitle: "Vivid Summer",
            itemCount: 6,
            updatedAtLabel: "Saved today",
            generationID: "gen-vivid-summer",
            items: [
                .init(id: "vivid-1", kind: .image, label: "Orange energy", previewColorHex: 0xE07030, secondaryColorHex: 0xFF9050, generationID: "gen-vivid-summer", bundleImageName: "home-orange-fit", alt: "Joyful figure in vibrant orange outfit", source: nil, author: "Saved"),
                .init(id: "vivid-2", kind: .palette, label: "Electric blue", previewColorHex: 0x2000F0, secondaryColorHex: 0x5040FF, generationID: "gen-vivid-summer"),
                .init(id: "vivid-3", kind: .image, label: "Berry macro", previewColorHex: 0xC0426A, secondaryColorHex: 0xE06898, generationID: "gen-vivid-summer", bundleImageName: "home-raspberries", alt: "Stacked raspberries macro photography", source: nil, author: "Saved"),
                .init(id: "vivid-4", kind: .palette, label: "Lime", previewColorHex: 0x88D040, secondaryColorHex: 0xB8E878, generationID: "gen-vivid-summer"),
                .init(id: "vivid-5", kind: .palette, label: "Violet pop", previewColorHex: 0x9A10F8, secondaryColorHex: 0xC060FF, generationID: "gen-vivid-summer"),
                .init(id: "vivid-6", kind: .palette, label: "Deep magenta", previewColorHex: 0xB83268, secondaryColorHex: 0xE05898, generationID: "gen-vivid-summer"),
            ]
        ),
        LibraryBoard(
            id: "ui-controls-board",
            promptTitle: "Soft Spatial UI",
            itemCount: 1,
            updatedAtLabel: "Saved today",
            generationID: "gen-soft-spatial-ui",
            items: [
                .init(id: "ui-controls-4", kind: .image, label: "Teal gradient", previewColorHex: 0xB8E8BC, secondaryColorHex: 0x1F6B48, generationID: "gen-soft-spatial-ui", alt: "Minimal onboarding card with selected and empty states in a floating spatial layout", source: nil, author: "Draft"),
            ]
        ),
        LibraryBoard(
            id: "ui-metrics-board",
            promptTitle: "UI Metrics Lab",
            itemCount: 5,
            updatedAtLabel: "Saved today",
            generationID: "gen-ui-metrics-lab",
            items: [
                .init(id: "ui-metrics-1", kind: .image, label: "Neon banking", previewColorHex: 0xF35A22, secondaryColorHex: 0xC6FF2E, generationID: "gen-ui-metrics-lab", bundleImageName: "ui-metrics-neon-bank", alt: "High-contrast dashboard cards with neon green performance widgets and an orange banking panel", source: nil, author: "Saved"),
                .init(id: "ui-metrics-2", kind: .image, label: "Viriability", previewColorHex: 0xCF6EB7, secondaryColorHex: 0x2F1230, generationID: "gen-ui-metrics-lab", bundleImageName: "ui-metrics-viriability", alt: "Soft pink glass card showing a centered Viriability metric", source: nil, author: "Saved"),
                .init(id: "ui-metrics-3", kind: .image, label: "Charge bar", previewColorHex: 0xF24A53, secondaryColorHex: 0x111111, generationID: "gen-ui-metrics-lab", bundleImageName: "ui-metrics-energy-bar", alt: "Minimal energy progress bar interface on white and black surfaces", source: nil, author: "Saved"),
                .init(id: "ui-metrics-4", kind: .image, label: "Soft charts", previewColorHex: 0xD684D0, secondaryColorHex: 0x1F47E5, generationID: "gen-ui-metrics-lab", bundleImageName: "ui-metrics-soft-charts", alt: "Dark analytics layout with rounded line, bar, area, and bubble charts", source: nil, author: "Saved"),
                .init(id: "ui-metrics-5", kind: .image, label: "Analytics cards", previewColorHex: 0xFF7A3D, secondaryColorHex: 0xD8FF40, generationID: "gen-ui-metrics-lab", bundleImageName: "ui-metrics-analytics-cards", alt: "Grid of analytics cards with lime, powder blue, yellow, and orange panels", source: nil, author: "Saved"),
            ]
        ),
        LibraryBoard(
            id: "ui-glass-board",
            promptTitle: "Icon & Glass Studies",
            itemCount: 5,
            updatedAtLabel: "Saved today",
            generationID: "gen-ui-glass-studies",
            items: [
                .init(id: "ui-glass-1", kind: .image, label: "Home tab", previewColorHex: 0xD9DDF1, secondaryColorHex: 0x2E5BFF, generationID: "gen-ui-glass-studies", bundleImageName: "ui-glass-home-tab", alt: "Soft glassmorphism travel interface with a floating tab bar and blue home icon", source: nil, author: "Saved"),
                .init(id: "ui-glass-2", kind: .image, label: "Selector rail", previewColorHex: 0xE6E7EE, secondaryColorHex: 0x111111, generationID: "gen-ui-glass-studies", bundleImageName: "ui-glass-selector-rail", alt: "Rounded selector rail with monochrome icon tiles on a light grid background", source: nil, author: "Saved"),
                .init(id: "ui-glass-3", kind: .image, label: "Subtitly icon", previewColorHex: 0xF0ECDD, secondaryColorHex: 0x222222, generationID: "gen-ui-glass-studies", bundleImageName: "ui-glass-subtitly-icon", alt: "Minimal app icon presentation for a Subtitly wordmark on a warm cream background", source: nil, author: "Saved"),
                .init(id: "ui-glass-4", kind: .image, label: "Commerce orbit", previewColorHex: 0xF2F2F0, secondaryColorHex: 0x0E0E10, generationID: "gen-ui-glass-studies", bundleImageName: "ui-glass-commerce-orbit", alt: "Editorial commerce UI with profile photos connected by a rounded black control", source: nil, author: "Saved"),
                .init(id: "ui-glass-5", kind: .image, label: "Message composer", previewColorHex: 0xEDF0F8, secondaryColorHex: 0x66D7FF, generationID: "gen-ui-glass-studies", bundleImageName: "ui-glass-message-composer", alt: "Translucent message composer with line icons and a glowing blue send button", source: nil, author: "Saved"),
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
            id: "home-sessions-board",
            promptTitle: "Home Sessions",
            itemCount: 7,
            updatedAtLabel: "Saved today",
            generationID: "gen-home-sessions",
            items: [
                .init(id: "hs-1", kind: .image, label: "Sunny portrait", previewColorHex: 0x5CB85C, secondaryColorHex: 0x90D890, generationID: "gen-home-sessions", bundleImageName: "home-woman", alt: "Woman in sunlit outdoor portrait", source: nil, author: "Saved"),
                .init(id: "hs-2", kind: .palette, label: "Teal", previewColorHex: 0x1E8A90, secondaryColorHex: 0x40B8C0, generationID: "gen-home-sessions"),
                .init(id: "hs-3", kind: .image, label: "Hat collage", previewColorHex: 0xD8C8C0, secondaryColorHex: 0xF0E4E0, generationID: "gen-home-sessions", bundleImageName: "home-hat-collage", alt: "Colorful hat collage editorial", source: nil, author: "Saved"),
                .init(id: "hs-4", kind: .image, label: "Press hold", previewColorHex: 0x2A9FD6, secondaryColorHex: 0x60C8F0, generationID: "gen-home-sessions", bundleImageName: "home-newspaper", alt: "Person holding up NYT newspaper", source: nil, author: "Saved"),
                .init(id: "hs-5", kind: .palette, label: "Lavender", previewColorHex: 0xA890C8, secondaryColorHex: 0xC8B8E8, generationID: "gen-home-sessions"),
                .init(id: "hs-6", kind: .image, label: "Pixel portrait", previewColorHex: 0xC8B8A0, secondaryColorHex: 0xE0D4C0, generationID: "gen-home-sessions", bundleImageName: "home-pixelated", alt: "Figure in a pixelated portrait style", source: nil, author: "Saved"),
                .init(id: "hs-7", kind: .image, label: "Smiley pool", previewColorHex: 0xE8D010, secondaryColorHex: 0xFF5020, generationID: "gen-home-sessions", bundleImageName: "home-smiley-pool", alt: "Fashion editorial with smiley sweatshirt and inflatable pool", source: nil, author: "Saved"),
            ]
        ),
        LibraryBoard(
            id: "soft-light-board",
            promptTitle: "Soft & Light",
            itemCount: 8,
            updatedAtLabel: "Saved today",
            generationID: "gen-soft-light",
            items: [
                .init(id: "sl-1", kind: .image, label: "Daffodil blur", previewColorHex: 0xA8A870, secondaryColorHex: 0xD0D0A0, generationID: "gen-soft-light", bundleImageName: "home-daffodil", alt: "Blurred daffodil flower soft focus", source: nil, author: "Saved"),
                .init(id: "sl-2", kind: .palette, label: "Baby pink", previewColorHex: 0xF8C0D8, secondaryColorHex: 0xFFE0EE, generationID: "gen-soft-light"),
                .init(id: "sl-3", kind: .image, label: "Laughing", previewColorHex: 0x3DA0D8, secondaryColorHex: 0x70C8F0, generationID: "gen-soft-light", bundleImageName: "home-laughing", alt: "Friends laughing together outdoors", source: nil, author: "Saved"),
                .init(id: "sl-4", kind: .palette, label: "Butter", previewColorHex: 0xFFDB70, secondaryColorHex: 0xFFEFB0, generationID: "gen-soft-light"),
                .init(id: "sl-5", kind: .image, label: "Skyward", previewColorHex: 0x4A9EE8, secondaryColorHex: 0x80C8FF, generationID: "gen-soft-light", bundleImageName: "home-skyward", alt: "Person facing skyward in bright light", source: nil, author: "Saved"),
                .init(id: "sl-6", kind: .image, label: "Blueberries", previewColorHex: 0x5B8EC4, secondaryColorHex: 0x90B8E0, generationID: "gen-soft-light", bundleImageName: "home-blueberries", alt: "Blueberries flat lay macro", source: nil, author: "Saved"),
                .init(id: "sl-7", kind: .palette, label: "Peach", previewColorHex: 0xE89448, secondaryColorHex: 0xFFBE80, generationID: "gen-soft-light"),
                .init(id: "sl-8", kind: .palette, label: "Coral", previewColorHex: 0xFF6B6B, secondaryColorHex: 0xFF9898, generationID: "gen-soft-light"),
            ]
        ),
        LibraryBoard(
            id: "ui-studies-2-board",
            promptTitle: "UI Studies II",
            itemCount: 6,
            updatedAtLabel: "Saved today",
            generationID: "gen-ui-studies-2",
            items: [
                .init(id: "ui2-1", kind: .image, label: "Marketplace", previewColorHex: 0xF0EBE0, secondaryColorHex: 0xE07030, generationID: "gen-ui-studies-2", bundleImageName: "soft-spatial-ui-2", alt: "Floating marketplace card UI with editorial composition", source: nil, author: "Draft"),
                .init(id: "ui2-2", kind: .palette, label: "Signal red", previewColorHex: 0xE82820, secondaryColorHex: 0xFF5040, generationID: "gen-ui-studies-2"),
                .init(id: "ui2-3", kind: .image, label: "Interest picker", previewColorHex: 0xE8E4DE, secondaryColorHex: 0xC4B8A0, generationID: "gen-ui-studies-2", bundleImageName: "soft-spatial-ui-3", alt: "Circle interest picker onboarding UI", source: nil, author: "Draft"),
                .init(id: "ui2-4", kind: .palette, label: "Hot pink", previewColorHex: 0xF060C0, secondaryColorHex: 0xFF98E0, generationID: "gen-ui-studies-2"),
                .init(id: "ui2-5", kind: .palette, label: "Dusty rose", previewColorHex: 0xE8789A, secondaryColorHex: 0xFFB0C8, generationID: "gen-ui-studies-2"),
                .init(id: "ui2-6", kind: .image, label: "Gather circles", previewColorHex: 0xE0DCD6, secondaryColorHex: 0xC0B499, generationID: "gen-ui-studies-2", bundleImageName: "soft-spatial-ui-4", alt: "Gather circles onboarding UI flow", source: nil, author: "Draft"),
            ]
        ),
        LibraryBoard(
            id: "digital-studies-board",
            promptTitle: "Digital Studies",
            itemCount: 6,
            updatedAtLabel: "Saved today",
            generationID: "gen-digital-studies",
            items: [
                .init(id: "ds-1", kind: .image, label: "Elasti UI", previewColorHex: 0xC04010, secondaryColorHex: 0xE06030, generationID: "gen-digital-studies", bundleImageName: "home-elasti-ui", alt: "Elasti AI platform dark interface", source: nil, author: "Saved"),
                .init(id: "ds-2", kind: .image, label: "AyaRX app", previewColorHex: 0x4A9FD8, secondaryColorHex: 0x80C8F0, generationID: "gen-digital-studies", bundleImageName: "home-ayarx-ui", alt: "AyaRX healthcare app UI grid", source: nil, author: "Saved"),
                .init(id: "ds-3", kind: .image, label: "Whispers", previewColorHex: 0xD0C8B8, secondaryColorHex: 0xF0E8D8, generationID: "gen-digital-studies", bundleImageName: "home-whispers-ui", alt: "Whispers sequential art game circular gallery", source: nil, author: "Saved"),
                .init(id: "ds-4", kind: .image, label: "MoMA eye", previewColorHex: 0xC83838, secondaryColorHex: 0xE86060, generationID: "gen-digital-studies", bundleImageName: "home-moma-eye", alt: "MoMA close-up eye with colorful confetti dots", source: nil, author: "Saved"),
                .init(id: "ds-5", kind: .palette, label: "Acid yellow", previewColorHex: 0xD8E010, secondaryColorHex: 0xF0F840, generationID: "gen-digital-studies"),
                .init(id: "ds-6", kind: .image, label: "Halftone sun", previewColorHex: 0xE89040, secondaryColorHex: 0xFFB870, generationID: "gen-digital-studies", bundleImageName: "home-halftone", alt: "Orange halftone dot abstract art", source: nil, author: "Saved"),
            ]
        ),
        LibraryBoard(
            id: "found-works-board",
            promptTitle: "Found Works",
            itemCount: 6,
            updatedAtLabel: "Saved today",
            generationID: "gen-found-works",
            items: [
                .init(id: "fw-1", kind: .image, label: "Soft aura", previewColorHex: 0x7AAED0, secondaryColorHex: 0xB0D0E8, generationID: "gen-found-works", bundleImageName: "home-aura-blue", alt: "Soft blue and cream aura gradient", source: nil, author: "Saved"),
                .init(id: "fw-2", kind: .image, label: "Surf dots", previewColorHex: 0x5098D8, secondaryColorHex: 0x90C8F0, generationID: "gen-found-works", bundleImageName: "home-surf-dots", alt: "Surfers in ocean with playful polka dot overlay", source: nil, author: "Saved"),
                .init(id: "fw-3", kind: .palette, label: "Warm amber", previewColorHex: 0xE89030, secondaryColorHex: 0xFFB860, generationID: "gen-found-works"),
                .init(id: "fw-4", kind: .image, label: "Tulip text", previewColorHex: 0xD87090, secondaryColorHex: 0xF0A0B8, generationID: "gen-found-works", bundleImageName: "home-tulips", alt: "Pink tulips with typography text overlay", source: nil, author: "Saved"),
                .init(id: "fw-5", kind: .image, label: "Algorithm", previewColorHex: 0xC0A080, secondaryColorHex: 0xE0C8A8, generationID: "gen-found-works", bundleImageName: "home-silhouettes", alt: "Colorful illustrated algorithmic silhouettes poster", source: nil, author: "Saved"),
                .init(id: "fw-6", kind: .palette, label: "Sage mist", previewColorHex: 0x88A898, secondaryColorHex: 0xB0C8B8, generationID: "gen-found-works"),
            ]
        ),
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
