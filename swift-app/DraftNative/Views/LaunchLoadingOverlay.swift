import AVFoundation
import SwiftUI
import UIKit

/// Launch experience: bundled `FinalLogoVideo.mp4` (capstone logo animation), then fades into the app shell (`#141414`).
struct LaunchLoadingOverlay: View {
    let onComplete: () -> Void

    @State private var videoOpacity: CGFloat = 1

    var body: some View {
        ZStack {
            launchChromeBackground.ignoresSafeArea()

            Group {
                if launchVideoURL() != nil {
                    FullBleedLaunchVideoPlayer(onPlaybackEnded: handlePlaybackEnded)
                        .opacity(videoOpacity)
                } else {
                    legacyFrameFallback(onComplete: onComplete)
                }
            }
        }
    }

    private var launchChromeBackground: some View {
        ZStack {
            Color(hex: 0x141414)
            RadialGradient(
                colors: [
                    Color(hex: 0xFF9C40).opacity(0.08),
                    Color(hex: 0xE07820).opacity(0.04),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 280
            )
            .allowsHitTesting(false)
        }
    }

    private func handlePlaybackEnded() {
        withAnimation(.easeInOut(duration: 0.55)) {
            videoOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.58) {
            onComplete()
        }
    }

    @ViewBuilder
    private func legacyFrameFallback(onComplete: @escaping () -> Void) -> some View {
        ZStack {
            Color(hex: 0x141414).ignoresSafeArea()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: 0xFF9C40).opacity(0.26),
                                Color(hex: 0xE07820).opacity(0.14),
                                Color(hex: 0xC86820).opacity(0.06),
                                Color(hex: 0x904010).opacity(0.02),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: 124
                        )
                    )
                    .frame(width: 248, height: 248)
                    .blur(radius: 28)
                    .allowsHitTesting(false)

                LogoFramesAnimationView(onComplete: onComplete)
                    .frame(width: 158, height: 158)
            }
        }
    }
}

private func launchVideoURL() -> URL? {
    Bundle.main.url(forResource: "FinalLogoVideo", withExtension: "mp4")
        ?? Bundle.main.url(forResource: "LogoLaunch", withExtension: "mp4")
        ?? Bundle.main.url(forResource: "logo", withExtension: "mp4")
}

// MARK: - Full-bleed launch video

private enum LaunchChrome {
    static let background = UIColor(red: 20 / 255, green: 20 / 255, blue: 20 / 255, alpha: 1)
}

private final class PlayerContainerView: UIView {
    var playerLayer: AVPlayerLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

private struct FullBleedLaunchVideoPlayer: UIViewRepresentable {
    let onPlaybackEnded: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPlaybackEnded: onPlaybackEnded)
    }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.backgroundColor = LaunchChrome.background

        guard let url = launchVideoURL() else {
            DispatchQueue.main.async { context.coordinator.finishOnce() }
            return view
        }

        let player = AVPlayer(url: url)
        player.isMuted = true

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.backgroundColor = LaunchChrome.background.cgColor
        view.playerLayer = layer
        view.layer.addSublayer(layer)

        context.coordinator.start(player: player)
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {}

    final class Coordinator: NSObject {
        private let onPlaybackEnded: () -> Void
        private var player: AVPlayer?
        private var statusObservation: NSKeyValueObservation?
        private var endObserver: NSObjectProtocol?
        private var fallbackTimer: Timer?
        private var launchPulseTimer: Timer?
        private var didFinish = false
        private let launchPulseGenerator = UIImpactFeedbackGenerator(style: .heavy)

        init(onPlaybackEnded: @escaping () -> Void) {
            self.onPlaybackEnded = onPlaybackEnded
        }

        func start(player: AVPlayer) {
            self.player = player
            launchPulseGenerator.prepare()
            player.automaticallyWaitsToMinimizeStalling = false

            guard let item = player.currentItem else {
                finishOnce()
                return
            }

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.finishOnce()
            }

            // Fallback: dismiss after 8s in case the video never fires end notification
            fallbackTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { [weak self] _ in
                self?.finishOnce()
            }

            // Wait for item to be ready before playing so first frame isn't frozen
            statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                guard item.status == .readyToPlay else { return }
                self?.statusObservation?.invalidate()
                self?.statusObservation = nil
                Task { @MainActor in
                    player.seek(to: .zero)
                    player.play()
                    self?.schedulePulse()
                }
            }
        }

        private func schedulePulse() {
            launchPulseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.launchPulseGenerator.impactOccurred(intensity: 1.0)
                }
            }
        }

        func finishOnce() {
            guard !didFinish else { return }
            didFinish = true
            statusObservation?.invalidate()
            statusObservation = nil
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
                self.endObserver = nil
            }
            fallbackTimer?.invalidate()
            fallbackTimer = nil
            launchPulseTimer?.invalidate()
            launchPulseTimer = nil
            onPlaybackEnded()
        }

        deinit {
            statusObservation?.invalidate()
            if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
            fallbackTimer?.invalidate()
            launchPulseTimer?.invalidate()
        }
    }
}

// MARK: - Legacy PNG sequence (only if no bundled MP4)

private struct LogoFramesAnimationView: UIViewRepresentable {
    let onComplete: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onComplete: onComplete) }

    func makeUIView(context: Context) -> UIImageView {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isOpaque = false
        iv.backgroundColor = .clear
        context.coordinator.load(into: iv)
        return iv
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {}

    final class Coordinator {
        private let onComplete: () -> Void
        private var completionTimer: Timer?
        private var launchPulseTimer: Timer?
        private let launchPulseGenerator = UIImpactFeedbackGenerator(style: .heavy)

        init(onComplete: @escaping () -> Void) { self.onComplete = onComplete }

        func load(into iv: UIImageView) {
            let urls = (Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: "LogoFrames") ?? [])
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
            let frames = urls.compactMap { UIImage(contentsOfFile: $0.path) }

            guard !frames.isEmpty else {
                onComplete()
                return
            }

            iv.animationImages = frames
            iv.animationDuration = Double(frames.count) / 30.0
            iv.animationRepeatCount = 1
            iv.startAnimating()
            launchPulseGenerator.prepare()
            launchPulseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.launchPulseGenerator.impactOccurred(intensity: 1.0)
                }
            }
            scheduleCallbacks(duration: iv.animationDuration)
        }

        private func scheduleCallbacks(duration: TimeInterval) {
            completionTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                self?.onComplete()
            }
        }

        deinit {
            launchPulseTimer?.invalidate()
            completionTimer?.invalidate()
        }
    }
}
