import AVFoundation
import AVKit
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

private struct FullBleedLaunchVideoPlayer: UIViewControllerRepresentable {
    let onPlaybackEnded: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPlaybackEnded: onPlaybackEnded)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        controller.view.backgroundColor = LaunchChrome.background
        controller.contentOverlayView?.backgroundColor = LaunchChrome.background
        controller.allowsPictureInPicturePlayback = false

        guard let url = launchVideoURL() else {
            DispatchQueue.main.async { context.coordinator.finishOnce() }
            return controller
        }

        let player = AVPlayer(url: url)
        player.isMuted = true
        controller.player = player
        context.coordinator.start(player: player)
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    final class Coordinator: NSObject {
        private let onPlaybackEnded: () -> Void
        private var endObserver: NSObjectProtocol?
        private var launchPulseTimer: Timer?
        private var didFinish = false
        private let launchPulseGenerator = UIImpactFeedbackGenerator(style: .heavy)

        init(onPlaybackEnded: @escaping () -> Void) {
            self.onPlaybackEnded = onPlaybackEnded
        }

        func start(player: AVPlayer) {
            launchPulseGenerator.prepare()

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

            scheduleLaunchPulseHaptic()

            player.play()
        }

        /// Tactile pulse at **0.5s** into the intro video (matches product “in the hand” beat).
        private func scheduleLaunchPulseHaptic() {
            launchPulseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.launchPulseGenerator.impactOccurred(intensity: 1.0)
                }
            }
        }

        func finishOnce() {
            guard !didFinish else { return }
            didFinish = true
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
                self.endObserver = nil
            }
            launchPulseTimer?.invalidate()
            launchPulseTimer = nil
            onPlaybackEnded()
        }

        deinit {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
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
