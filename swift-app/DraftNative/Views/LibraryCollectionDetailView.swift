import SwiftUI

struct LibraryCollectionDetailView: View {
    @EnvironmentObject private var appModel: AppModel
    let collectionID: String

    private var meta: LibraryCollection? {
        LibrarySeedData.collection(id: collectionID)
    }

    private var boardsForCollection: [LibraryBoard] {
        switch collectionID {
        case "latest":
            return appModel.boards
        case "individual":
            return appModel.boards.filter { $0.items.contains(where: { $0.kind == .image }) }
        default:
            guard let meta else { return [] }
            return meta.boardIDs.compactMap { bid in appModel.boards.first(where: { $0.id == bid }) }
        }
    }

    /// Hidden on the Individual gallery only (still on boards / All items).
    private static let excludedIndividualImageItemIDs: Set<String> = [
        "ui-controls-spatial-1",
        "ui-controls-spatial-2",
        "ui-controls-spatial-3",
        "ui2-1",
        "ui2-3",
    ]

    private static let excludedIndividualImageBundles: Set<String> = [
        "soft-spatial-ui-1",
        "soft-spatial-ui-2",
        "soft-spatial-ui-3",
    ]

    private var individualImageItems: [LibraryItem] {
        boardsForCollection.flatMap { board in
            board.items.filter { $0.kind == .image }
        }
        .filter { item in
            !Self.excludedIndividualImageItemIDs.contains(item.id)
                && !(item.bundleImageName.map { Self.excludedIndividualImageBundles.contains($0) } ?? false)
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(meta?.title ?? "Collection")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(meta?.description ?? "")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))

                    if collectionID == "individual" {
                        if let hero = individualImageItems.first {
                            LibraryTile(item: hero, width: nil, height: 280, cornerRadius: LibraryVisualMetrics.itemContainerCornerRadius)
                                .frame(maxWidth: .infinity)
                        }

                        if individualImageItems.count > 1 {
                            HStack(spacing: 12) {
                                ForEach(Array(individualImageItems.dropFirst().prefix(2))) { item in
                                    LibraryTile(item: item, width: nil, height: 190, cornerRadius: LibraryVisualMetrics.itemContainerCornerRadius)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }

                        let remaining = Array(individualImageItems.dropFirst(3))
                        if !remaining.isEmpty {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(remaining) { item in
                                    NavigationLink(value: LibraryRoute.item(item.id)) {
                                        LibraryTile(item: item, width: nil, height: 186)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Color.clear.frame(width: 1, height: 1).id("individualCollectionScrollBottom")
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(boardsForCollection) { board in
                                NavigationLink(value: LibraryRoute.board(board.id)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(board.promptTitle)
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundStyle(.white)
                                            Text("\(board.itemCount) items • \(board.updatedAtLabel)")
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundStyle(.white.opacity(0.62))
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    .padding(18)
                                    .background(Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: LibraryVisualMetrics.itemContainerCornerRadius, style: .continuous)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: LibraryVisualMetrics.itemContainerCornerRadius, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(22)
            }
            .onChange(of: appModel.pendingLibraryScrollIndividualViewToBottom) { _, should in
                guard should, collectionID == "individual" else { return }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(160))
                    withAnimation(.easeOut(duration: 0.35)) {
                        proxy.scrollTo("individualCollectionScrollBottom", anchor: .bottom)
                    }
                    appModel.pendingLibraryScrollIndividualViewToBottom = false
                }
            }
        }
        .background(Color(hex: 0x111111).ignoresSafeArea())
        .navigationTitle(meta?.title ?? "Collection")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}
