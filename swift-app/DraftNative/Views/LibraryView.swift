import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Collections")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(LibrarySeedData.collections) { collection in
                                    NavigationLink(value: collection) {
                                        CollectionCard(collection: collection)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 22)
                        }
                        .padding(.horizontal, -22)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Boards")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        LazyVStack(spacing: 16) {
                            ForEach(LibrarySeedData.boards) { board in
                                NavigationLink(value: board) {
                                    BoardCard(board: board)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(22)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Library")
            .navigationDestination(for: LibraryBoard.self) { board in
                LibraryBoardDetailView(board: board)
            }
            .navigationDestination(for: LibraryCollection.self) { collection in
                LibraryCollectionDetailView(collection: collection)
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

private struct CollectionCard: View {
    let collection: LibraryCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(collection.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(collection.subtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.74))
                .multilineTextAlignment(.leading)

            Spacer(minLength: 8)

            Text(collection.countLabel)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0xE8A87C))
        }
        .padding(18)
        .frame(width: 228, height: 164, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x1D1A18), Color(hex: 0x3C3027)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct BoardCard: View {
    let board: LibraryBoard

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(board.promptTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(board.subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.68))
                }

                Spacer()

                Text("\(board.itemCount)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0xE8A87C))
            }

            PreviewGrid(items: board.previewItems, height: 188)

            Text(board.updatedAtLabel)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.56))
        }
        .padding(18)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

struct PreviewGrid: View {
    let items: [LibraryItem]
    let height: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let gap: CGFloat = 10
            let cellWidth = (proxy.size.width - gap) / 2
            let topHeight = height * 0.58
            let bottomHeight = height - topHeight - gap

            VStack(spacing: gap) {
                HStack(spacing: gap) {
                    LibraryTile(item: items[safe: 0], width: cellWidth, height: topHeight)
                    LibraryTile(item: items[safe: 1], width: cellWidth, height: topHeight)
                }

                HStack(spacing: gap) {
                    LibraryTile(item: items[safe: 2], width: cellWidth, height: bottomHeight)
                    LibraryTile(item: items[safe: 3], width: cellWidth, height: bottomHeight)
                }
            }
        }
        .frame(height: height)
    }
}

struct LibraryTile: View {
    let item: LibraryItem?
    let width: CGFloat?
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let item {
                if item.kind == .image {
                    imageLayer(item: item)
                } else {
                    paletteLayer(item: item)
                }
            } else {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.03))
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func imageLayer(item: LibraryItem) -> some View {
        if let thumbnailURL = item.thumbnailURL ?? item.imageURL {
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .overlay(Color.black.opacity(0.14))
                default:
                    gradientPlaceholder(item: item)
                }
            }
        } else {
            gradientPlaceholder(item: item)
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
            VStack(alignment: .leading, spacing: 4) {
                Text(item.label)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                if let source = item.source?.rawValue.uppercased() {
                    Text(source)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .opacity(0.72)
                }
            }
            .foregroundStyle(textColor(for: item.previewColorHex))
            .padding(12)
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
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.label)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Text(String(format: "#%06X", item.previewColorHex))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .opacity(0.78)
            }
            .foregroundStyle(textColor(for: item.previewColorHex))
            .padding(12)
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
