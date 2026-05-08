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

                if showLaunchOverlay {
                    LaunchLoadingOverlay {
                        withAnimation(.easeOut(duration: 0.5)) {
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
