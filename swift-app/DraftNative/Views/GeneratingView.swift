import SwiftUI

struct GeneratingView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ZStack {
            Color(hex: 0x111111).ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                if case .failed = appModel.generationState {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(Color(hex: 0xE8A87C))
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color(hex: 0xE8A87C))
                        .scaleEffect(1.6)
                }

                VStack(spacing: 10) {
                    Text(titleText)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(messageText)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: 0xA59B92))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                }

                if case .failed = appModel.generationState {
                    VStack(spacing: 12) {
                        Button("Try Again") {
                            Task {
                                await appModel.retryGeneration()
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button("Back Home") {
                            appModel.dismissFlow()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }

                Spacer()
            }
            .padding(28)
        }
        .task {
            guard case .generating = appModel.generationState else { return }
            await appModel.generateArtifact()
        }
    }

    private var titleText: String {
        switch appModel.generationState {
        case .failed:
            return "Generation failed"
        case .idle, .generating:
            return "Generating your artifact"
        case .ready:
            return "Ready"
        }
    }

    private var messageText: String {
        switch appModel.generationState {
        case .failed(let message):
            return message
        case .idle, .generating:
            return "This preserves the current app's dedicated generation flow while we rebuild it natively."
        case .ready:
            return "Artifact loaded."
        }
    }
}
