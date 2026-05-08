import SwiftUI
import UIKit
import WebKit

struct OutputView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var selection = 0

    private var payload: ArtifactPayload {
        ArtifactPayloadParser.parse(html: appModel.artifactHTML)
    }

    var body: some View {
        artifactShell
            .background(Color(hex: 0x141414).ignoresSafeArea())
    }

    private var shellSubtitle: String {
        switch payload {
        case .palette:
            return "Color Palette"
        case .photos(let options):
            return options.first?.displayMode == .image ? "Image Gathering" : "Moodboard"
        case .ui:
            return "UI"
        case .web:
            return "Artifact"
        }
    }

    private var artifactShell: some View {
        VStack(spacing: 0) {
            shellHeader
            shellBody
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if showsDirectionIndicator {
                directionIndicator
                    .padding(.top, 16)
            }
            Spacer(minLength: 18)
            AppBottomNav(
                selectedTab: .create,
                variant: .default,
                onSelectCreate: { appModel.resetSession() },
                onSelectLibrary: { appModel.dismissFlowToLibrary() }
            )
            .frame(width: 236)
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 6)
        .frame(maxHeight: .infinity)
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0x141414))
    }

    private var shellHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Draft")
                    .font(.system(size: 40, weight: .bold, design: .default))
                    .foregroundStyle(.white)

                Text(shellSubtitle)
                    .font(.system(size: 20, weight: .regular, design: .default))
                    .foregroundStyle(Color.white.opacity(0.82))
            }

            Spacer()

            HStack(spacing: 12) {
                shellAction(systemName: "xmark") { appModel.resetSession() }
                shellAction(systemName: "checkmark") { appModel.dismissFlow() }
            }
        }
        .padding(.bottom, 20)
    }

    private func shellAction(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: systemName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var shellBody: some View {
        switch payload {
        case .palette(let options):
            PaletteArtifactPager(options: options, selection: $selection)
        case .photos(let options):
            PhotoArtifactPager(options: options, selection: $selection)
        case .ui(let options):
            UIArtifactPager(options: options, selection: $selection)
        case .web(let html):
            WebArtifactView(html: html)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
    }

    private var showsDirectionIndicator: Bool {
        directionCount > 1
    }

    private var directionCount: Int {
        switch payload {
        case .palette(let options):
            return options.count
        case .photos(let options):
            return options.count
        case .ui(let options):
            return options.count
        case .web:
            return 0
        }
    }

    private var directionIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<directionCount, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(index == selection ? 0.96 : 0.28))
                    .frame(width: index == selection ? 22 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.16), value: selection)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PaletteArtifactPager: View {
    let options: [PaletteOptionPayload]
    @Binding var selection: Int

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                PaletteArtifactPage(option: option)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

private struct PaletteArtifactPage: View {
    let option: PaletteOptionPayload

    var body: some View {
        GeometryReader { geometry in
            let gap: CGFloat = 12
            let contentWidth = geometry.size.width
            let contentHeight = geometry.size.height
            let largeWidth = contentWidth
            let leftMediumWidth = floor((contentWidth - gap) * 0.66)
            let rightMediumWidth = contentWidth - gap - leftMediumWidth
            let smallWidth = floor((contentWidth - gap * 2) / 3)
            let bottomWidth = floor((contentWidth - gap) / 2)
            let baseHeights: [CGFloat] = [164, 154, 118, 144]
            // Subtract gaps before scaling so content + gaps = contentHeight exactly
            let heightScale = min(1, (contentHeight - gap * 3) / baseHeights.reduce(0, +))
            let largeHeight = baseHeights[0] * heightScale
            let mediumHeight = baseHeights[1] * heightScale
            let smallHeight = baseHeights[2] * heightScale
            let bottomHeight = baseHeights[3] * heightScale

            VStack(spacing: gap) {
                if option.swatches.indices.contains(0) {
                    PaletteSwatchTile(swatch: option.swatches[0])
                        .frame(width: largeWidth, height: largeHeight)
                }

                HStack(spacing: gap) {
                    if option.swatches.indices.contains(1) {
                        PaletteSwatchTile(swatch: option.swatches[1])
                            .frame(width: leftMediumWidth, height: mediumHeight)
                    }
                    if option.swatches.indices.contains(2) {
                        PaletteSwatchTile(swatch: option.swatches[2])
                            .frame(width: rightMediumWidth, height: mediumHeight)
                    }
                }

                HStack(spacing: gap) {
                    ForEach(3..<6, id: \.self) { index in
                        if option.swatches.indices.contains(index) {
                            PaletteSwatchTile(swatch: option.swatches[index])
                                .frame(width: smallWidth, height: smallHeight)
                        }
                    }
                }

                HStack(spacing: gap) {
                    ForEach(6..<8, id: \.self) { index in
                        if option.swatches.indices.contains(index) {
                            PaletteSwatchTile(swatch: option.swatches[index], bordered: index == 6)
                                .frame(width: bottomWidth, height: bottomHeight)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

private struct PaletteSwatchTile: View {
    let swatch: PaletteSwatch
    var bordered = false

    var body: some View {
        let background = ArtifactColorParser.color(from: swatch.hex)
        let textColor = ArtifactColorParser.isLight(hex: swatch.hex) ? Color.black.opacity(0.92) : Color.white

        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(background)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(bordered ? Color.white.opacity(0.92) : .clear, lineWidth: 1.5)
            )
            .overlay(
                VStack(alignment: .leading, spacing: 2) {
                    Spacer()
                    Text(swatch.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(textColor)
                    Text(swatch.hex.replacingOccurrences(of: "#", with: ""))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(textColor.opacity(0.9))
                }
                .padding(16),
                alignment: .topLeading
            )
    }
}

private struct PhotoArtifactPager: View {
    let options: [PhotoOptionPayload]
    @Binding var selection: Int

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                PhotoArtifactPage(option: option)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

private struct PhotoArtifactPage: View {
    let option: PhotoOptionPayload

    private let gap: CGFloat = 10

    var body: some View {
        VStack(spacing: gap) {
            photoOrPlaceholder(at: 0, swatch: option.swatches?[safe: 0])
                .frame(maxWidth: .infinity)
                .frame(height: 210)

            HStack(spacing: gap) {
                photoOrPlaceholder(at: 1, swatch: option.swatches?[safe: 1])
                    .frame(maxWidth: .infinity)
                    .frame(height: 145)
                photoOrPlaceholder(at: 2, swatch: option.swatches?[safe: 2])
                    .frame(maxWidth: .infinity)
                    .frame(height: 145)
            }

            HStack(spacing: gap) {
                photoOrPlaceholder(at: 3, swatch: option.swatches?[safe: 3])
                    .frame(maxWidth: .infinity)
                    .frame(height: 145)
                photoOrPlaceholder(at: 4, swatch: option.swatches?[safe: 0])
                    .frame(maxWidth: .infinity)
                    .frame(height: 145)
            }

            if option.displayMode == .moodboard, let swatches = option.swatches, !swatches.isEmpty {
                let swatchCount = max(1, min(swatches.count, 4))
                HStack(spacing: gap) {
                    ForEach(Array(swatches.prefix(swatchCount).enumerated()), id: \.offset) { _, swatch in
                        MoodboardSwatchTile(swatch: swatch)
                            .frame(maxWidth: .infinity)
                            .frame(height: 62)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func photoOrPlaceholder(at index: Int, swatch: PaletteSwatch?) -> some View {
        if option.photos.indices.contains(index) {
            PhotoTile(photo: option.photos[index])
        } else {
            PlaceholderTile(swatch: swatch)
        }
    }
}

private struct MoodboardSwatchTile: View {
    let swatch: PaletteSwatch

    var body: some View {
        let background = ArtifactColorParser.color(from: swatch.hex)
        let textColor = ArtifactColorParser.isLight(hex: swatch.hex) ? Color.black.opacity(0.92) : Color.white

        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(background)
            .overlay(
                VStack(alignment: .leading, spacing: 1) {
                    Text(swatch.name)
                        .font(.system(size: 12, weight: .bold))
                    Text(swatch.hex.replacingOccurrences(of: "#", with: ""))
                        .font(.system(size: 10, weight: .medium))
                        .opacity(0.9)
                }
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(12)
            )
    }
}

private struct PlaceholderTile: View {
    var swatch: PaletteSwatch? = nil

    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(gradient)
            .overlay(
                Group {
                    if let swatch {
                        VStack(alignment: .leading, spacing: 2) {
                            Spacer()
                            Text(swatch.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(ArtifactColorParser.isLight(hex: swatch.hex) ? Color.black.opacity(0.7) : Color.white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                    }
                }
            )
    }

    private var gradient: LinearGradient {
        let base = swatch.map { ArtifactColorParser.color(from: $0.hex) } ?? Color(hex: 0x1C1C1C)
        return LinearGradient(
            colors: [base.opacity(0.45), Color(hex: 0x0A0A0A)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct PhotoTile: View {
    let photo: PhotoItemPayload

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ArtifactImageView(urlString: photo.imageUrl, bundleImageName: photo.bundleImageName)
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            Text(photoLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var photoLabel: String {
        let raw = photo.alt.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty { return "Inspiration" }
        return raw
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .prefix(2)
            .joined(separator: " ")
    }
}

private struct UIArtifactPager: View {
    let options: [UIOptionPayload]
    @Binding var selection: Int

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                NativeUIOptionCard(option: option)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

private struct NativeUIOptionCard: View {
    let option: UIOptionPayload

    var body: some View {
        let background = ArtifactColorParser.color(from: option.background)
        let surface = ArtifactColorParser.color(from: option.surface)
        let accent = ArtifactColorParser.color(from: option.accent)
        let muted = ArtifactColorParser.color(from: option.mutedSurface)
        let text = ArtifactColorParser.color(from: option.text)
        let mutedText = ArtifactColorParser.color(from: option.mutedText)

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(option.productName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(text)

                Text(option.supportingText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(mutedText)
                    .fixedSize(horizontal: false, vertical: true)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(surface)
                    .frame(height: 360)
                    .overlay(uiMock(surface: surface, accent: accent, muted: muted, text: text))

                HStack(spacing: 10) {
                    capsuleLabel(option.primaryCta, background: accent, foreground: .black)
                    capsuleLabel(option.secondaryCta, background: .clear, foreground: text, border: muted)
                }
            }
            .padding(18)
        }
        .scrollIndicators(.hidden)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(background)
        )
    }

    private func capsuleLabel(_ title: String, background: Color, foreground: Color, border: Color? = nil) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule(style: .continuous)
                    .fill(background)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(border ?? .clear, lineWidth: 1)
                    )
            )
    }

    private func uiMock(surface: Color, accent: Color, muted: Color, text: Color) -> some View {
        VStack(spacing: 16) {
            HStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(muted).frame(width: 96, height: 14)
                Spacer()
                RoundedRectangle(cornerRadius: 8, style: .continuous).fill(muted.opacity(0.82)).frame(width: 54, height: 14)
            }

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(accent)
                .frame(height: 156)
                .overlay(
                    VStack(alignment: .leading, spacing: 10) {
                        Spacer()
                        Text(option.headline)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(text)
                        Text(option.featureTitle)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(text.opacity(0.75))
                    }
                    .padding(24),
                    alignment: .bottomLeading
                )

            featurePreview(accent: accent, muted: muted, text: text)
        }
        .padding(18)
    }

    @ViewBuilder
    private func featurePreview(accent: Color, muted: Color, text: Color) -> some View {
        switch option.featureKind {
        case .toggles:
            VStack(spacing: 12) {
                ForEach(Array(option.featureItems.prefix(3).enumerated()), id: \.offset) { index, item in
                    HStack {
                        Text(item)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(text)
                        Spacer()
                        ZStack(alignment: index == 1 ? .leading : .trailing) {
                            Capsule(style: .continuous)
                                .fill(index == 1 ? muted.opacity(0.8) : accent.opacity(0.9))
                                .frame(width: 54, height: 32)
                            Circle()
                                .fill(.white)
                                .frame(width: 26, height: 26)
                                .padding(3)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(muted.opacity(0.42))
                    )
                }
            }

        case .buttons:
            VStack(spacing: 12) {
                ForEach(Array(option.featureItems.prefix(3).enumerated()), id: \.offset) { index, item in
                    Text(item)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(index == 1 ? text : Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(index == 1 ? muted.opacity(0.58) : accent)
                        )
                }
            }

        case .picker:
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    ForEach(Array(option.featureItems.prefix(3).enumerated()), id: \.offset) { index, item in
                        Text(item)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(index == 0 ? Color.black : text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(index == 0 ? accent : muted.opacity(0.48))
                            )
                    }
                }

                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous).fill(muted.opacity(0.84))
                    RoundedRectangle(cornerRadius: 24, style: .continuous).fill(muted.opacity(0.56))
                }
                .frame(height: 112)
            }

        case .cards:
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous).fill(muted.opacity(0.84))
                    RoundedRectangle(cornerRadius: 24, style: .continuous).fill(muted.opacity(0.56))
                }
                .frame(height: 112)

                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 22, style: .continuous).fill(muted.opacity(0.62))
                    RoundedRectangle(cornerRadius: 22, style: .continuous).fill(muted.opacity(0.76))
                    RoundedRectangle(cornerRadius: 22, style: .continuous).fill(accent.opacity(0.32))
                }
                .frame(height: 84)
            }
        }
    }
}

private struct ArtifactImageView: View {
    let urlString: String
    let bundleImageName: String?

    var body: some View {
        Group {
            if let bundleImage {
                Image(uiImage: bundleImage)
                    .resizable()
                    .scaledToFill()
            } else if let image = dataImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0x1C1C1C))
        .clipped()
    }

    private var bundleImage: UIImage? {
        guard let bundleImageName, !bundleImageName.isEmpty else { return nil }
        return UIImage(named: bundleImageName)
    }

    private var dataImage: UIImage? {
        guard urlString.hasPrefix("data:"),
              let commaIndex = urlString.firstIndex(of: ",") else {
            return nil
        }

        let base64 = String(urlString[urlString.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [Color(hex: 0x2B2B2B), Color(hex: 0x161616)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private enum ArtifactColorParser {
    static func color(from value: String) -> Color {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("#") {
            return colorFromHex(trimmed)
        }

        if trimmed.lowercased().hasPrefix("rgba") {
            return colorFromRGBA(trimmed)
        }

        return .white
    }

    static func isLight(hex: String) -> Bool {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6 else { return false }
        let r = Double(Int(cleaned.prefix(2), radix: 16) ?? 0)
        let g = Double(Int(cleaned.dropFirst(2).prefix(2), radix: 16) ?? 0)
        let b = Double(Int(cleaned.dropFirst(4).prefix(2), radix: 16) ?? 0)
        let brightness = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
        return brightness > 0.72
    }

    private static func colorFromHex(_ hex: String) -> Color {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6 else { return .white }

        let r = Double(Int(cleaned.prefix(2), radix: 16) ?? 0) / 255
        let g = Double(Int(cleaned.dropFirst(2).prefix(2), radix: 16) ?? 0) / 255
        let b = Double(Int(cleaned.dropFirst(4).prefix(2), radix: 16) ?? 0) / 255

        return Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    private static func colorFromRGBA(_ rgba: String) -> Color {
        let cleaned = rgba
            .replacingOccurrences(of: "rgba(", with: "")
            .replacingOccurrences(of: ")", with: "")
        let components = cleaned.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard components.count == 4 else { return .white }

        let r = Double(components[0]) ?? 255
        let g = Double(components[1]) ?? 255
        let b = Double(components[2]) ?? 255
        let a = Double(components[3]) ?? 1

        return Color(.sRGB, red: r / 255, green: g / 255, blue: b / 255, opacity: a)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct WebArtifactView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}
