import Combine
import SwiftUI

struct GeneratingView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var dotPhase = 0

    private let dotTimer = Timer.publish(every: 0.55, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            if case .failed = appModel.generationState {
                Color(hex: 0x0D0D0D).ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(Color(hex: 0xE8A87C))

                    VStack(spacing: 12) {
                        Button("Try Again") {
                            Task { await appModel.retryGeneration() }
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button("Back Home") {
                            appModel.dismissFlow()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(28)
            } else {
                HStack(spacing: 6) {
                    Text("Generating")
                        .font(.system(size: 20, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))

                    HStack(spacing: 4) {
                        Circle()
                            .fill(.white.opacity(dotPhase >= 1 ? 0.88 : 0.22))
                            .frame(width: 4, height: 4)
                        Circle()
                            .fill(.white.opacity(dotPhase >= 2 ? 0.88 : 0.22))
                            .frame(width: 4, height: 4)
                    }
                    .animation(.easeInOut(duration: 0.25), value: dotPhase)
                }
            }
        }
        .onReceive(dotTimer) { _ in
            dotPhase = (dotPhase + 1) % 3
        }
    }
}
