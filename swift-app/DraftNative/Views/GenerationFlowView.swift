import SwiftUI

struct GenerationFlowView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        Group {
            switch appModel.generationState {
            case .idle, .generating, .failed:
                GeneratingView()
            case .ready:
                OutputView()
            }
        }
        .offset(y: max(0, dragOffset))
        .gesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    guard value.translation.height > 0 else { return }
                    // Rubber-band: resistance increases as you drag further
                    let raw = value.translation.height
                    dragOffset = raw * (1 - log10(1 + raw / 120) * 0.5)
                }
                .onEnded { value in
                    let shouldDismiss = value.translation.height > 130
                        || value.predictedEndTranslation.height > 260
                    if shouldDismiss {
                        withAnimation(.easeIn(duration: 0.22)) { dragOffset = UIScreen.main.bounds.height }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            appModel.dismissFlow()
                            dragOffset = 0
                        }
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }
}
