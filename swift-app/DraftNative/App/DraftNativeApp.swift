import SwiftUI

@main
struct DraftNativeApp: App {
    @StateObject private var appModel = AppModel()
    @State private var showLaunchOverlay = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootTabView()
                    .environmentObject(appModel)
                    .allowsHitTesting(!showLaunchOverlay)

                if showLaunchOverlay {
                    LaunchLoadingOverlay {
                        withAnimation(.easeInOut(duration: 0.7)) {
                            showLaunchOverlay = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
        }
    }
}
