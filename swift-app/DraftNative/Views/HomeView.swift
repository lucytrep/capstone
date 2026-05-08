import SwiftUI
import UIKit

struct HomeView: View {
    private struct Backdrop {
        let name: String
        let gradientColors: [Color]
        let micIconColor: Color
        let buttonGlowColor: Color
    }

    private static let backdrops: [Backdrop] = {
        let pinkGradient: [Color] = [Color(hex: 0x2A0620), Color(hex: 0x471129), Color(hex: 0x6B0132), Color(hex: 0xA31557), Color(hex: 0xDD2B77), Color(hex: 0xCE68A4)]
        let warmPurpleGradient: [Color] = [Color(hex: 0x4C425C), Color(hex: 0x9A5B77), Color(hex: 0xE08A6D)]
        let purpleGradient: [Color] = [Color(hex: 0x383E58), Color(hex: 0x6A567F), Color(hex: 0x8E6BC7)]
        let blueGradient: [Color] = [Color(hex: 0x3D3F59), Color(hex: 0x5E688D), Color(hex: 0x69A6B0)]
        let deepBlueGradient: [Color] = [Color(hex: 0x000E25), Color(hex: 0x08254F), Color(hex: 0x144892), Color(hex: 0x2368D4)]
        let darkGreenGradient: [Color] = [Color(hex: 0x091208), Color(hex: 0x173022), Color(hex: 0x2C5140), Color(hex: 0x4B7562)]

        return [
            Backdrop(name: "pink", gradientColors: pinkGradient, micIconColor: Color(hex: 0x4A1230), buttonGlowColor: Color(hex: 0xDD2B77)),
            Backdrop(name: "warmPurple", gradientColors: warmPurpleGradient, micIconColor: Color(hex: 0x5E3144), buttonGlowColor: Color(hex: 0xE08A6D)),
            Backdrop(name: "purple", gradientColors: purpleGradient, micIconColor: Color(hex: 0x4A4478), buttonGlowColor: Color(hex: 0x8E6BC7)),
            Backdrop(name: "blue", gradientColors: blueGradient, micIconColor: Color(hex: 0x2E5163), buttonGlowColor: Color(hex: 0x69A6B0)),
            Backdrop(name: "deepBlue", gradientColors: deepBlueGradient, micIconColor: Color(hex: 0x123B7D), buttonGlowColor: Color(hex: 0x2368D4)),
            Backdrop(name: "darkGreen", gradientColors: darkGreenGradient, micIconColor: Color(hex: 0x1E3A2D), buttonGlowColor: Color(hex: 0x4B7562))
        ]
    }()

    @EnvironmentObject private var appModel: AppModel
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var dictationButtonPulse = false
    @State private var autoGenerateTask: Task<Void, Never>?
    @State private var lastAutoSubmittedPrompt = ""
    let onSelectCreate: () -> Void
    let onSelectLibrary: () -> Void
    let backgroundGradientIndex: Int
    @AppStorage("draft.native.onboarding.seen") private var hasSeenOnboarding = false
    @State private var onboardingStep = 0
    @FocusState private var composerFocused: Bool

    private var activeGradientSetIndex: Int {
        backgroundGradientIndex % Self.backdrops.count
    }

    private var activeBackdrop: Backdrop {
        Self.backdrops[activeGradientSetIndex]
    }

    private var activeBackgroundGradient: [Color] {
        activeBackdrop.gradientColors
    }

    private var activeMicIconColor: Color {
        activeBackdrop.micIconColor
    }

    private var activeButtonGlowColor: Color {
        activeBackdrop.buttonGlowColor
    }

    private var activeButtonCoreGradient: [Color] {
        let colors = activeBackgroundGradient
        if colors.count >= 4 {
            return [colors[1], colors[2], colors[colors.count - 2], colors[colors.count - 1]]
        }
        return colors
    }

    private var promptText: String {
        let trimmed = appModel.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return "Tap to dictate, speak clearly and pause when finished"
    }

    private var showTypedFallback: Bool {
        !speechRecognizer.canUseVoice
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                headerCard
                Spacer()
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

            dictationButton
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .offset(y: 48)

            if !hasSeenOnboarding {
                onboardingOverlay
            }
        }
        .task {
            await speechRecognizer.requestPermissions()
            if !dictationButtonPulse {
                dictationButtonPulse = true
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

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: activeBackgroundGradient,
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 1.05)
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.white.opacity(0.11),
                    Color(hex: 0xF3A9C7, opacity: 0.08),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.08),
                startRadius: 20,
                endRadius: 520
            )
            .ignoresSafeArea()

            HalftoneRingBackdrop(
                glowColor: activeButtonGlowColor,
                isListening: speechRecognizer.isListening
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.08),
                    Color.clear,
                    Color(hex: 0x4A1230).opacity(0.16)
                ],
                startPoint: UnitPoint(x: 0.2, y: 0),
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Draft")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .kerning(-0.5)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 0) {
                Text(promptText)
                    .font(.system(size: 34, weight: appModel.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .light : .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(appModel.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.88 : 0.98))
                    .kerning(-0.5)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    .frame(minHeight: 112, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            composer

            if showTypedFallback {
                Button {
                    appModel.startFlow()
                } label: {
                    Text("Generate from text")
                        .padding(.horizontal, 18)
                }
                .buttonStyle(PrimaryButtonStyle())
                .opacity(appModel.canGenerate ? 1 : 0.45)
                .disabled(!appModel.canGenerate)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        .frame(minHeight: showTypedFallback ? 120 : 1, maxHeight: showTypedFallback ? 120 : 1)
        .opacity(showTypedFallback ? 1 : 0.01)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(showTypedFallback ? 0.08 : 0.001))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(showTypedFallback ? 0.16 : 0.001), lineWidth: 1)
                )
        )
        .padding(.top, 12)
    }

    private var dictationButton: some View {
        Button {
            Task {
                if !hasSeenOnboarding { return }
                await speechRecognizer.toggleListening(seedTranscript: appModel.transcript)
            }
        } label: {
            Image(systemName: "waveform")
                .font(.system(size: 72, weight: .medium))
                .foregroundStyle(.white.opacity(speechRecognizer.isListening ? 1.0 : 0.75))
                .symbolEffect(.variableColor.iterative.reversing, isActive: speechRecognizer.isListening)
                .shadow(color: activeButtonGlowColor.opacity(speechRecognizer.isListening ? 0.9 : 0.5), radius: 20, x: 0, y: 0)
                .scaleEffect(buttonScale)
                .animation(buttonPulseAnimation, value: speechRecognizer.isListening)
                .animation(buttonPulseAnimation, value: dictationButtonPulse)
        }
        .buttonStyle(DictationPressButtonStyle())
    }

    private var buttonScale: CGFloat {
        if speechRecognizer.isListening {
            return 0.965
        }

        return dictationButtonPulse ? 1.03 : 0.985
    }

    private var buttonPulseAnimation: Animation {
        .easeInOut(duration: speechRecognizer.isListening ? 0.78 : 1.4).repeatForever(autoreverses: true)
    }

    private var onboardingOverlay: some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                Text(onboardingStep == 0 ? "Welcome to Draft" : "How it works")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))

                Text(onboardingStep == 0 ? "Speak the direction you want to explore" : "We turn your prompt into visual directions you can compare")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(onboardingStep == 0
                     ? "Describe a moodboard, palette, UI direction, or image concept, then tap the mic to start generating."
                     : "Use the library to review boards, open details, and compare multiple routes before choosing what to keep.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .lineSpacing(4)

                HStack(spacing: 8) {
                    onboardingDot(active: onboardingStep == 0)
                    onboardingDot(active: onboardingStep == 1)
                }
                .padding(.top, 2)

                HStack {
                    Button("Skip") {
                        hasSeenOnboarding = true
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))

                    Spacer()

                    Button(onboardingStep == 0 ? "Next" : "Got it") {
                        if onboardingStep == 0 {
                            onboardingStep = 1
                        } else {
                            hasSeenOnboarding = true
                        }
                    }
                    .padding(.horizontal, 4)
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
            .background(Color(hex: 0x83365F, opacity: 0.92))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 24)
        }
    }

    private func onboardingDot(active: Bool) -> some View {
        Capsule(style: .continuous)
            .fill(active ? Color.white : Color.white.opacity(0.32))
            .frame(width: active ? 18 : 8, height: 8)
    }
}

private struct DictationPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .saturation(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

private struct HalftoneRingBackdrop: View {
    let glowColor: Color
    let isListening: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            Canvas { context, size in
                draw(context: context, size: size, time: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
        .blur(radius: 14)
        .allowsHitTesting(false)
    }

    private func draw(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let cx = size.width / 2
        let cy = size.height / 2 + 48
        let minDim = min(size.width, size.height)

        var gr: CGFloat = 1, gg: CGFloat = 0.4, gb: CGFloat = 0.6
        UIColor(glowColor).getRed(&gr, green: &gg, blue: &gb, alpha: nil)

        // Ring geometry — wider band so peak dots are larger and more prominent
        let outerR: CGFloat = minDim * 0.82
        let peakR:  CGFloat = minDim * 0.52
        let halfW:  CGFloat = (outerR - peakR) * 1.55

        // Expand outward / contract inward — large amplitude so motion is clearly visible
        let speed: Double = isListening ? 2.4 : 1.1
        // Apply cubic ease to the sin wave so motion lingers at the extremes
        let raw = CGFloat(sin(time * speed))          // -1…+1 linear
        let t = (raw + 1) / 2                         // 0…1
        let eased = t * t * (3 - 2 * t)              // smoothstep
        let expand = eased * 2 - 1                    // back to -1…+1, eased
        let animPeak = peakR * (1 + expand * 0.30)
        let animHalfW = halfW * (1 + expand * 0.16)

        let spacing: CGFloat = 4.5
        var x: CGFloat = 0
        while x <= size.width {
            var y: CGFloat = 0
            while y <= size.height {
                let dx = x - cx
                let dy = y - cy
                let dist = (dx * dx + dy * dy).squareRoot()

                // Linear falloff (not squared) — softer, more gradual transition
                let ringT  = max(0, 1 - abs(dist - animPeak) / animHalfW)
                let centerT = max(0, 1 - dist / (animPeak * 0.72)) * 0.45
                let brightness = max(ringT, centerT)
                guard brightness > 0.02 else { y += spacing; continue }

                let angle = atan2(Double(dy), Double(dx))
                let topness = CGFloat(-sin(angle) * 0.5 + 0.5)
                let r = gr * topness + 1.0 * (1 - topness)
                let g = gg * topness + 1.0 * (1 - topness)
                let b = gb * topness + 1.0 * (1 - topness)

                // Dot size + opacity both scale with brightness for smooth fade
                let dotR = spacing * 0.34 * brightness
                guard dotR >= 0.2 else { y += spacing; continue }

                let rect = CGRect(x: Double(x) - dotR, y: Double(y) - dotR,
                                  width: dotR * 2, height: dotR * 2)
                context.fill(Path(ellipseIn: rect),
                             with: .color(Color(red: Double(r), green: Double(g), blue: Double(b))
                                .opacity(Double(brightness) * 0.88)))

                y += spacing
            }
            x += spacing
        }
    }
}
