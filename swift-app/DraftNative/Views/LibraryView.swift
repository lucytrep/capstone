import SwiftUI
import UIKit

enum LibraryContentTab {
    case drafts, allItems
}

enum LibraryRoute: Hashable {
    case board(String)
    case item(String)
    case settings
    case collection(String)
}

struct LibraryView: View {
    @EnvironmentObject private var appModel: AppModel
    let onSelectCreate: () -> Void
    let onSelectLibrary: () -> Void

    @State private var contentTab: LibraryContentTab = .allItems
    @State private var haptic = UIImpactFeedbackGenerator(style: .light)
    @State private var navPath = NavigationPath()

    private struct MasonryEntry: Identifiable {
        let item: LibraryItem
        let index: Int
        let height: CGFloat

        var id: String { item.id }
    }

    private var allItems: [LibraryItem] {
        let items = deduplicateLibraryItems(appModel.boards.flatMap(\.items))
        let uiItems = items.filter(isUIItem)
        let paletteLike = items.filter { !isUIItem($0) && isPaletteLike($0) }
        let photoItems = prioritizeTopLibraryPhotos(items.filter { !isUIItem($0) && !isPaletteLike($0) })

        let interleaved = interleavePaletteLikeWithPhotos(
            paletteLike: paletteLike,
            photos: photoItems,
            leadPhotoCount: 2
        )

        var mixed: [LibraryItem] = []
        mixed.reserveCapacity(interleaved.count + uiItems.count)

        var uiIndex = 0
        var otherIndex = 0

        while otherIndex < interleaved.count || uiIndex < uiItems.count {
            for _ in 0..<2 where otherIndex < interleaved.count {
                mixed.append(interleaved[otherIndex])
                otherIndex += 1
            }

            if uiIndex < uiItems.count {
                mixed.append(uiItems[uiIndex])
                uiIndex += 1
            }
        }

        return mixed.filter { item in
            guard !Self.suppressedLibraryItemIDs.contains(item.id) else { return false }
            if let b = item.bundleImageName, Self.suppressedLibraryBundles.contains(b) { return false }
            return true
        }
    }

    /// Items removed from All items / detail carousel (e.g. deprecated seed assets).
    private static let suppressedLibraryItemIDs: Set<String> = [
        "ui-controls-spatial-1",
        "local-home-09-004",
    ]

    private static let suppressedLibraryBundles: Set<String> = [
        "soft-spatial-ui-1",
        "image_outdoor_selfie",
    ]

    private func isUIItem(_ item: LibraryItem) -> Bool {
        item.id.hasPrefix("ui-") || item.generationID.hasPrefix("gen-ui-")
    }

    private func isPaletteLike(_ item: LibraryItem) -> Bool {
        if item.kind == .palette { return true }
        if item.kind == .image, let b = item.bundleImageName, b.hasPrefix("color_") { return true }
        return false
    }

    /// Orange cruiser and sandstone portal first so the masonry top row matches the library reference;
    /// pushes the similar “figure in open desert” shot later to avoid a repetitive hero row.
    /// Locally bundled imports (`gen-local-*`) are spliced in right after those two heroes so newly added
    /// gallery imagery (e.g. Pinterest garden studies) appears at the top of All items instead of after
    /// every seeded board.
    private func prioritizeTopLibraryPhotos(_ photos: [LibraryItem]) -> [LibraryItem] {
        let pinterestLocalGen = "gen-local-home-imagery-pinterest"
        let localGenPrefix = "gen-local-"
        // Skip the near-white Pinterest swatch so the top of All items stays color-rich.
        let skipBundles: Set<String> = ["image_pinterest_soft_blank_field"]

        var pinterestOrdered: [LibraryItem] = []
        var otherLocalOrdered: [LibraryItem] = []
        var seenLocal = Set<String>()
        for item in photos where item.generationID.hasPrefix(localGenPrefix) {
            guard seenLocal.insert(item.id).inserted else { continue }
            if let b = item.bundleImageName, skipBundles.contains(b) { continue }
            if item.generationID == pinterestLocalGen {
                pinterestOrdered.append(item)
            } else {
                otherLocalOrdered.append(item)
            }
        }
        let promotedLocal = pinterestOrdered + otherLocalOrdered
        let promotedIDs = Set(promotedLocal.map(\.id))
        let pool = photos.filter { !promotedIDs.contains($0.id) }

        // `desert-dreams-2` (the Mirage runway sunset walker) joins the hero row alongside
        // the orange car and sandstone portal so the page opens with three on-tone images.
        let leadBundles = ["home-orange-car", "desert-dreams-1", "desert-dreams-2"]

        var lead: [LibraryItem] = []
        var consumed = Set<String>()
        for bundle in leadBundles {
            guard let item = pool.first(where: { $0.bundleImageName == bundle }) else { continue }
            lead.append(item)
            consumed.insert(item.id)
        }

        let middle = pool.filter { !consumed.contains($0.id) }
        let curated = lead + middle
        let heroCount = min(leadBundles.count, curated.count)
        return Array(curated.prefix(heroCount)) + promotedLocal + Array(curated.dropFirst(heroCount))
    }

    /// `leadPhotoCount` keeps the first N photos back-to-back (after `prioritizeTopLibraryPhotos`) so hero tiles
    /// aren’t split by a swatch in the masonry top row.
    private func interleavePaletteLikeWithPhotos(
        paletteLike: [LibraryItem],
        photos: [LibraryItem],
        leadPhotoCount: Int = 0
    ) -> [LibraryItem] {
        var result: [LibraryItem] = []
        result.reserveCapacity(paletteLike.count + photos.count)
        var p = 0
        var s = 0
        while p < leadPhotoCount, p < photos.count {
            result.append(photos[p])
            p += 1
        }
        var preferPhoto = false
        while p < photos.count || s < paletteLike.count {
            if preferPhoto, p < photos.count {
                result.append(photos[p])
                p += 1
            } else if !preferPhoto, s < paletteLike.count {
                result.append(paletteLike[s])
                s += 1
            } else if p < photos.count {
                result.append(photos[p])
                p += 1
            } else if s < paletteLike.count {
                result.append(paletteLike[s])
                s += 1
            }
            preferPhoto.toggle()
        }
        return result
    }

    private func deduplicateLibraryItems(_ items: [LibraryItem]) -> [LibraryItem] {
        var result: [LibraryItem] = []
        var seenIDs = Set<String>()
        var seenVisual = Set<String>()
        for item in items {
            if seenIDs.contains(item.id) { continue }
            if let sig = visualDuplicateSignature(for: item), seenVisual.contains(sig) { continue }
            result.append(item)
            seenIDs.insert(item.id)
            if let sig = visualDuplicateSignature(for: item) {
                seenVisual.insert(sig)
            }
        }
        return result
    }

    /// Maps distinct asset names that are crops or exports of the same campaign photo to one key,
    /// so “Yellow Editorial Exports” does not repeat the Nike Editorial board in All items.
    private static let bundleCanonicalVisualGroup: [String: String] = [
        // Same jumping-group photo used on two seeded boards under different asset names.
        "recipe-app-concept-5": "jumping-group-outdoor",
        "home-jumping": "jumping-group-outdoor",
        "nike-editorial-1": "yellow-editorial-portrait",
        "image_headmark_portrait": "yellow-editorial-portrait",
        "nike-editorial-2": "yellow-editorial-city-tote",
        "image_city_tote_crop": "yellow-editorial-city-tote",
        "image_city_tote_frame": "yellow-editorial-city-tote",
        "nike-editorial-3": "yellow-editorial-lime-motion",
        "image_lime_motion_crop": "yellow-editorial-lime-motion",
        "image_lime_motion_square": "yellow-editorial-lime-motion",
        "nike-editorial-4": "yellow-editorial-wordmark",
        "image_bold_wordmark": "yellow-editorial-wordmark",
        "image_wordmark_square": "yellow-editorial-wordmark",
        "nike-editorial-5": "yellow-editorial-get-into-it",
        "image_get_into_it_poster": "yellow-editorial-get-into-it",
        "image_get_into_it_cover": "yellow-editorial-get-into-it",
    ]

    private func visualDuplicateSignature(for item: LibraryItem) -> String? {
        switch item.kind {
        case .palette:
            return nil
        case .image:
            if let b = item.bundleImageName, !b.isEmpty {
                if let group = Self.bundleCanonicalVisualGroup[b] {
                    return "vis:\(group)"
                }
                return "bundle:\(b)"
            }
            let raw = item.imageURL ?? item.thumbnailURL
            guard let url = raw else { return nil }
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.query = nil
            let normalized = components?.url?.absoluteString ?? url.absoluteString
            guard !normalized.isEmpty else { return nil }
            return "url:\(normalized)"
        }
    }

    private func masonryHeight(index: Int) -> CGFloat {
        let heights: [CGFloat] = [190, 120, 230, 145, 175, 105, 215, 160, 135, 250, 115, 195]
        return heights[index % heights.count]
    }

    private var masonryColumns: (left: [MasonryEntry], right: [MasonryEntry]) {
        var left: [MasonryEntry] = []
        var right: [MasonryEntry] = []
        var leftHeight: CGFloat = 0
        var rightHeight: CGFloat = 0
        let columnSpacing: CGFloat = 10

        for (index, item) in allItems.enumerated() {
            let entry = MasonryEntry(item: item, index: index, height: masonryHeight(index: index))

            if leftHeight <= rightHeight {
                left.append(entry)
                leftHeight += entry.height + columnSpacing
            } else {
                right.append(entry)
                rightHeight += entry.height + columnSpacing
            }
        }

        return (left, right)
    }

    /// Top bar lives in `safeAreaInset` so its height stays compact and consistent while scrolling (no tall “resting” strip).
    private var libraryTopBar: some View {
        HStack(alignment: .center) {
            Button {
                haptic.impactOccurred()
                haptic.prepare()
                onSelectCreate()
            } label: {
                Image("logo-dmark")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 25)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 18) {
                Button {
                    haptic.impactOccurred()
                    haptic.prepare()
                    contentTab = .drafts
                } label: {
                    Text("Drafts")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(contentTab == .drafts ? 1 : 0.38))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    haptic.impactOccurred()
                    haptic.prepare()
                    contentTab = .allItems
                } label: {
                    Text("All items")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(contentTab == .allItems ? 1 : 0.38))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 6)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                haptic.impactOccurred()
                haptic.prepare()
                navPath.append(LibraryRoute.settings)
            } label: {
                Image("icon-user")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 28)
        .padding(.top, 10)
        // Extra bottom inset so total bar height matches the looser pre–safeAreaInset “resting” strip.
        .padding(.bottom, 18)
        .background(Color(hex: 0x141414))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack(path: $navPath) {
                ScrollViewReader { proxy in
                    ScrollView {
                        Group {
                            if contentTab == .allItems {
                                allItemsGrid
                                Color.clear.frame(width: 1, height: 1).id("libraryAllItemsScrollBottom")
                            } else {
                                draftsContent
                                Color.clear.frame(width: 1, height: 1).id("libraryDraftsScrollBottom")
                            }
                        }
                    }
                    .onChange(of: appModel.pendingLibrarySelectDraftsTab) { _, should in
                        guard should else { return }
                        contentTab = .drafts
                        appModel.pendingLibrarySelectDraftsTab = false
                    }
                    .onChange(of: appModel.pendingLibraryScrollDraftsToBottom) { _, should in
                        guard should, contentTab == .drafts else { return }
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(120))
                            withAnimation(.easeOut(duration: 0.35)) {
                                proxy.scrollTo("libraryDraftsScrollBottom", anchor: .bottom)
                            }
                            appModel.pendingLibraryScrollDraftsToBottom = false
                        }
                    }
                    .onChange(of: appModel.pendingLibraryScrollAllItemsToBottom) { _, should in
                        guard should else { return }
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(120))
                            if contentTab == .allItems {
                                withAnimation(.easeOut(duration: 0.35)) {
                                    proxy.scrollTo("libraryAllItemsScrollBottom", anchor: .bottom)
                                }
                                appModel.pendingLibraryScrollAllItemsToBottom = false
                            }
                        }
                    }
                    .onChange(of: contentTab) { _, tab in
                        guard tab == .allItems, appModel.pendingLibraryScrollAllItemsToBottom else { return }
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(80))
                            withAnimation(.easeOut(duration: 0.35)) {
                                proxy.scrollTo("libraryAllItemsScrollBottom", anchor: .bottom)
                            }
                            appModel.pendingLibraryScrollAllItemsToBottom = false
                        }
                    }
                }
                // Keeps the bar height stable and compact (nav-style) instead of a tall resting block above the scroll.
                .safeAreaInset(edge: .top, spacing: 0) {
                    libraryTopBar
                }
                .background(Color(hex: 0x141414).ignoresSafeArea())
                .navigationBarHidden(true)
                .navigationDestination(for: LibraryRoute.self) { route in
                    switch route {
                    case .board(let id):
                        LibraryBoardDetailView(boardID: id)
                    case .item(let id):
                        LibraryItemDetailView(items: allItems, selectedItemID: id)
                    case .settings:
                        SettingsView()
                    case .collection(let id):
                        LibraryCollectionDetailView(collectionID: id)
                    }
                }
            }
            .preferredColorScheme(.dark)
            .onAppear { haptic.prepare() }

            if navPath.isEmpty {
                if contentTab == .allItems {
                    VStack(spacing: 0) {
                        Spacer()
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: Color(hex: 0x141414).opacity(0.08), location: 0.42),
                                .init(color: Color(hex: 0x141414).opacity(0.38), location: 0.68),
                                .init(color: Color(hex: 0x141414).opacity(0.82), location: 0.9),
                                .init(color: Color(hex: 0x141414), location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
                }

                libraryBottomNav
            }
        }
    }

    private var allItemsGrid: some View {
        let columns = masonryColumns

        return HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 10) {
                ForEach(columns.left) { entry in
                    NavigationLink(value: LibraryRoute.item(entry.item.id)) {
                        ItemGridTile(item: entry.item, height: entry.height)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                ForEach(columns.right) { entry in
                    NavigationLink(value: LibraryRoute.item(entry.item.id)) {
                        ItemGridTile(item: entry.item, height: entry.height)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.top, 20)
        .padding(.bottom, 140)
    }

    private let draftColumns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
    ]

    private var draftsContent: some View {
        LazyVGrid(columns: draftColumns, spacing: 4) {
            ForEach(appModel.boards) { board in
                NavigationLink(value: LibraryRoute.board(board.id)) {
                    VStack(alignment: .leading, spacing: 6) {
                        BoardVCard(board: board)
                        Text(board.promptTitle)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.88))
                            .lineLimit(1)
                            .padding(.bottom, 8)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if board.id.hasPrefix("user-saved-") {
                        Button(role: .destructive) {
                            appModel.removeUserSavedBoard(id: board.id)
                        } label: {
                            Label("Remove from library", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 14)
        .padding(.bottom, 140)
    }

    private var libraryBottomNav: some View {
        AppBottomNav(
            selectedTab: .library,
            variant: .default,
            onSelectCreate: onSelectCreate,
            onSelectLibrary: onSelectLibrary
        )
        .padding(.bottom, 24)
    }
}

// Horizontal scroll card — elongated portrait card per board
private struct BoardHCard: View {
    let board: LibraryBoard

    private let cardWidth: CGFloat = 170

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            PreviewGrid(items: board.previewItems, height: 170 * 0.85)
                .frame(width: cardWidth)
                .clipShape(RoundedRectangle(cornerRadius: LibraryVisualMetrics.itemContainerCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: LibraryVisualMetrics.itemContainerCornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(board.promptTitle)
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(board.itemCount) items")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .frame(width: cardWidth)
    }
}

// Full-width vertical card for the Drafts grid — 2×2 photo collage with tighter corners than board detail.
private struct BoardVCard: View {
    let board: LibraryBoard

    private let corner = LibraryVisualMetrics.draftsBoardShellCornerRadius
    private let gap: CGFloat = 6

    var body: some View {
        let items = board.previewItems

        Color(hex: 0x141414)
            .aspectRatio(3.0/4.0, contentMode: .fit)
            .overlay(
                GeometryReader { geo in
                    let cellW = (geo.size.width - gap) / 2
                    let cellH = (geo.size.height - gap) / 2

                    VStack(spacing: gap) {
                        HStack(spacing: gap) {
                            BoardGridCell(item: items[safe: 0], width: cellW, height: cellH)
                                .id("\(board.id)-draft-0-\(items[safe: 0]?.id ?? "nil")")
                            BoardGridCell(item: items[safe: 1], width: cellW, height: cellH)
                                .id("\(board.id)-draft-1-\(items[safe: 1]?.id ?? "nil")")
                        }
                        HStack(spacing: gap) {
                            BoardGridCell(item: items[safe: 2], width: cellW, height: cellH)
                                .id("\(board.id)-draft-2-\(items[safe: 2]?.id ?? "nil")")
                            BoardGridCell(item: items[safe: 3], width: cellW, height: cellH)
                                .id("\(board.id)-draft-3-\(items[safe: 3]?.id ?? "nil")")
                        }
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            .frame(maxWidth: .infinity)
    }
}

// Plain photo cell for the Drafts grid collage.
private struct BoardGridCell: View {
    let item: LibraryItem?
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        LibraryTile(
            item: item,
            width: width,
            height: height,
            compactPreview: true,
            cornerRadius: LibraryVisualMetrics.draftsBoardCellCornerRadius,
            showsEdgeStroke: false
        )
    }
}

// Individual item tile for the masonry grid
private struct ItemGridTile: View {
    let item: LibraryItem
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            LibraryTile(item: item, width: geo.size.width, height: height, cornerRadius: LibraryVisualMetrics.itemContainerCornerRadius)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LibraryVisualMetrics.itemContainerCornerRadius, style: .continuous)
                .fill(Color(hex: item.previewColorHex).opacity(0.32))
                .blur(radius: 14)
                .offset(y: 4)
        )
    }
}

// MARK: - Shared tile views (also used in LibraryBoardDetailView)

struct PreviewGrid: View {
    let items: [LibraryItem]
    let height: CGFloat
    /// Corner radius for mini tiles inside the preview (defaults to masonry/board card radius).
    var cellCornerRadius: CGFloat = LibraryVisualMetrics.itemContainerCornerRadius

    var body: some View {
        GeometryReader { proxy in
            let gap: CGFloat = 6
            let fullWidth = proxy.size.width
            // Subtract the 2 gaps between 3 rows so tiles fill the full height exactly
            let tilePool = height - gap * 2

            VStack(spacing: gap) {
                LibraryTile(item: items[safe: 0], width: fullWidth, height: tilePool * (37.0 / 84.0), compactPreview: true, cornerRadius: cellCornerRadius)
                    .id("preview-row0-\(items[safe: 0]?.id ?? "nil")")

                HStack(spacing: gap) {
                    LibraryTile(item: items[safe: 1], width: fullWidth * 0.57, height: tilePool * (29.0 / 84.0), compactPreview: true, cornerRadius: cellCornerRadius)
                        .id("preview-row1a-\(items[safe: 1]?.id ?? "nil")")
                    LibraryTile(item: items[safe: 2], width: fullWidth * 0.40, height: tilePool * (29.0 / 84.0), compactPreview: true, cornerRadius: cellCornerRadius)
                        .id("preview-row1b-\(items[safe: 2]?.id ?? "nil")")
                }

                LibraryTile(item: items[safe: 3], width: fullWidth, height: tilePool * (18.0 / 84.0), compactPreview: true, cornerRadius: cellCornerRadius)
                    .id("preview-row2-\(items[safe: 3]?.id ?? "nil")")
            }
        }
        .frame(height: height)
    }
}

// MARK: - All items catalog chrome (teal spatial selection tile)

private func spatialSelectionCatalogHeader(item: LibraryItem, padding: CGFloat) -> some View {
    Text(item.label)
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .foregroundStyle(Color.black.opacity(0.84))
        .fixedSize(horizontal: false, vertical: true)
        .padding(padding)
}

struct LibraryTile: View {
    let item: LibraryItem?
    let width: CGFloat?
    let height: CGFloat
    var compactPreview: Bool = false
    var cornerRadius: CGFloat = LibraryVisualMetrics.itemContainerCornerRadius
    /// When false, no hairline stroke (e.g. draft board 2×2 mosaic reads as one surface).
    var showsEdgeStroke: Bool = true

    var body: some View {
        ZStack(alignment: compactPreview ? .center : .topLeading) {
            if let item {
                Group {
                    if item.kind == .image {
                        imageLayer(item: item)
                    } else {
                        paletteLayer(item: item)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.03))
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            if showsEdgeStroke {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private func imageLayer(item: LibraryItem) -> some View {
        if compactPreview && item.id == "ui-controls-3" {
            uiPickerPreview
        } else if item.id == "ui-controls-4" {
            selectionStatesGradientFill(item: item, showCatalogHeader: !compactPreview)
        } else if let name = item.bundleImageName, let uiImage = UIImage(named: name) {
            ZStack(alignment: .topLeading) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                Color.black.opacity(0.06)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topLeading) {
                if !compactPreview, item.kind == .image, shouldShowSwatchCaption(for: item) {
                    paletteSwatchCaptionStack(item: item)
                }
            }
        } else if let thumbnailURL = item.thumbnailURL ?? item.imageURL {
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    ZStack(alignment: .topLeading) {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                        Color.black.opacity(0.06)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .allowsHitTesting(false)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .topLeading) {
                        if !compactPreview, item.kind == .image, shouldShowSwatchCaption(for: item) {
                            paletteSwatchCaptionStack(item: item)
                        }
                    }
                default:
                    gradientPlaceholder(item: item)
                }
            }
        } else {
            gradientPlaceholder(item: item)
        }
    }

    /// Same notion as `isPaletteLike` in this file: flat `color_*` chips and the near-white Pinterest field tile.
    private func shouldShowSwatchCaption(for item: LibraryItem) -> Bool {
        guard let b = item.bundleImageName, !b.isEmpty else { return false }
        if b.hasPrefix("color_") { return true }
        if b == "image_pinterest_soft_blank_field" { return true }
        return false
    }

    private var swatchCaptionHexSize: CGFloat {
        if height < 118 { return 10 }
        if height < 175 { return 12 }
        return 13
    }

    private var swatchCaptionPadding: CGFloat {
        if height < 118 { return 8 }
        return min(16, height * 0.085)
    }

    /// Extra bottom inset so labels clear the tile curve, FAB, and short masonry heights.
    private var swatchCaptionBottomInset: CGFloat {
        max(swatchCaptionPadding, min(18, height * 0.11))
    }

    /// Hex-only caption for palette tiles and bundled `color_*` chips (library grid / previews).
    @ViewBuilder
    private func paletteSwatchCaptionStack(item: LibraryItem) -> some View {
        let fg = textColor(for: item.previewColorHex)
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)
            Text(String(format: "%06X", item.previewColorHex))
                .font(.system(size: swatchCaptionHexSize, weight: .semibold, design: .monospaced))
                .foregroundStyle(fg.opacity(0.95))
        }
        .padding(.top, swatchCaptionPadding)
        .padding(.horizontal, swatchCaptionPadding)
        .padding(.bottom, swatchCaptionBottomInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .shadow(color: .black.opacity(0.55), radius: 8, x: 0, y: 2)
    }

    private var uiPickerPreview: some View {
        ZStack {
            Color(hex: 0xF8F6F0)
            ZStack {
                previewCircle("M.R", color: 0x95B173, size: 20).offset(x: 0, y: -20)
                previewCircle("A.B", color: 0xD4D8DC, size: 20, darkText: true).offset(x: 18, y: -4)
                previewCircle("N.H", color: 0xA9C8E6, size: 20).offset(x: 10, y: 18)
                previewCircle("S.B", color: 0x9A7A64, size: 20).offset(x: -10, y: 18)
                previewCircle("I.V", color: 0xF6F3EC, size: 20, darkText: true).offset(x: -20, y: -4)
            }
        }
    }

    /// All-items grid: no screenshot — green wash from seed `preview` / `secondary` hexes (warmer than teal UI accents).
    private func selectionStatesGradientFill(item: LibraryItem, showCatalogHeader: Bool) -> some View {
        LinearGradient(
            colors: [
                Color(hex: item.previewColorHex),
                Color(hex: item.secondaryColorHex)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            if showCatalogHeader {
                spatialSelectionCatalogHeader(item: item, padding: 12)
            }
        }
    }

    private func previewCircle(_ text: String, color: UInt, size: CGFloat = 20, darkText: Bool = false) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: color))
                .frame(width: size, height: size)
            Text(text)
                .font(.system(size: max(3, size * 0.22), weight: .bold, design: .default))
                .foregroundStyle(darkText ? Color.black.opacity(0.7) : .white)
        }
    }

    private func gradientPlaceholder(item: LibraryItem) -> some View {
        LinearGradient(
            colors: [
                Color(hex: item.previewColorHex),
                Color(hex: item.secondaryColorHex)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            if !compactPreview, item.kind == .image, shouldShowSwatchCaption(for: item) {
                paletteSwatchCaptionStack(item: item)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func paletteLayer(item: LibraryItem) -> some View {
        LinearGradient(
            colors: [
                Color(hex: item.previewColorHex),
                Color(hex: item.secondaryColorHex)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topLeading) {
            if compactPreview {
                EmptyView()
            } else {
                paletteSwatchCaptionStack(item: item)
            }
        }
    }

    private func textColor(for hex: UInt) -> Color {
        let red = Double((hex >> 16) & 0xff) / 255
        let green = Double((hex >> 8) & 0xff) / 255
        let blue = Double(hex & 0xff) / 255
        let brightness = (red * 299 + green * 587 + blue * 114) / 1000
        return brightness > 0.72 ? Color.black.opacity(0.82) : .white
    }
}

// MARK: - Item detail

struct LibraryItemDetailView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    let items: [LibraryItem]
    let selectedItemID: String

    @State private var currentItemID: String
    @State private var showBoardPicker = false
    @State private var savedBoardName: String?
    @State private var shareSheetPayload: DraftShareSheetPayload?

    private let itemPageHaptics = UISelectionFeedbackGenerator()

    init(items: [LibraryItem], selectedItemID: String) {
        self.items = items
        self.selectedItemID = selectedItemID
        _currentItemID = State(initialValue: selectedItemID)
    }

    private var currentItem: LibraryItem? {
        items.first(where: { $0.id == currentItemID }) ?? items.first
    }

    private var currentIndexLabel: String? {
        guard let index = items.firstIndex(where: { $0.id == currentItemID }) ?? items.indices.first else { return nil }
        return "\(index + 1) of \(items.count)"
    }

    private var availableBoards: [LibraryBoard] {
        guard let currentItem else { return [] }
        return appModel.boards.filter { board in
            !board.items.contains(where: { $0.id == currentItem.id })
        }
    }

    private var swipeSpring: Animation {
        .interactiveSpring(response: 0.34, dampingFraction: 0.86, blendDuration: 0.18)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let item = currentItem {
                    detailBackdrop(item: item)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        Spacer(minLength: 20)

                        detailCanvas(availableSize: geo.size)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 0)
                    .padding(.top, 10)
                    .safeAreaInset(edge: .top) {
                        detailTopBar(item: item)
                            .padding(.horizontal, 14)
                            .padding(.top, 14)
                            .padding(.bottom, 12)
                    }
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 10) {
                            detailInfoPanel(item: item)
                                .id("info-\(currentItemID)")
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                ))
                            detailActionBar()
                                .id("actions-\(currentItemID)")
                                .transition(.opacity)
                        }
                            .padding(.horizontal, 18)
                            .padding(.top, 18)
                            .padding(.bottom, 10)
                    }
                } else {
                    Color(hex: 0x111111).ignoresSafeArea()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            itemPageHaptics.prepare()
        }
        .onChange(of: currentItemID) { _, _ in
            itemPageHaptics.selectionChanged()
            itemPageHaptics.prepare()
        }
        .sheet(isPresented: $showBoardPicker) {
            ItemBoardPickerSheet(
                boards: availableBoards,
                onSelect: { board in
                    guard let currentItem else { return }
                    appModel.addItem(currentItem, to: board.id)
                    savedBoardName = board.promptTitle
                    showBoardPicker = false
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(30)
            .presentationBackground(Color(hex: 0x1A1A1A))
        }
        .sheet(item: $shareSheetPayload) { payload in
            ActivityView(activityItems: payload.activityItems)
        }
    }

    private func detailCanvas(availableSize: CGSize) -> some View {
        let canvasHeight = min(availableSize.height * 0.62, 580)

        return TabView(selection: $currentItemID) {
            ForEach(items) { item in
                Group {
                    if item.kind == .image {
                        itemBackground(item: item, contentMode: .fit)
                    } else {
                        colorGradient(item: item)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: canvasHeight)
                .clipped()
                .tag(item.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: canvasHeight)
    }

    private func detailTopBar(item: LibraryItem) -> some View {
        HStack {
            chromeCircleButton(systemName: "chevron.left") {
                dismiss()
            }

            Spacer()

            topShareButton(item: item)
        }
    }

    private func topShareButton(item: LibraryItem) -> some View {
        Button {
            presentShareSheet(for: item)
        } label: {
            chromeCircleLabel(systemName: "square.and.arrow.up")
        }
        .buttonStyle(.plain)
    }

    private func presentShareSheet(for item: LibraryItem) {
        Task {
            let items = await LibraryShareImageFactory.activityItems(forItem: item)
            await MainActor.run {
                shareSheetPayload = DraftShareSheetPayload(activityItems: items)
            }
        }
    }

    private func chromeCircleButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            chromeCircleLabel(systemName: systemName)
        }
        .buttonStyle(.plain)
    }

    private func chromeCircleLabel(systemName: String) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 54, height: 54)

            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private func detailInfoPanel(item: LibraryItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let currentIndexLabel {
                detailChip(currentIndexLabel)
            }

            if !item.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(item.label)
                    .font(.system(size: item.kind == .image ? 26 : 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.interpolate)
            }

            if item.source != nil || item.kind == .palette {
                HStack(spacing: 10) {
                    if let source = item.source?.rawValue.uppercased() {
                        detailChip(source)
                    }

                    if item.kind == .palette {
                        detailChip(String(format: "#%06X", item.previewColorHex))
                    }
                }
            }

            if let alt = item.alt, item.kind == .image {
                Text(alt)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.interpolate)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    private func detailActionBar() -> some View {
        HStack {
            Spacer(minLength: 0)
            Button {
                showBoardPicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundStyle(.black)
                .frame(width: 196, height: 64)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white)
                )
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private func detailChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.88))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.09))
            )
    }

    @ViewBuilder
    private func detailBackdrop(item: LibraryItem) -> some View {
        Color.black
            .overlay(
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(hex: item.previewColorHex).opacity(0.14),
                        Color(hex: item.secondaryColorHex).opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .animation(swipeSpring, value: currentItemID)
    }

    @ViewBuilder
    private func itemBackground(item: LibraryItem, contentMode: ContentMode = .fill) -> some View {
        if item.id == "ui-controls-4" {
            LinearGradient(
                colors: [Color(hex: item.previewColorHex), Color(hex: item.secondaryColorHex)],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(alignment: .topLeading) {
                spatialSelectionCatalogHeader(item: item, padding: 18)
            }
        } else if let name = item.bundleImageName, let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else if let url = item.thumbnailURL ?? item.imageURL {
            AsyncImage(url: url) { phase in
                if case .success(let img) = phase {
                    img.resizable()
                        .aspectRatio(contentMode: contentMode)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else {
                    colorGradient(item: item)
                }
            }
        } else {
            colorGradient(item: item)
        }
    }

    private func colorGradient(item: LibraryItem) -> some View {
        LinearGradient(
            colors: [Color(hex: item.previewColorHex), Color(hex: item.secondaryColorHex)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func adaptiveTextColor(for hex: UInt) -> Color {
        let r = Double((hex >> 16) & 0xff) / 255
        let g = Double((hex >> 8) & 0xff) / 255
        let b = Double(hex & 0xff) / 255
        let brightness = (r * 299 + g * 587 + b * 114) / 1000
        return brightness > 0.55 ? Color.black.opacity(0.82) : .white
    }
}

private struct ItemBoardPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let boards: [LibraryBoard]
    let onSelect: (LibraryBoard) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Rely on `presentationDragIndicator(.visible)` only — a custom grabber stacked with it read as two overlapping top bars.
            Text("Collections")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.46))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 26)

            if boards.isEmpty {
                VStack(spacing: 10) {
                    Text("No other boards available")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("This item is already saved in every board.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(boards) { board in
                            Button {
                                onSelect(board)
                            } label: {
                                HStack(spacing: 14) {
                                    PreviewGrid(
                                        items: board.previewItems,
                                        height: 72,
                                        cellCornerRadius: LibraryVisualMetrics.collectionPickerPreviewTileCornerRadius
                                    )
                                        .frame(width: 72)
                                        .clipShape(
                                            UnevenRoundedRectangle(
                                                topLeadingRadius: 0,
                                                bottomLeadingRadius: LibraryVisualMetrics.collectionPickerPreviewClipCornerRadius,
                                                bottomTrailingRadius: LibraryVisualMetrics.collectionPickerPreviewClipCornerRadius,
                                                topTrailingRadius: 0,
                                                style: .continuous
                                            )
                                        )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(board.promptTitle)
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundStyle(.white)
                                            .multilineTextAlignment(.leading)
                                        Text("\(board.itemCount) item\(board.itemCount == 1 ? "" : "s")")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundStyle(.white.opacity(0.48))
                                    }

                                    Spacer()

                                    Image(systemName: "plus")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                                .padding(.horizontal, 18)
                                .frame(height: 102)
                                .background(
                                    RoundedRectangle(cornerRadius: LibraryVisualMetrics.collectionPickerBoardRowCornerRadius, style: .continuous)
                                        .fill(Color.white.opacity(0.08))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                }
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 14)
        }
        .background(Color(hex: 0x1A1A1A))
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
