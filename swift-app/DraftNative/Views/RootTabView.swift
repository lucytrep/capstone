import SwiftUI
import UIKit

enum DraftTab: Hashable {
    case create
    case library
}

struct RootTabView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var selectedTab: DraftTab = .create
    // Home backdrops rotate only while the user is off the dictation page,
    // then the next backdrop is shown when they return to Create.
    @State private var homeGradientIndex = 0
    private let navFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        ZStack {
            switch selectedTab {
            case .create:
                HomeView(
                    onSelectCreate: { selectCreate() },
                    onSelectLibrary: { selectLibrary() },
                    backgroundGradientIndex: homeGradientIndex
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
        if selectedTab == .library {
            homeGradientIndex += 1
        }
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
