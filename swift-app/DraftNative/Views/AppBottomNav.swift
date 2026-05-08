import SwiftUI

enum AppBottomNavVariant {
    case `default`
    case home
}

struct AppBottomNav: View {
    let selectedTab: DraftTab
    let variant: AppBottomNavVariant
    let onSelectCreate: () -> Void
    let onSelectLibrary: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button(action: onSelectCreate) {
                navIcon(systemName: "waveform", active: selectedTab == .create, size: 24)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            Button(action: onSelectLibrary) {
                navIcon(systemName: "books.vertical.fill", active: selectedTab == .library, size: 22)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 26)
        .background(glassBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 66, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 66, style: .continuous))
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowYOffset)
    }

    @ViewBuilder
    private var glassBackground: some View {
        if variant == .default {
            RoundedRectangle(cornerRadius: 66, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: 0x252627), location: 0.0451),
                            .init(color: Color(hex: 0x353435), location: 0.7082),
                            .init(color: Color(hex: 0x2C2C2D), location: 0.9824)
                        ],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                )
        } else {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.16))
                )
        }
    }

    private var borderColor: Color {
        switch variant {
        case .default:
            return Color(hex: 0x313032)
        case .home:
            return Color.white.opacity(0.28)
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .default:
            return Color.black.opacity(0.48)
        case .home:
            return Color.black.opacity(0.18)
        }
    }

    private var shadowRadius: CGFloat {
        switch variant {
        case .default: return 24
        case .home: return 20
        }
    }

    private var shadowYOffset: CGFloat {
        switch variant {
        case .default: return 10
        case .home: return 8
        }
    }

    @ViewBuilder
    private func navIcon(systemName: String, active: Bool, size: CGFloat, width: CGFloat = 62, height: CGFloat = 54) -> some View {
        if variant == .default {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(active ? Color.white.opacity(0.9) : Color(hex: 0x696969))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(activeFill(active: active))
                    .overlay {
                        if active {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.42), lineWidth: 1)
                        }
                    }
                    .frame(width: width, height: height)

                Image(systemName: systemName)
                    .font(.system(size: size, weight: .regular))
                    .foregroundStyle(active ? Color(hex: 0x2A0620) : Color.white.opacity(0.92))
            }
            .frame(width: width, height: height)
            .compositingGroup()
        }
    }

    private func activeFill(active: Bool) -> Color {
        switch variant {
        case .default:
            return active ? Color.white.opacity(0.14) : .clear
        case .home:
            return active ? Color.white.opacity(0.96) : Color.white.opacity(0.14)
        }
    }
}
