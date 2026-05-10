import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var glowIdlePulse = false
    @State private var holdGestureActive = false
    /// Drives ripple / idle crossfade smoothly (0…1), independent of binary gesture flags.
    @State private var rippleVisualIntensity: CGFloat = 0
    @State private var autoGenerateTask: Task<Void, Never>?
    @State private var lastAutoSubmittedPrompt = ""
    let onSelectCreate: () -> Void
    let onSelectLibrary: () -> Void
    @AppStorage("draft.native.onboarding.seen") private var hasSeenOnboarding = false
    @FocusState private var composerFocused: Bool

    private let holdFeedback = UIImpactFeedbackGenerator(style: .medium)
    /// Lifts dictation copy away from the tab bar (~3rem at 16px).
    private static let instructionLiftFromNav: CGFloat = 48

    private var centerDisplayText: String {
        let trimmed = appModel.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if holdGestureActive || speechRecognizer.isListening {
            return trimmed.isEmpty ? "Listening...." : trimmed
        }
        return "Press and hold\nto dictate"
    }

    private var centerTextIsPlaceholder: Bool {
        let trimmed = appModel.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty && !holdGestureActive && !speechRecognizer.isListening
    }

    private var showTypedFallback: Bool {
        !speechRecognizer.canUseVoice
    }

    var body: some View {
        ZStack {
            dictationBackdrop

            VStack(spacing: 0) {
                titleHeader

                Spacer(minLength: 8)
                    .layoutPriority(2)

                dictationHitArea

                Spacer(minLength: 20)
                    .layoutPriority(2)

                centerCopy
                    .padding(
                        .bottom,
                        showTypedFallback ? 4 + Self.instructionLiftFromNav : 6 + Self.instructionLiftFromNav
                    )

                if showTypedFallback {
                    typedFallbackSection
                }

                AppBottomNav(
                    selectedTab: .create,
                    variant: .default,
                    onSelectCreate: onSelectCreate,
                    onSelectLibrary: onSelectLibrary
                )
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)
            .padding(.bottom, 24)

            if !hasSeenOnboarding {
                onboardingOverlay
            }
        }
        .task {
            holdFeedback.prepare()
            await speechRecognizer.requestPermissions()
            if !glowIdlePulse {
                glowIdlePulse = true
            }
        }
        .onReceive(speechRecognizer.$transcript) { value in
            guard value != appModel.transcript else { return }
            appModel.updateTranscript(value)
        }
        .onReceive(speechRecognizer.$completedTranscriptionCount.dropFirst()) { _ in
            guard hasSeenOnboarding, !appModel.isFlowPresented else { return }

            let finalPrompt = speechRecognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !finalPrompt.isEmpty else { return }

            if finalPrompt != appModel.transcript {
                appModel.updateTranscript(finalPrompt)
            }

            lastAutoSubmittedPrompt = finalPrompt
            appModel.startFlow()
        }
        .onChange(of: appModel.transcript) { _, newValue in
            scheduleAutoGenerateIfNeeded(for: newValue)
        }
        .onChange(of: holdGestureActive) { _, holding in
            // Long ease + no overshoot: listening backdrop can track every frame without stepping.
            withAnimation(.easeInOut(duration: holding ? 0.58 : 0.82)) {
                rippleVisualIntensity = holding ? 1 : 0
            }
        }
        .fullScreenCover(isPresented: $appModel.isFlowPresented) {
            GenerationFlowView()
                .environmentObject(appModel)
        }
    }

    private func scheduleAutoGenerateIfNeeded(for value: String) {
        autoGenerateTask?.cancel()

        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lastAutoSubmittedPrompt = ""
        }

        guard showTypedFallback, hasSeenOnboarding, !speechRecognizer.isListening, !appModel.isFlowPresented else {
            return
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != lastAutoSubmittedPrompt else {
            return
        }

        autoGenerateTask = Task {
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                let latest = appModel.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard latest == trimmed, !latest.isEmpty, !appModel.isFlowPresented else { return }
                lastAutoSubmittedPrompt = latest
                appModel.startFlow()
            }
        }
    }

    private var isGlowExpanded: Bool {
        holdGestureActive || speechRecognizer.isListening
    }

    private var dictationBackdrop: some View {
        ZStack {
            Color(red: 0.055, green: 0.052, blue: 0.05)
                .ignoresSafeArea()
            glowOval
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    /// Ring-shaped warm-orange glow — dark centre, orange halo, fades to black.
    private var glowOval: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let idlePulse   = CGFloat(0.5 + 0.5 * sin(t * 0.85))
            let listenPulse = CGFloat(0.5 + 0.5 * sin(t * 1.4))
            let p = rippleVisualIntensity
            let opacity = (1 - p) * (0.82 + 0.12 * idlePulse) + p * (1.0 + 0.0 * listenPulse)

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                // Slightly wider than tall, matching reference screenshot
                EllipticalGradient(
                    stops: [
                        .init(color: .clear,                              location: 0),
                        .init(color: .clear,                              location: 0.18),
                        .init(color: Color(hex: 0xC86820).opacity(0.40),  location: 0.34),
                        .init(color: Color(hex: 0xE07820).opacity(0.85),  location: 0.52),
                        .init(color: Color(hex: 0xC86820).opacity(0.55),  location: 0.68),
                        .init(color: Color(hex: 0x904010).opacity(0.18),  location: 0.86),
                        .init(color: .clear,                              location: 1)
                    ]
                )
                .frame(width: w * 0.96, height: w * 0.92)
                .blur(radius: 36)
                .opacity(Double(opacity))
                .position(x: w / 2, y: h * 0.46)
            }
            .scaleEffect(glowIdlePulse ? 1.03 : 0.98)
            .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: glowIdlePulse)
        }
    }

    private var titleHeader: some View {
        Text("Draft")
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .accessibilityAddTraits(.isHeader)
    }

    /// Fixed-size hit target only — all glow lives in `dictationBackdrop` so layout never shifts.
    private var dictationHitArea: some View {
        Color.clear
            .frame(width: 320, height: 320)
            .contentShape(Rectangle())
            .gesture(holdToDictateGesture)
            .accessibilityLabel("Dictation")
            .accessibilityHint("Press and hold to speak your prompt")
    }

    private var holdToDictateGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard hasSeenOnboarding, speechRecognizer.canUseVoice else { return }
                guard !holdGestureActive else { return }
                holdGestureActive = true
                holdFeedback.impactOccurred(intensity: 0.9)
                holdFeedback.prepare()
                Task {
                    await speechRecognizer.beginListening(seedTranscript: appModel.transcript)
                }
            }
            .onEnded { _ in
                guard holdGestureActive else { return }
                holdGestureActive = false
                speechRecognizer.stopListening()
            }
    }

    private var centerCopy: some View {
        VStack(spacing: 10) {
            Text(centerDisplayText)
                .font(.system(size: centerTextIsPlaceholder ? 20 : 18, weight: centerTextIsPlaceholder ? .medium : .regular, design: .rounded))
                .foregroundStyle(Color.white.opacity(centerTextIsPlaceholder ? 0.95 : 0.92))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 12)
                .frame(minHeight: 56, alignment: .center)

            if !speechRecognizer.errorMessage.isEmpty {
                Text(speechRecognizer.errorMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var typedFallbackSection: some View {
        VStack(spacing: 12) {
            composer

            Button {
                appModel.startFlow()
            } label: {
                Text("Generate from text")
                    .padding(.horizontal, 18)
            }
            .buttonStyle(PrimaryButtonStyle())
            .opacity(appModel.canGenerate ? 1 : 0.45)
            .disabled(!appModel.canGenerate)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    private var composer: some View {
        TextEditor(text: Binding(
            get: { appModel.transcript },
            set: { appModel.updateTranscript($0) }
        ))
        .focused($composerFocused)
        .scrollContentBackground(.hidden)
        .foregroundStyle(.white)
        .font(.system(size: 16, weight: .regular, design: .rounded))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 120, maxHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private var onboardingOverlay: some View {
        OnboardingSwipeIntroView {
            hasSeenOnboarding = true
        }
        .transition(.opacity.combined(with: .scale(scale: 0.99)))
        .zIndex(100)
    }
}

// MARK: - Onboarding (Figma: swipe to start)

private struct OnboardingSwipeIntroView: View {
    let onComplete: () -> Void

    @State private var knobOffset: CGFloat = 0
    @State private var dragSessionBase: CGFloat = 0
    @State private var didLockDragBase = false

    private let knobSize: CGFloat = 50
    private let trackHeight: CGFloat = 56
    private let trackInnerPadding: CGFloat = 5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: 0xFF9C40), location: 0),
                    .init(color: Color(hex: 0xFF9C40).opacity(0.92), location: 0.08),
                    .init(color: Color(hex: 0xF09038).opacity(0.72), location: 0.22),
                    .init(color: Color(hex: 0xE08030).opacity(0.48), location: 0.42),
                    .init(color: Color(hex: 0xCC7228).opacity(0.26), location: 0.62),
                    .init(color: Color(hex: 0xA85820).opacity(0.10), location: 0.82),
                    .init(color: Color.black.opacity(0), location: 1)
                ]),
                center: UnitPoint(x: 0.34, y: 0.46),
                startRadius: 0,
                endRadius: 380
            )
            .blur(radius: 44)
            .ignoresSafeArea()

            GeometryReader { geo in
                let horizontalPad: CGFloat = 24
                let trackW = geo.size.width - horizontalPad * 2
                let maxKnobX = max(0, trackW - knobSize - trackInnerPadding * 2)

                VStack(alignment: .leading, spacing: 0) {
                    Spacer(minLength: 72)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome to")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))

                        Text("Think it.")
                            .font(.system(size: 40, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.top, 4)

                        Text("Say it.")
                            .font(.system(size: 40, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Draft it.")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 28)

                    Spacer(minLength: 24)

                    HStack {
                        Spacer(minLength: 0)
                        swipeTrack(trackWidth: trackW, maxKnobX: maxKnobX)
                        Spacer(minLength: 0)
                    }
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 28))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private func swipeTrack(trackWidth: CGFloat, maxKnobX: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .frame(width: trackWidth, height: trackHeight)

            Text("Start")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.95))
                .frame(width: trackWidth, height: trackHeight)
                .allowsHitTesting(false)

            HStack {
                Spacer(minLength: 0)
                Text("›››")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(.trailing, 18)
            }
            .frame(width: trackWidth, height: trackHeight)
            .allowsHitTesting(false)

            ZStack {
                Circle()
                    .fill(Color(red: 0.9, green: 0.9, blue: 0.92))
                    .frame(width: knobSize, height: knobSize)
                    .shadow(color: .black.opacity(0.28), radius: 8, x: 0, y: 4)
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.82))
            }
            .padding(.leading, trackInnerPadding)
            .offset(x: min(max(0, knobOffset), maxKnobX))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !didLockDragBase {
                            dragSessionBase = knobOffset
                            didLockDragBase = true
                        }
                        knobOffset = min(max(0, dragSessionBase + gesture.translation.width), maxKnobX)
                    }
                    .onEnded { _ in
                        didLockDragBase = false
                        let release = knobOffset
                        if release > maxKnobX * 0.52 {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onComplete()
                        } else {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                                knobOffset = 0
                            }
                        }
                    }
            )
        }
        .frame(width: trackWidth, height: trackHeight)
    }
}

