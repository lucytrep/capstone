import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(LibrarySeedData.boards) { board in
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(board.title)
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text(board.subtitle)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.7))
                                }

                                Spacer()

                                Text("\(board.itemCount)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(hex: 0xE8A87C))
                            }

                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.08),
                                            Color(hex: 0xE8A87C).opacity(0.18)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 180)
                                .overlay(alignment: .bottomLeading) {
                                    Text("React Native library board placeholder")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.75))
                                        .padding(18)
                                }
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    }
                }
                .padding(22)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Library")
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}
