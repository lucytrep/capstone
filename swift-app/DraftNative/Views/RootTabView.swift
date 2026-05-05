import SwiftUI

enum DraftTab: Hashable {
    case create
    case library
    case settings
}

struct RootTabView: View {
    @State private var selectedTab: DraftTab = .create

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Create", systemImage: "waveform")
                }
                .tag(DraftTab.create)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "square.grid.2x2")
                }
                .tag(DraftTab.library)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(DraftTab.settings)
        }
        .tint(Color(hex: 0xE8A87C))
    }
}
