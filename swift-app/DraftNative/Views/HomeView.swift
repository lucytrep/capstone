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
    /// Rotating prompts: first visible line is always the dictate hint, then library suggestions.
    @State private var sloganLine = ""
    @State private var sloganOpacity: Double = 0
    @State private var fixedTagOpacity: Double = 1
    /// When the rotating suggestion is visually dominant, we record it so a matching generation can retire that line.
    @State private var idlePromptPendingConsumption: String?
    let onSelectCreate: () -> Void
    let onSelectLibrary: () -> Void
    @AppStorage("draft.native.onboarding.seen") private var hasSeenOnboarding = false
    @FocusState private var composerFocused: Bool

    private let holdFeedback = UIImpactFeedbackGenerator(style: .medium)
    /// Lifts dictation copy away from the tab bar (~3rem at 16px).
    private static let instructionLiftFromNav: CGFloat = 48

    private static let pressAndHoldDictateLine = "Press and hold to dictate"

    private var idleSlogans: [String] {
        IdlePromptSuggestions.makeLines(excluding: appModel.consumedIdlePromptLines)
    }

    private var idleTaglineTaskIdentity: String {
        let consumedKey = appModel.consumedIdlePromptLines.sorted().joined(separator: "\u{1e}")
        return "\(shouldRunIdleTaglineCycle)-\(consumedKey)"
    }

    /// Rotating slogan stays readable longer; dictate line holds before advancing.
    private static let sloganHoldNanoseconds: UInt64 = 6_500_000_000
    private static let taglineFadeSeconds: Double = 0.95
    private static let fixedFadeInSeconds: Double = 0.55
    private static let fixedHoldNanoseconds: UInt64 = 1_800_000_000

    /// Shared SF Pro Rounded: hero title; prompts use a lighter weight for contrast.
    private enum DraftScreenType {
        /// ~1rem larger than prior 40pt headline.
        static let title = Font.system(size: 52, weight: .bold, design: .rounded)
        static let body = Font.system(size: 20, weight: .regular, design: .rounded)
    }

    /// ~1rem offset below safe area / stack top so “Draft” sits lower (16pt at default scale).
    private static let titleTopInset: CGFloat = 16

    private static var sloganFadeAnimation: Animation { .smooth(duration: taglineFadeSeconds) }
    private static var fixedLineFadeAnimation: Animation { .smooth(duration: fixedFadeInSeconds) }

    private var centerDisplayText: String {
        let trimmed = appModel.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if holdGestureActive || speechRecognizer.isListening {
            return trimmed.isEmpty ? "Listening" : trimmed
        }
        return ""
    }

    private var centerTextIsPlaceholder: Bool {
        let trimmed = appModel.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty && !holdGestureActive && !speechRecognizer.isListening
    }

    /// When true, run the same idle copy rotation as the legacy Expo home screen.
    private var shouldRunIdleTaglineCycle: Bool {
        hasSeenOnboarding && centerTextIsPlaceholder && !appModel.isFlowPresented
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
            .opacity(appModel.isFlowPresented ? 0 : 1)
            .animation(.easeInOut(duration: 0.45), value: appModel.isFlowPresented)
            .allowsHitTesting(!appModel.isFlowPresented)

            if !hasSeenOnboarding {
                onboardingOverlay
            }

            if appModel.isFlowPresented {
                GenerationFlowView()
                    .environmentObject(appModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appModel.isFlowPresented)
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
            appModel.startFlow(consumingIdlePromptLine: idlePromptPendingConsumption)
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
        .task(id: idleTaglineTaskIdentity) {
            guard shouldRunIdleTaglineCycle else { return }
            await runIdleTaglineCycle()
        }
        .onChange(of: sloganOpacity) { _, _ in syncIdlePromptPendingConsumption() }
        .onChange(of: fixedTagOpacity) { _, _ in syncIdlePromptPendingConsumption() }
        .onChange(of: sloganLine) { _, _ in syncIdlePromptPendingConsumption() }
    }

    private func syncIdlePromptPendingConsumption() {
        if sloganOpacity > fixedTagOpacity {
            idlePromptPendingConsumption = sloganLine
        } else {
            idlePromptPendingConsumption = nil
        }
    }

    @MainActor
    private func runIdleTaglineCycle() async {
        let lines = idleSlogans
        guard !lines.isEmpty else { return }
        var sloganIdx = 0
        sloganLine = lines[sloganIdx]

        // First thing users see: fixed dictate line, then crossfade into rotating suggestions.
        sloganOpacity = 0
        fixedTagOpacity = 1

        // Opening beat: "Press and hold to dictate" alone, then first suggestion.
        try? await Task.sleep(nanoseconds: Self.fixedHoldNanoseconds)
        guard !Task.isCancelled, shouldRunIdleTaglineCycle else { return }

        withAnimation(Self.sloganFadeAnimation) {
            fixedTagOpacity = 0
            sloganOpacity = 1
        }
        try? await Task.sleep(for: .seconds(Self.taglineFadeSeconds))
        guard !Task.isCancelled, shouldRunIdleTaglineCycle else { return }

        while !Task.isCancelled {
            guard shouldRunIdleTaglineCycle else { break }

            try? await Task.sleep(nanoseconds: Self.sloganHoldNanoseconds)
            guard !Task.isCancelled, shouldRunIdleTaglineCycle else { break }

            withAnimation(Self.sloganFadeAnimation) {
                sloganOpacity = 0
            }
            try? await Task.sleep(for: .seconds(Self.taglineFadeSeconds))
            guard !Task.isCancelled, shouldRunIdleTaglineCycle else { break }

            withAnimation(Self.fixedLineFadeAnimation) {
                fixedTagOpacity = 1
            }
            try? await Task.sleep(for: .seconds(Self.fixedFadeInSeconds))
            guard !Task.isCancelled, shouldRunIdleTaglineCycle else { break }

            try? await Task.sleep(nanoseconds: Self.fixedHoldNanoseconds)
            guard !Task.isCancelled, shouldRunIdleTaglineCycle else { break }

            let nextLines = idleSlogans
            guard !nextLines.isEmpty else { break }
            sloganIdx = (sloganIdx + 1) % nextLines.count
            sloganLine = nextLines[sloganIdx]

            withAnimation(Self.sloganFadeAnimation) {
                fixedTagOpacity = 0
                sloganOpacity = 1
            }
            try? await Task.sleep(for: .seconds(Self.taglineFadeSeconds))
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
                appModel.startFlow(consumingIdlePromptLine: idlePromptPendingConsumption)
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

    /// Smoothly interpolates through an ordered palette using a 0…1 phase.
    private func glowCycleColor(phase: Double) -> Color {
        // palette: orange → peach → sage → pale-sage → near-white → warm-peach → back
        let stops: [(r: Double, g: Double, b: Double)] = [
            (1.000, 0.482, 0.000), // FF7B00  orange
            (1.000, 0.722, 0.384), // FFB862  soft peach
            (0.737, 0.855, 0.761), // BCDAC2  sage
            (0.847, 0.937, 0.878), // D8EFE0  pale sage
            (0.996, 1.000, 1.000), // FEFFFE  near-white
            (1.000, 0.898, 0.800), // FFE5CC  warm cream
        ]
        let n = Double(stops.count)
        let scaled = phase * n
        let i = Int(scaled) % stops.count
        let j = (i + 1) % stops.count
        let t = scaled - Double(Int(scaled))
        let s = t * t * (3 - 2 * t) // smoothstep
        let a = stops[i], b = stops[j]
        return Color(
            red:   a.r + (b.r - a.r) * s,
            green: a.g + (b.g - a.g) * s,
            blue:  a.b + (b.b - a.b) * s
        )
    }

    /// Ring-shaped glow that slowly cycles through orange → sage → white.
    private var glowOval: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let idlePulse   = CGFloat(0.5 + 0.5 * sin(t * 0.85))
            let listenPulse = CGFloat(0.5 + 0.5 * sin(t * 1.4))
            let p = rippleVisualIntensity

            let opacity = (1 - p) * (0.28 + 0.48 * idlePulse) + p * (1.15 + 0.12 * listenPulse)
            let pressScale: CGFloat = 1.0 + p * 0.75
            let blurRadius: CGFloat = 36 - p * 10

            let cyclePhase = (t / 12.0).truncatingRemainder(dividingBy: 1.0)
            let haloColor  = glowCycleColor(phase: cyclePhase)
            let innerColor = glowCycleColor(phase: (cyclePhase + 0.08).truncatingRemainder(dividingBy: 1.0))
            let outerColor = glowCycleColor(phase: (cyclePhase + 0.18).truncatingRemainder(dividingBy: 1.0))

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                EllipticalGradient(
                    stops: [
                        .init(color: .clear,                                             location: 0),
                        .init(color: .clear,                                             location: 0.14),
                        .init(color: innerColor.opacity(0.35 + p * 0.40),                location: 0.30),
                        .init(color: haloColor.opacity(0.80 + p * 0.20),                 location: 0.50),
                        .init(color: innerColor.opacity(0.50 + p * 0.30),                location: 0.66),
                        .init(color: outerColor.opacity(0.14 + p * 0.26),                location: 0.84),
                        .init(color: .clear,                                             location: 1)
                    ]
                )
                .frame(width: w * 0.96, height: w * 0.92)
                .blur(radius: blurRadius)
                .opacity(Double(opacity))
                .scaleEffect(pressScale)
                .position(x: w / 2, y: h * 0.46)
            }
        }
        // Pulse lives outside the TimelineView so SwiftUI's animation engine never resets it
        .scaleEffect(glowIdlePulse ? 1.22 : 0.84)
        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: glowIdlePulse)
    }

    private var titleHeader: some View {
        Text("Draft")
            .font(DraftScreenType.title)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.top, 12 + Self.titleTopInset)
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
            if !centerTextIsPlaceholder {
                Text(centerDisplayText)
                    .font(DraftScreenType.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 56, alignment: .center)
            } else if hasSeenOnboarding {
                idleTaglineStack
            } else {
                Color.clear
                    .frame(minHeight: 88)
                    .accessibilityHidden(true)
            }

            if !speechRecognizer.errorMessage.isEmpty {
                Text(speechRecognizer.errorMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Rotating line and dictate hint share one centered slot; each forced to a single line (scales down if needed).
    private var idleTaglineStack: some View {
        ZStack {
            Text(sloganLine)
                .font(DraftScreenType.body)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .allowsTightening(true)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .opacity(sloganOpacity)
                .allowsHitTesting(false)

            Text(Self.pressAndHoldDictateLine)
                .font(DraftScreenType.body)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .allowsTightening(true)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .opacity(fixedTagOpacity)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .center)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Self.pressAndHoldDictateLine) \(sloganLine)")
    }

    private var typedFallbackSection: some View {
        VStack(spacing: 12) {
            composer

            Button {
                appModel.startFlow(consumingIdlePromptLine: idlePromptPendingConsumption)
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
                    .init(color: Color(hex: 0xFF6E00), location: 0),
                    .init(color: Color(hex: 0xFF6E00).opacity(0.92), location: 0.08),
                    .init(color: Color(hex: 0xF05500).opacity(0.72), location: 0.22),
                    .init(color: Color(hex: 0xE04400).opacity(0.48), location: 0.42),
                    .init(color: Color(hex: 0xC43200).opacity(0.26), location: 0.62),
                    .init(color: Color(hex: 0x962200).opacity(0.10), location: 0.82),
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

