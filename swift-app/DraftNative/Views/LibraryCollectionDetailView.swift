import SwiftUI

struct LibraryCollectionDetailView: View {
    let collection: LibraryCollection

    private var boards: [LibraryBoard] {
        collection.boardIDs.compactMap(LibrarySeedData.board)
    }

    private var individualItems: [LibraryItem] {
        boards.flatMap { board in
            board.items.filter { $0.kind == .image }
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(collection.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(collection.description)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))

                if collection.id == "individual" {
                    if let hero = individualItems.first {
                        LibraryTile(item: hero, width: nil, height: 280, cornerRadius: 22)
                            .frame(maxWidth: .infinity)
                    }

                    if individualItems.count > 1 {
                        HStack(spacing: 12) {
                            ForEach(Array(individualItems.dropFirst().prefix(2))) { item in
                                LibraryTile(item: item, width: nil, height: 190, cornerRadius: 18)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    let remaining = Array(individualItems.dropFirst(3))
                    if !remaining.isEmpty {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(remaining) { item in
                                LibraryTile(item: item, width: nil, height: 186)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(boards) { board in
                            NavigationLink(value: board) {
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
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(22)
        }
        .background(Color(hex: 0x111111).ignoresSafeArea())
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}
