import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Spacer()
                    Text("Settings")
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundStyle(.white)
                    Spacer()
                }

                settingsSection(
                    title: "General",
                    rows: ["Saved", "Output", "Privacy"],
                    showsIcons: true
                )

                settingsSection(
                    title: "Preferences",
                    rows: ["Notifications", "Appearance"],
                    showsIcons: false
                )
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 42)
        }
        .background(Color(hex: 0x141414).ignoresSafeArea())
        .navigationBarHidden(false)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private func settingsSection(title: String, rows: [String], showsIcons: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 29, weight: .bold, design: .default))
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(spacing: 14) {
                        if showsIcons {
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: iconName(for: row))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                )
                        }

                        Text(row)
                            .font(.system(size: 17, weight: .semibold, design: .default))
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)

                    if index < rows.count - 1 {
                        Divider()
                            .overlay(Color.white.opacity(0.08))
                            .padding(.horizontal, 18)
                    }
                }
            }
            .background(Color(hex: 0x151515))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    private func iconName(for row: String) -> String {
        switch row {
        case "Saved": return "bookmark"
        case "Output": return "slider.horizontal.3"
        case "Privacy": return "shield"
        default: return "circle"
        }
    }
}
