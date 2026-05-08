import AVFoundation
import SwiftUI

struct GeneratingView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ZStack {
            Color(hex: 0x111111).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("Draft")
                    .font(.system(size: 34, weight: .semibold, design: .default))
                    .kerning(-0.5)
                    .foregroundStyle(.white)

                Text(appModel.transcript.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.system(size: 34, weight: .regular, design: .default))
                    .kerning(-0.5)
                    .foregroundStyle(.white.opacity(0.98))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                Spacer()

                Group {
                    if case .failed = appModel.generationState {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(Color(hex: 0xE8A87C))
                    } else {
                        LoadingLogoVideo()
                            .frame(width: 220, height: 220)
                    }
                }
                .frame(maxWidth: .infinity)

                if case .failed = appModel.generationState {
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
                } else {
                    Button("Cancel") {
                        appModel.dismissFlow()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding(28)
        }
    }
}

private struct LoadingLogoVideo: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.backgroundColor = .clear

        guard let url = Bundle.main.url(forResource: "Logo", withExtension: "mov") else {
            return view
        }

        let playerItem = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .none

        let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        context.coordinator.player = queuePlayer
        context.coordinator.looper = looper
        context.coordinator.observeLoopEnd(for: playerItem)

        view.playerLayer.player = queuePlayer
        view.playerLayer.videoGravity = .resizeAspect
        queuePlayer.play()

        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        if context.coordinator.player?.timeControlStatus != .playing {
            context.coordinator.player?.play()
        }
    }

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.stopObserving()
        uiView.playerLayer.player = nil
        coordinator.looper = nil
        coordinator.player = nil
    }

    final class Coordinator {
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?
        private var observer: NSObjectProtocol?
        private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

        func observeLoopEnd(for templateItem: AVPlayerItem) {
            stopObserving()
            feedbackGenerator.prepare()
            observer = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: templateItem,
                queue: .main
            ) { [weak self] _ in
                self?.feedbackGenerator.impactOccurred(intensity: 0.65)
                self?.feedbackGenerator.prepare()
            }
        }

        func stopObserving() {
            if let observer {
                NotificationCenter.default.removeObserver(observer)
                self.observer = nil
            }
        }

        deinit {
            stopObserving()
        }
    }
}

private final class PlayerContainerView: UIView {
    let playerLayer = AVPlayerLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(playerLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
