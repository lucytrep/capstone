import SwiftUI
import UIKit

private enum LibraryContentTab {
    case drafts, allItems
}

private enum LibraryRoute: Hashable {
    case board(String)
    case settings
}

struct LibraryView: View {
    @EnvironmentObject private var appModel: AppModel
    let onSelectCreate: () -> Void
    let onSelectLibrary: () -> Void

    @State private var contentTab: LibraryContentTab = .allItems
    @State private var haptic = UIImpactFeedbackGenerator(style: .light)
    @State private var navPath = NavigationPath()

    private var allItems: [LibraryItem] {
        appModel.boards.flatMap { $0.items }
    }

    private func masonryHeight(index: Int) -> CGFloat {
        let heights: [CGFloat] = [190, 120, 230, 145, 175, 105, 215, 160, 135, 250, 115, 195]
        return heights[index % heights.count]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack(path: $navPath) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack {
                            Button {
                                haptic.impactOccurred()
                                haptic.prepare()
                                onSelectCreate()
                            } label: {
                                Image(systemName: "waveform")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
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
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            NavigationLink(value: LibraryRoute.settings) {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                haptic.impactOccurred()
                                haptic.prepare()
                            })
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 34)

                        if contentTab == .allItems {
                            allItemsGrid
                        } else {
                            draftsContent
                        }
                    }
                }
                .background(Color(hex: 0x141414).ignoresSafeArea())
                .navigationBarHidden(true)
                .navigationDestination(for: LibraryRoute.self) { route in
                    switch route {
                    case .board(let id):
                        LibraryBoardDetailView(boardID: id)
                    case .settings:
                        SettingsView()
                    }
                }
            }
            .preferredColorScheme(.dark)
            .onAppear { haptic.prepare() }

            if navPath.isEmpty {
                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: Color(hex: 0x141414).opacity(0.35), location: 0.30),
                            .init(color: Color(hex: 0x141414).opacity(0.72), location: 0.60),
                            .init(color: Color(hex: 0x141414), location: 0.88),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)

                libraryBottomNav
            }
        }
    }

    private var allItemsGrid: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 10) {
                ForEach(Array(allItems.enumerated()), id: \.element.id) { index, item in
                    if index % 2 == 0 {
                        ItemGridTile(item: item, height: masonryHeight(index: index))
                    }
                }
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                ForEach(Array(allItems.enumerated()), id: \.element.id) { index, item in
                    if index % 2 == 1 {
                        ItemGridTile(item: item, height: masonryHeight(index: index))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.top, 20)
        .padding(.bottom, 140)
    }

    private let draftColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var draftsContent: some View {
        LazyVGrid(columns: draftColumns, spacing: 16) {
            ForEach(appModel.boards) { board in
                NavigationLink(value: LibraryRoute.board(board.id)) {
                    BoardVCard(board: board)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 20)
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
                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
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

// Full-width vertical card for the Drafts list
private struct BoardVCard: View {
    let board: LibraryBoard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(board.promptTitle)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(board.itemCount) items")
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundStyle(.white.opacity(0.55))
            }

            PreviewGrid(items: board.previewItems, height: 160)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Individual item tile for the masonry grid, with label beneath
private struct ItemGridTile: View {
    let item: LibraryItem
    let height: CGFloat

    var body: some View {
        GeometryReader { geo in
            LibraryTile(item: item, width: geo.size.width, height: height)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shared tile views (also used in LibraryBoardDetailView)

struct PreviewGrid: View {
    let items: [LibraryItem]
    let height: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let gap: CGFloat = 6
            let fullWidth = proxy.size.width
            // Subtract the 2 gaps between 3 rows so tiles fill the full height exactly
            let tilePool = height - gap * 2

            VStack(spacing: gap) {
                LibraryTile(item: items[safe: 0], width: fullWidth, height: tilePool * (37.0 / 84.0), compactPreview: true)

                HStack(spacing: gap) {
                    LibraryTile(item: items[safe: 1], width: fullWidth * 0.57, height: tilePool * (29.0 / 84.0), compactPreview: true)
                    LibraryTile(item: items[safe: 2], width: fullWidth * 0.40, height: tilePool * (29.0 / 84.0), compactPreview: true)
                }

                LibraryTile(item: items[safe: 3], width: fullWidth, height: tilePool * (18.0 / 84.0), compactPreview: true)
            }
        }
        .frame(height: height)
    }
}

struct LibraryTile: View {
    let item: LibraryItem?
    let width: CGFloat?
    let height: CGFloat
    var compactPreview: Bool = false
    var cornerRadius: CGFloat = 2

    var body: some View {
        ZStack(alignment: compactPreview ? .center : .bottomLeading) {
            if let item {
                if item.kind == .image {
                    imageLayer(item: item)
                } else {
                    paletteLayer(item: item)
                }
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.03))
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func imageLayer(item: LibraryItem) -> some View {
        if compactPreview && item.id == "ui-controls-1" {
            uiAvatarPreview
        } else if compactPreview && item.id == "ui-controls-2" {
            uiFloatingPreview
        } else if compactPreview && item.id == "ui-controls-3" {
            uiPickerPreview
        } else if compactPreview && item.id == "ui-controls-4" {
            uiSelectionPreview
        } else if let name = item.bundleImageName, let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .overlay(Color.black.opacity(0.06))
        } else if let thumbnailURL = item.thumbnailURL ?? item.imageURL {
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .overlay(Color.black.opacity(0.06))
                default:
                    gradientPlaceholder(item: item)
                }
            }
        } else {
            gradientPlaceholder(item: item)
        }
    }

    private var uiAvatarPreview: some View {
        ZStack {
            Color(hex: 0xF8F6F0)
            HStack(spacing: -5) {
                previewCircle("M.R", color: 0x7E5C44)
                previewCircle("A.B", color: 0xF7A62C)
                previewCircle("N.H", color: 0x8043DB)
                previewCircle("S.B", color: 0x90C4BC)
                previewCircle("I.V", color: 0xBB6B5A)
            }
        }
    }

    private var uiFloatingPreview: some View {
        ZStack {
            Color(hex: 0xF8F6F0)
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    previewCircle("M.R", color: 0x7E5C44)
                    previewCircle("A.B", color: 0xF7A62C)
                    previewCircle("N.H", color: 0x8043DB)
                }
                HStack(spacing: 18) {
                    previewCircle("S.B", color: 0x90C4BC)
                    previewCircle("I.V", color: 0xBB6B5A)
                }
            }
        }
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

    private var uiSelectionPreview: some View {
        ZStack {
            Color(hex: 0xF6F4EE)
            HStack(spacing: 4) {
                previewCircle("M.R", color: 0x7E5C44, size: 18)
                previewCircle("A.B", color: 0xF7A62C, size: 14)
                previewCircle("N.H", color: 0x8043DB, size: 18)
                previewCircle("S.B", color: 0x90C4BC, size: 14)
                previewCircle("I.V", color: 0xBB6B5A, size: 18)
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
        .overlay(alignment: .bottomLeading) {
            if !compactPreview {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.label)
                        .font(.system(size: 13, weight: .bold, design: .default))
                    if let source = item.source?.rawValue.uppercased() {
                        Text(source)
                            .font(.system(size: 11, weight: .semibold, design: .default))
                            .opacity(0.72)
                    }
                }
                .foregroundStyle(textColor(for: item.previewColorHex))
                .padding(12)
            }
        }
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
        .overlay(alignment: compactPreview ? .center : .bottomLeading) {
            if compactPreview {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.label)
                        .font(.system(size: 13, weight: .bold, design: .default))
                    Text(String(format: "#%06X", item.previewColorHex))
                        .font(.system(size: 11, weight: .semibold, design: .default))
                        .opacity(0.78)
                }
                .foregroundStyle(textColor(for: item.previewColorHex))
                .padding(12)
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

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
