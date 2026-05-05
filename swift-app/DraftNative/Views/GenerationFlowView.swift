import SwiftUI

struct GenerationFlowView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Group {
            switch appModel.generationState {
            case .idle, .generating, .failed:
                GeneratingView()
            case .ready:
                OutputView()
            }
        }
    }
}
