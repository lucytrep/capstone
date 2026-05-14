import SwiftUI
import UIKit
import WebKit

/// Matches `PhotoArtifactPage.tileCorner` / `PhotoTile` so palette grids read as the same family as moodboards.
private let artifactTileCornerRadius: CGFloat = 16

struct OutputView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var selection = 0
    @State private var showExportSheet = false

    private var payload: ArtifactPayload {
        ArtifactPayloadParser.parse(html: appModel.artifactHTML)
    }

    var body: some View {
        artifactShell
            .background(Color(hex: 0x141414).ignoresSafeArea())
            .sheet(isPresented: $showExportSheet) {
                DraftExportSheet(
                    artifactHTML: appModel.artifactHTML,
                    payload: payload,
                    directionIndex: selection
                )
                .presentationDetents([.medium, .large])
                .presentationBackground(Color(hex: 0x1A1A1A))
            }
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
                .padding(.horizontal, 20)
            shellBody
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if showsDirectionIndicator {
                directionIndicator
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
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
                shellAction(systemName: "square.and.arrow.up", accessibilityLabel: "Export draft") {
                    showExportSheet = true
                }
                shellAction(systemName: "xmark", accessibilityLabel: "Discard") { appModel.resetSession() }
                shellAction(systemName: "checkmark", accessibilityLabel: "Save to library") {
                    appModel.saveGeneratedDraftToLibrary(directionIndex: selection)
                }
            }
        }
        .padding(.bottom, 20)
    }

    private func shellAction(systemName: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
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
        .accessibilityLabel(accessibilityLabel)
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
                .padding(.horizontal, 20)
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

    private let itemPageHaptics = UISelectionFeedbackGenerator()

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                PaletteArtifactPage(option: option)
                    .padding(.horizontal, 20)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onAppear { itemPageHaptics.prepare() }
        .onChange(of: selection) { _, _ in
            itemPageHaptics.selectionChanged()
            itemPageHaptics.prepare()
        }
    }
}

private struct PaletteArtifactPage: View {
    let option: PaletteOptionPayload

    var body: some View {
        GeometryReader { geometry in
            let gap: CGFloat = 10
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

        RoundedRectangle(cornerRadius: artifactTileCornerRadius, style: .continuous)
            .fill(background)
            .overlay(
                RoundedRectangle(cornerRadius: artifactTileCornerRadius, style: .continuous)
                    .stroke(bordered ? Color.white.opacity(0.92) : Color.white.opacity(0.08), lineWidth: bordered ? 1.5 : 1)
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

    private let itemPageHaptics = UISelectionFeedbackGenerator()

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                PhotoArtifactPage(option: option)
                    .padding(.horizontal, 20)
                    .id(option.id)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onAppear { itemPageHaptics.prepare() }
        .onChange(of: selection) { _, _ in
            itemPageHaptics.selectionChanged()
            itemPageHaptics.prepare()
        }
    }
}

private struct PhotoArtifactPage: View {
    let option: PhotoOptionPayload

    private let gap: CGFloat = 10
    private let tileCorner: CGFloat = artifactTileCornerRadius

    /// Matches `MockArtifactGenerator.swapLowResBundleAssetsTowardThirdDirection`.
    private static let lowResBundleLayoutThreshold = 1200
    /// In moodboard mode, these grid slots are replaced by palette swatch tiles (swatch index = order in array).
    private static let moodboardSwatchSlotOrder = [1, 4]

    /// For each grid slot 0…5, the index into `option.photos` shown there (nil = placeholder).
    private var slotOriginalIndices: [Int?] {
        Self.slotOriginalIndices(for: option.photos)
    }

    private var moodboardSwatchSlots: [Int: PaletteSwatch] {
        guard option.displayMode == .moodboard, let swatches = option.swatches, !swatches.isEmpty else { return [:] }
        var map: [Int: PaletteSwatch] = [:]
        for (i, slot) in Self.moodboardSwatchSlotOrder.enumerated() {
            guard i < swatches.count else { break }
            map[slot] = swatches[i]
        }
        return map
    }

    var body: some View {
        GeometryReader { geometry in
            let contentWidth = geometry.size.width
            let contentHeight = geometry.size.height
            let baseHeights: [CGFloat] = [210, 148, 168]
            let rowGaps = gap * 2
            let heightBudget = max(0, contentHeight - rowGaps)
            let baseSum = baseHeights.reduce(0, +)
            let heightScale = baseSum > 0 ? heightBudget / baseSum : 0
            let heroHeight = baseHeights[0] * heightScale
            let midHeight = baseHeights[1] * heightScale
            let bottomHeight = baseHeights[2] * heightScale
            let midCellWidth = floor((contentWidth - gap) / 2)
            let bottomCellWidth = floor((contentWidth - 2 * gap) / 3)

            VStack(spacing: gap) {
                photoCell(index: 0)
                    .frame(width: contentWidth, height: heroHeight)
                    .clipShape(RoundedRectangle(cornerRadius: tileCorner, style: .continuous))

                HStack(spacing: gap) {
                    photoCell(index: 1)
                        .frame(width: midCellWidth, height: midHeight)
                        .clipShape(RoundedRectangle(cornerRadius: tileCorner, style: .continuous))
                    photoCell(index: 2)
                        .frame(width: midCellWidth, height: midHeight)
                        .clipShape(RoundedRectangle(cornerRadius: tileCorner, style: .continuous))
                }

                HStack(spacing: gap) {
                    photoCell(index: 3)
                        .frame(width: bottomCellWidth, height: bottomHeight)
                        .clipShape(RoundedRectangle(cornerRadius: tileCorner, style: .continuous))
                    photoCell(index: 4)
                        .frame(width: bottomCellWidth, height: bottomHeight)
                        .clipShape(RoundedRectangle(cornerRadius: tileCorner, style: .continuous))
                    photoCell(index: 5)
                        .frame(width: bottomCellWidth, height: bottomHeight)
                        .clipShape(RoundedRectangle(cornerRadius: tileCorner, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private func photoCell(index: Int) -> some View {
        if let moodSwatch = moodboardSwatchSlots[index] {
            PaletteSwatchTile(swatch: moodSwatch)
        } else if let oi = slotOriginalIndices[index], option.photos.indices.contains(oi) {
            PhotoTile(photo: option.photos[oi])
        } else {
            PlaceholderTile()
        }
    }

    /// Puts small bundled assets in the bottom row first, then mid/hero, so large slots show sharp images.
    private static func slotOriginalIndices(for photos: [PhotoItemPayload]) -> [Int?] {
        var result: [Int?] = Array(repeating: nil, count: 6)
        guard !photos.isEmpty else { return result }

        func isLowResBundle(_ p: PhotoItemPayload) -> Bool {
            guard let b = p.bundleImageName, !b.isEmpty else { return false }
            guard let d = p.maxPixelDimension else { return true }
            return d < lowResBundleLayoutThreshold
        }

        let lowOrig = photos.indices.filter { isLowResBundle(photos[$0]) }
        let highOrig = photos.indices.filter { !isLowResBundle(photos[$0]) }
        let bottomSlots = [3, 4, 5]
        let topSlots = [0, 1, 2]

        var lowQ = lowOrig
        var highQ = highOrig
        var nextFree = 0

        func takeNextSlot() -> Int? {
            while nextFree < 6 {
                if result[nextFree] == nil { return nextFree }
                nextFree += 1
            }
            return nil
        }

        for s in bottomSlots {
            guard let oi = lowQ.first else { break }
            lowQ.removeFirst()
            if s < result.count { result[s] = oi }
        }
        for s in topSlots {
            guard let oi = highQ.first else { break }
            highQ.removeFirst()
            if s < result.count { result[s] = oi }
        }
        var remainder = lowQ + highQ
        while let oi = remainder.first {
            remainder.removeFirst()
            guard let slot = takeNextSlot() else { break }
            result[slot] = oi
            nextFree = slot + 1
        }
        return result
    }
}

private struct PlaceholderTile: View {
    var swatch: PaletteSwatch? = nil

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.68),
                    .init(color: .black.opacity(0.52), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(photoLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.45), radius: 3, x: 0, y: 1)
                .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

    private let itemPageHaptics = UISelectionFeedbackGenerator()

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                NativeUIOptionCard(option: option)
                    .padding(.horizontal, 20)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onAppear { itemPageHaptics.prepare() }
        .onChange(of: selection) { _, _ in
            itemPageHaptics.selectionChanged()
            itemPageHaptics.prepare()
        }
    }
}

private struct NativeUIOptionCard: View {
    let option: UIOptionPayload

    private let corner: CGFloat = artifactTileCornerRadius
    private let gap: CGFloat = 10

    private var accent: Color { ArtifactColorParser.color(from: option.accent) }
    private var onAccent: Color { ArtifactColorParser.isLight(hex: option.accent) ? .black.opacity(0.88) : .white }

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let baseHeights: [CGFloat] = [200, 164, 92]
            let budget = max(0, h - gap * 2)
            let hs = budget / max(1, baseHeights.reduce(0, +))
            let heroH   = baseHeights[0] * hs
            let midH    = baseHeights[1] * hs
            let bottomH = baseHeights[2] * hs
            let halfW   = floor((w - gap) / 2)

            VStack(spacing: gap) {
                heroTile(width: w, height: heroH)

                HStack(spacing: gap) {
                    componentTile(width: halfW, height: midH)
                    descriptionTile(width: halfW, height: midH)
                }

                HStack(spacing: gap) {
                    ctaTile(title: option.primaryCta, width: halfW, height: bottomH, primary: true)
                    ctaTile(title: option.secondaryCta, width: halfW, height: bottomH, primary: false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func heroTile(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(accent)
            LinearGradient(
                colors: [Color.black.opacity(0), Color.black.opacity(0.28)],
                startPoint: .top, endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Text(option.label.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(onAccent.opacity(0.55))
                    .kerning(1.2)
                Text(option.productName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(onAccent)
                    .lineLimit(1)
                Text(option.headline)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(onAccent.opacity(0.72))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }

    private func componentTile(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color(hex: 0x1C1C1E))
                .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1))
            VStack(alignment: .leading, spacing: 9) {
                Text(option.featureTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.4))
                featurePreview()
            }
            .padding(13)
        }
        .frame(width: width, height: height)
    }

    private func descriptionTile(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color(hex: 0x1C1C1E))
                .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(accent.opacity(0.3), lineWidth: 1))
            VStack(alignment: .leading, spacing: 8) {
                accent.frame(width: 24, height: 3).clipShape(Capsule())
                Text(option.supportingText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .lineLimit(7)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(13)
        }
        .frame(width: width, height: height)
    }

    private func ctaTile(title: String, width: CGFloat, height: CGFloat, primary: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(primary ? accent : Color(hex: 0x1C1C1E))
                .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous).stroke(primary ? Color.clear : Color.white.opacity(0.1), lineWidth: 1))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(primary ? onAccent : Color.white.opacity(0.8))
                .lineLimit(1)
        }
        .frame(width: width, height: height)
    }

    @ViewBuilder
    private func featurePreview() -> some View {
        switch option.featureKind {
        case .toggles:
            VStack(spacing: 6) {
                ForEach(Array(option.featureItems.prefix(2).enumerated()), id: \.offset) { i, item in
                    HStack {
                        Text(item).font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.72))
                        Spacer()
                        ZStack(alignment: i == 1 ? .leading : .trailing) {
                            Capsule().fill(i == 1 ? Color.white.opacity(0.12) : accent).frame(width: 38, height: 22)
                            Circle().fill(.white).frame(width: 16).padding(3)
                        }
                    }
                    .padding(.horizontal, 9).frame(height: 34)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                }
            }

        case .buttons:
            VStack(spacing: 6) {
                ForEach(Array(option.featureItems.prefix(2).enumerated()), id: \.offset) { i, item in
                    Text(item)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(i == 0 ? onAccent : .white.opacity(0.78))
                        .frame(maxWidth: .infinity).frame(height: 34)
                        .background(RoundedRectangle(cornerRadius: 10).fill(i == 0 ? accent : Color.white.opacity(0.07)))
                }
            }

        case .picker:
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    ForEach(Array(option.featureItems.prefix(3).enumerated()), id: \.offset) { i, item in
                        Text(item).font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(i == 0 ? onAccent : .white.opacity(0.55))
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(Capsule().fill(i == 0 ? accent : Color.white.opacity(0.07)))
                    }
                }
                RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)).frame(maxWidth: .infinity).frame(height: 46)
            }

        case .cards:
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 10).fill(accent.opacity(0.3)).frame(height: 42)
                    RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)).frame(height: 42)
                }
                RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)).frame(maxWidth: .infinity).frame(height: 30)
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
                    .interpolation(.high)
                    .scaledToFill()
            } else if let image = dataImage {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
            } else if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .interpolation(.high)
                            .scaledToFill()
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

enum ArtifactColorParser {
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
