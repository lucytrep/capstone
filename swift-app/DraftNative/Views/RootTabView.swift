import SwiftUI
import UIKit

enum DraftTab: Hashable {
    case create
    case library
}

struct RootTabView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var selectedTab: DraftTab = .create
    private let navFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            switch selectedTab {
            case .create:
                HomeView(
                    onSelectCreate: { selectCreate() },
                    onSelectLibrary: { selectLibrary() }
                )
            case .library:
                LibraryView(
                    onSelectCreate: { selectCreate() },
                    onSelectLibrary: { selectLibrary() }
                )
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: appModel.pendingLibraryNavigation) { _, pending in
            if pending {
                appModel.pendingLibraryNavigation = false
                selectLibrary()
            }
        }
    }

    private func selectCreate() {
        guard selectedTab != .create else { return }
        navFeedbackGenerator.impactOccurred(intensity: 0.65)
        navFeedbackGenerator.prepare()
        selectedTab = .create
    }

    private func selectLibrary() {
        guard selectedTab != .library else { return }
        navFeedbackGenerator.impactOccurred(intensity: 0.65)
        navFeedbackGenerator.prepare()
        selectedTab = .library
    }
}
