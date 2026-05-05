import Foundation

struct LibraryBoard: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let itemCount: Int
}

enum LibrarySeedData {
    static let boards: [LibraryBoard] = [
        .init(id: "spatial-ui", title: "Soft Spatial UI", subtitle: "Interface concepts", itemCount: 18),
        .init(id: "hotel-editorial", title: "Hotel Editorial", subtitle: "Photo directions", itemCount: 12),
        .init(id: "kitchen-tones", title: "Kitchen Tones", subtitle: "Color palette board", itemCount: 9),
        .init(id: "launch-story", title: "Launch Story", subtitle: "Landing page concepts", itemCount: 14),
    ]
}
