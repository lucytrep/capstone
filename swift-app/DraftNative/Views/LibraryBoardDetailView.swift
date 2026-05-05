import SwiftUI

struct LibraryBoardDetailView: View {
    let board: LibraryBoard

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(board.promptTitle)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("\(board.itemCount) items • \(board.updatedAtLabel)")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(board.items) { item in
                        LibraryTile(item: item, width: nil, height: item.kind == .palette ? 138 : 178)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(22)
        }
        .background(Color(hex: 0x111111).ignoresSafeArea())
        .navigationTitle(board.promptTitle)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}
