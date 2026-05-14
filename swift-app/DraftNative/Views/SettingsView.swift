import SwiftUI

struct SettingsView: View {
    @AppStorage("draft.settings.autoSave")         private var autoSave         = true
    @AppStorage("draft.settings.haptics")          private var haptics          = true
    @AppStorage("draft.settings.autoSubmit")       private var autoSubmit       = true
    @AppStorage("draft.settings.noiseCancellation")private var noiseCancellation = true
    @AppStorage("draft.settings.reduceMotion")     private var reduceMotion     = false
    @AppStorage("draft.settings.analytics")        private var analytics        = false
    @AppStorage("draft.settings.outputQuality")    private var outputQuality    = "High"
    @AppStorage("draft.settings.defaultStyle")     private var defaultStyle     = "Minimal"
    @AppStorage("draft.settings.micSensitivity")   private var micSensitivity   = "Medium"

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHeader
                    .padding(.top, 8)
                    .padding(.bottom, 28)

                settingsGroup {
                    iconRow(icon: "wand.and.stars",  color: Color(hex: 0xFF6E00), label: "AI Model",       value: "Draft v2")
                    Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 58)
                    iconRow(icon: "slider.horizontal.3", color: Color(hex: 0x5E5CE6), label: "Output Quality", value: outputQuality)
                    Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 58)
                    iconRow(icon: "paintbrush",      color: Color(hex: 0xFF375F), label: "Default Style",  value: defaultStyle)
                    Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 58)
                    toggleRow(icon: "square.and.arrow.down", color: Color(hex: 0x30D158), label: "Auto-Save Drafts", binding: $autoSave)
                }
                sectionLabel("Generation")

                settingsGroup {
                    iconRow(icon: "mic.fill",        color: Color(hex: 0xFF6E00), label: "Mic Sensitivity", value: micSensitivity)
                    Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 58)
                    toggleRow(icon: "checkmark.circle.fill", color: Color(hex: 0x30D158), label: "Auto-Submit on Silence", binding: $autoSubmit)
                    Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 58)
                    toggleRow(icon: "waveform",      color: Color(hex: 0x5E5CE6), label: "Noise Cancellation", binding: $noiseCancellation)
                }
                sectionLabel("Voice & Input")

                settingsGroup {
                    iconRow(icon: "moon.fill",       color: Color(hex: 0x5E5CE6), label: "Theme",          value: "Dark")
                    Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 58)
                    toggleRow(icon: "hand.tap.fill", color: Color(hex: 0xFF9F0A), label: "Haptic Feedback", binding: $haptics)
                    Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 58)
                    toggleRow(icon: "sparkles",      color: Color(hex: 0xFF375F), label: "Reduce Motion",   binding: $reduceMotion)
                }
                sectionLabel("Appearance")

                settingsGroup {
                    toggleRow(icon: "chart.bar.fill", color: Color(hex: 0x636366), label: "Usage Analytics",  binding: $analytics)
                    Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 58)
                    iconRow(icon: "lock.shield.fill", color: Color(hex: 0x30D158), label: "Privacy Policy",    value: nil)
                    Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 58)
                    destructiveRow(icon: "trash.fill", label: "Clear All History")
                }
                sectionLabel("Privacy")

                settingsGroup {
                    iconRow(icon: "star.fill",        color: Color(hex: 0xFF9F0A), label: "Rate Draft",       value: nil)
                    Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 58)
                    iconRow(icon: "envelope.fill",    color: Color(hex: 0x5E5CE6), label: "Send Feedback",    value: nil)
                    Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 58)
                    iconRow(icon: "info.circle.fill", color: Color(hex: 0x636366), label: "About",            value: nil)
                }
                sectionLabel("Support")

                versionFooter
                    .padding(.top, 12)
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(hex: 0x141414).ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: - Profile header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFF6E00), Color(hex: 0xC44200)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 62, height: 62)
                Text("D")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Draft User")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Beta Access  ·  v1.0.0")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Section container

    @ViewBuilder
    private func settingsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .padding(.bottom, 6)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(0.35))
            .kerning(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            .padding(.top, 14)
            .padding(.bottom, 8)
    }

    // MARK: - Row types

    private func iconRow(icon: String, color: Color, label: String, value: String?) -> some View {
        HStack(spacing: 14) {
            iconChip(icon: icon, color: color)
            Text(label)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white)
            Spacer()
            if let value {
                Text(value)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.38))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func toggleRow(icon: String, color: Color, label: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            iconChip(icon: icon, color: color)
            Text(label)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(Color(hex: 0xFF6E00))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func destructiveRow(icon: String, label: String) -> some View {
        HStack(spacing: 14) {
            iconChip(icon: icon, color: Color(hex: 0xFF3B30))
            Text(label)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color(hex: 0xFF3B30))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func iconChip(icon: String, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(color)
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            )
    }

    // MARK: - Footer

    private var versionFooter: some View {
        VStack(spacing: 4) {
            Text("Draft")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.2))
            Text("Version 1.0.0 (Beta)")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.15))
        }
        .frame(maxWidth: .infinity)
    }
}
