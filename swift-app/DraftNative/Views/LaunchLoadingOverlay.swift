import AVFoundation
import SwiftUI
import UIKit

struct LaunchLoadingOverlay: View {
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color(hex: 0x141414).ignoresSafeArea()
            IntroLogoVideo(onComplete: onComplete)
                .frame(width: 280, height: 280)
        }
    }
}

private struct IntroLogoVideo: UIViewRepresentable {
    let onComplete: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.backgroundColor = .clear

        guard let url = Bundle.main.url(forResource: "Logo", withExtension: "mov") else {
            DispatchQueue.main.async { context.coordinator.finish() }
            return view
        }

        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .pause
        context.coordinator.player = player
        context.coordinator.observeEnd(for: player.currentItem)

        // Fire haptic 0.5 s into the animation — feels synced to the motion
        context.coordinator.observeHapticBoundary(player: player)

        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect

        player.play()

        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {}

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: Coordinator) {
        coordinator.stopObserving()
        coordinator.player?.pause()
        coordinator.player = nil
        uiView.playerLayer.player = nil
    }

    final class Coordinator {
        var player: AVPlayer?
        var endObserver: NSObjectProtocol?
        var hapticObserver1: Any?
        var hapticObserver2: Any?
        let softGenerator = UIImpactFeedbackGenerator(style: .light)
        let mainGenerator = UIImpactFeedbackGenerator(style: .medium)
        private let onComplete: () -> Void
        private var didFinish = false

        init(onComplete: @escaping () -> Void) {
            self.onComplete = onComplete
        }

        func observeEnd(for item: AVPlayerItem?) {
            guard let item else { return }
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.finish()
            }
        }

        func observeHapticBoundary(player: AVPlayer) {
            softGenerator.prepare()
            mainGenerator.prepare()

            // Soft anticipation tap
            let time1 = CMTime(seconds: 0.78, preferredTimescale: 600)
            hapticObserver1 = player.addBoundaryTimeObserver(
                forTimes: [NSValue(time: time1)], queue: .main
            ) { [weak self] in
                self?.softGenerator.impactOccurred(intensity: 0.45)
            }

            // Main tap — slightly stronger, follows the motion beat
            let time2 = CMTime(seconds: 1.08, preferredTimescale: 600)
            hapticObserver2 = player.addBoundaryTimeObserver(
                forTimes: [NSValue(time: time2)], queue: .main
            ) { [weak self] in
                self?.mainGenerator.impactOccurred(intensity: 0.8)
            }
        }

        func finish() {
            guard !didFinish else { return }
            didFinish = true
            onComplete()
        }

        func stopObserving() {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
                self.endObserver = nil
            }
            if let hapticObserver1, let player {
                player.removeTimeObserver(hapticObserver1)
                self.hapticObserver1 = nil
            }
            if let hapticObserver2, let player {
                player.removeTimeObserver(hapticObserver2)
                self.hapticObserver2 = nil
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
