import SwiftUI
import UIKit

// MARK: - Share sheet bridge

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Messages and several system share targets attach a **file URL** reliably; a raw `UIImage` plus a caption `String`
/// often results in only the text being composed. This item source hands targets a temp JPEG while pasteboard still gets the image.
final class ShareableLibraryImageItem: NSObject, UIActivityItemSource {
    private let image: UIImage
    private let lock = NSLock()
    private var cachedFileURL: URL?

    init(image: UIImage) {
        self.image = image
    }

    private func jpegFileURL() -> URL? {
        lock.lock()
        defer { lock.unlock() }
        if let cachedFileURL { return cachedFileURL }
        let url = try? DraftExportFileWriter.writeShareJPEG(image)
        cachedFileURL = url
        return url
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        switch activityType {
        case .some(.copyToPasteboard):
            return image
        default:
            return jpegFileURL() ?? image
        }
    }
}

/// Shared payload for `ActivityView` when presented from a SwiftUI `.sheet(item:)`.
struct DraftShareSheetPayload: Identifiable {
    let id = UUID()
    let activityItems: [Any]
}

// MARK: - Library share (items + boards)

enum LibraryShareImageFactory {
    /// Single-item share (detail screen): one JPEG-backed item source so Messages attaches the image.
    static func activityItems(forItem item: LibraryItem) async -> [Any] {
        if let image = await uiImage(for: item) {
            return [ShareableLibraryImageItem(image: image)]
        }
        if let url = item.imageURL ?? item.thumbnailURL {
            var out: [Any] = [url]
            let cap = itemShareCaption(item)
            if !cap.isEmpty { out.append(cap) }
            return out
        }
        let cap = itemShareCaption(item)
        if !cap.isEmpty { return [cap] }
        return [item.label]
    }

    /// Board share: one attachment per item (JPEG where possible) in board order, up to `maxItems`.
    static func activityItems(forBoard board: LibraryBoard, maxItems: Int = 18) async -> [Any] {
        var out: [Any] = []
        for item in board.items.prefix(maxItems) {
            if let image = await uiImage(for: item) {
                out.append(ShareableLibraryImageItem(image: image))
            } else if let url = item.imageURL ?? item.thumbnailURL {
                out.append(url)
            } else {
                let cap = itemShareCaption(item)
                if !cap.isEmpty { out.append(cap) }
            }
        }
        if out.isEmpty {
            return ["\(board.promptTitle)\n\(board.itemCount) items"]
        }
        return out
    }

    private static func uiImage(for item: LibraryItem) async -> UIImage? {
        if let name = item.bundleImageName, let img = UIImage(named: name) {
            return img
        }
        if let url = item.imageURL ?? item.thumbnailURL {
            if let data = try? await URLSession.shared.data(from: url).0, let img = UIImage(data: data) {
                return img
            }
            return nil
        }
        if item.kind == .palette {
            return await MainActor.run {
                renderPaletteShareImage(preview: item.previewColorHex, secondary: item.secondaryColorHex)
            }
        }
        return nil
    }

    private static func itemShareCaption(_ item: LibraryItem) -> String {
        [item.alt, item.label]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    private static func renderPaletteShareImage(preview: UInt, secondary: UInt) -> UIImage {
        let size = CGSize(width: 900, height: 900)
        let c1 = uiColor(hex: preview)
        let c2 = uiColor(hex: secondary)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [c1.cgColor, c2.cgColor] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) {
                ctx.cgContext.drawLinearGradient(
                    gradient,
                    start: .zero,
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }
        }
    }

    private static func uiColor(hex: UInt) -> UIColor {
        let r = CGFloat((hex >> 16) & 0xff) / 255
        let g = CGFloat((hex >> 8) & 0xff) / 255
        let b = CGFloat(hex & 0xff) / 255
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - File + formatted exports

enum DraftExportFileWriter {
    static func writeHTMLToTemporaryFile(html: String) throws -> URL {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let stamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Draft-\(stamp).html")
        try html.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func writeShareJPEG(_ image: UIImage, compressionQuality: CGFloat = 0.92) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("draft-share-\(UUID().uuidString).jpg")
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            throw DraftShareImageEncodingError()
        }
        try data.write(to: url, options: .atomic)
        return url
    }
}

private struct DraftShareImageEncodingError: Error {}

enum DraftExportFormatters {
    static func cssVariables(payload: ArtifactPayload, directionIndex: Int) -> String? {
        guard case .palette(let options) = payload,
              options.indices.contains(directionIndex) else { return nil }
        let swatches = options[directionIndex].swatches
        guard !swatches.isEmpty else { return nil }
        let vars = swatches.map { s in
            let name = s.name.lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-")).inverted)
                .joined()
            return "  --color-\(name): \(s.hex);"
        }.joined(separator: "\n")
        return ":root {\n\(vars)\n}"
    }

    static func figmaPaletteSVG(payload: ArtifactPayload, directionIndex: Int) -> String? {
        guard case .palette(let options) = payload,
              options.indices.contains(directionIndex) else { return nil }
        let swatches = options[directionIndex].swatches
        guard !swatches.isEmpty else { return nil }
        let cell: CGFloat = 100
        let width = cell * CGFloat(swatches.count)
        var rects = ""
        for (i, s) in swatches.enumerated() {
            let x = CGFloat(i) * cell
            rects += #"<rect x="\#(x)" y="0" width="\#(cell)" height="\#(cell)" fill="\#(s.hex)"/>"#
            rects += "\n"
        }
        return """
        <svg xmlns="http://www.w3.org/2000/svg" width="\(Int(width))" height="\(Int(cell))" viewBox="0 0 \(width) \(cell)">
        \(rects)</svg>
        """
    }

    static func commaSeparatedHexes(payload: ArtifactPayload, directionIndex: Int) -> String? {
        guard case .palette(let options) = payload,
              options.indices.contains(directionIndex) else { return nil }
        let swatches = options[directionIndex].swatches
        guard !swatches.isEmpty else { return nil }
        return swatches.map(\.hex).joined(separator: ", ")
    }

    static func photoReferenceList(payload: ArtifactPayload, directionIndex: Int) -> String? {
        guard case .photos(let options) = payload,
              options.indices.contains(directionIndex) else { return nil }
        let photos = options[directionIndex].photos
        guard !photos.isEmpty else { return nil }
        return photos.map { p in
            [p.imageUrl, "  \(p.alt)", "  \(p.author) · \(p.source.rawValue) · \(p.detailUrl)"]
                .joined(separator: "\n")
        }.joined(separator: "\n\n")
    }

    static func illustratorSwatchTSV(payload: ArtifactPayload, directionIndex: Int) -> String? {
        guard case .palette(let options) = payload,
              options.indices.contains(directionIndex) else { return nil }
        let swatches = options[directionIndex].swatches
        guard !swatches.isEmpty else { return nil }
        return swatches.map { "\($0.name)\t\($0.hex)" }.joined(separator: "\n")
    }

    static func uiDirectionJSON(payload: ArtifactPayload, directionIndex: Int) -> String? {
        guard case .ui(let options) = payload,
              options.indices.contains(directionIndex) else { return nil }
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? enc.encode(options[directionIndex]) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Open in Figma, Pinterest, AI chats

private enum DraftExternalOpenTool: String, CaseIterable, Identifiable {
    case figma
    case pinterest
    case claude
    case chatGPT
    case gemini

    var id: String { rawValue }

    var title: String {
        switch self {
        case .figma: return "Figma"
        case .pinterest: return "Pinterest"
        case .claude: return "Claude"
        case .chatGPT: return "ChatGPT"
        case .gemini: return "Gemini"
        }
    }

    var subtitle: String {
        switch self {
        case .figma: return "SVG, CSS, or references on clipboard — paste on canvas"
        case .pinterest: return "Image links & credits for boards or search"
        case .claude: return "Bundled export for a new chat"
        case .chatGPT: return "Bundled export for a new chat"
        case .gemini: return "Bundled export for a new chat"
        }
    }

    var systemImage: String {
        switch self {
        case .figma: return "square.grid.3x3"
        case .pinterest: return "pin.circle"
        case .claude: return "sparkles"
        case .chatGPT: return "bubble.left.and.bubble.right"
        case .gemini: return "star.circle"
        }
    }

    /// HTTPS URLs so Universal Links open the native app when installed.
    var destinationURL: URL {
        switch self {
        case .figma:
            return URL(string: "https://www.figma.com/")!
        case .pinterest:
            return URL(string: "https://www.pinterest.com/")!
        case .claude:
            return URL(string: "https://claude.ai/new")!
        case .chatGPT:
            return URL(string: "https://chatgpt.com/")!
        case .gemini:
            return URL(string: "https://gemini.google.com/app")!
        }
    }

    func pasteboardString(artifactHTML: String, payload: ArtifactPayload, directionIndex: Int) -> String {
        switch self {
        case .figma:
            return Self.firstNonEmpty([
                DraftExportFormatters.figmaPaletteSVG(payload: payload, directionIndex: directionIndex),
                DraftExportFormatters.cssVariables(payload: payload, directionIndex: directionIndex),
                DraftExportFormatters.illustratorSwatchTSV(payload: payload, directionIndex: directionIndex),
                DraftExportFormatters.photoReferenceList(payload: payload, directionIndex: directionIndex),
                DraftExportFormatters.uiDirectionJSON(payload: payload, directionIndex: directionIndex),
            ]) ?? Self.genericFallback(artifactHTML: artifactHTML, payload: payload, directionIndex: directionIndex)

        case .pinterest:
            return Self.firstNonEmpty([
                DraftExportFormatters.photoReferenceList(payload: payload, directionIndex: directionIndex),
                DraftExportFormatters.commaSeparatedHexes(payload: payload, directionIndex: directionIndex),
                DraftExportFormatters.cssVariables(payload: payload, directionIndex: directionIndex),
                DraftExportFormatters.figmaPaletteSVG(payload: payload, directionIndex: directionIndex),
            ]) ?? Self.genericFallback(artifactHTML: artifactHTML, payload: payload, directionIndex: directionIndex)

        case .claude, .chatGPT, .gemini:
            return Self.aiBundle(artifactHTML: artifactHTML, payload: payload, directionIndex: directionIndex)
        }
    }

    private static func firstNonEmpty(_ options: [String?]) -> String? {
        for opt in options {
            guard let s = opt else { continue }
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return t }
        }
        return nil
    }

    private static func genericFallback(artifactHTML: String, payload: ArtifactPayload, directionIndex: Int) -> String {
        if let s = ArtifactPayloadParser.primaryEmbeddedJSONString(html: artifactHTML), !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return s
        }
        if let s = DraftExportFormatters.uiDirectionJSON(payload: payload, directionIndex: directionIndex) {
            return s
        }
        let trimmed = artifactHTML.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 12_000 {
            return String(trimmed.prefix(12_000)) + "\n\n… (truncated)"
        }
        return trimmed
    }

    private static func aiBundle(artifactHTML: String, payload: ArtifactPayload, directionIndex: Int) -> String {
        var blocks: [String] = []
        blocks.append("Export from the Draft iOS app — use the sections below.\n")

        if let svg = DraftExportFormatters.figmaPaletteSVG(payload: payload, directionIndex: directionIndex) {
            blocks.append("## Palette (SVG)\n\(svg)")
        }
        if let css = DraftExportFormatters.cssVariables(payload: payload, directionIndex: directionIndex) {
            blocks.append("## CSS variables\n\(css)")
        }
        if let photos = DraftExportFormatters.photoReferenceList(payload: payload, directionIndex: directionIndex) {
            blocks.append("## Image references\n\(photos)")
        }
        if let json = DraftExportFormatters.uiDirectionJSON(payload: payload, directionIndex: directionIndex) {
            blocks.append("## UI direction (JSON)\n\(json)")
        }
        if let hex = DraftExportFormatters.commaSeparatedHexes(payload: payload, directionIndex: directionIndex) {
            blocks.append("## Hex list\n\(hex)")
        }
        if let embedded = ArtifactPayloadParser.primaryEmbeddedJSONString(html: artifactHTML) {
            blocks.append("## Embedded JSON\n\(embedded)")
        }
        if blocks.count == 1 {
            let snippet = String(artifactHTML.prefix(10_000))
            blocks.append("## Artifact HTML (snippet)\n\(snippet)")
        }
        let joined = blocks.joined(separator: "\n\n")
        if joined.count > 14_000 {
            return String(joined.prefix(14_000)) + "\n\n… (truncated for chat paste)"
        }
        return joined
    }
}

// MARK: - Export card (for PNG rendering)

private struct DraftExportCard: View {
    let payload: ArtifactPayload
    let directionIndex: Int

    var body: some View {
        ZStack {
            Color(hex: 0x141414)
            content
                .padding(24)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch payload {
        case .palette(let options) where options.indices.contains(directionIndex):
            paletteGrid(options[directionIndex].swatches)
        case .ui(let options) where options.indices.contains(directionIndex):
            uiTokenGrid(options[directionIndex])
        default:
            EmptyView()
        }
    }

    private func paletteGrid(_ swatches: [PaletteSwatch]) -> some View {
        VStack(spacing: 10) {
            ForEach(swatches, id: \.hex) { swatch in
                let bg = ArtifactColorParser.color(from: swatch.hex)
                let fg: Color = ArtifactColorParser.isLight(hex: swatch.hex) ? .black.opacity(0.85) : .white
                HStack {
                    Text(swatch.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(fg)
                    Spacer()
                    Text(swatch.hex.uppercased())
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(fg.opacity(0.8))
                }
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(bg))
            }
        }
    }

    private func uiTokenGrid(_ option: UIOptionPayload) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(option.productName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            tokenRow("Background", hex: option.background)
            tokenRow("Surface", hex: option.surface)
            tokenRow("Accent", hex: option.accent)
            tokenRow("Text", hex: option.text)
        }
    }

    private func tokenRow(_ name: String, hex: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(ArtifactColorParser.color(from: hex))
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(hex.uppercased())
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Export sheet

struct DraftExportSheet: View {
    let artifactHTML: String
    let payload: ArtifactPayload
    let directionIndex: Int

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var shareItems: [Any] = []
    @State private var isSharing = false
    @State private var copiedLabel: String?

    var body: some View {
        NavigationStack {
            List {
                // MARK: Open in
                Section {
                    ForEach(DraftExternalOpenTool.allCases) { tool in
                        Button {
                            openInExternalTool(tool)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: tool.systemImage)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 28, alignment: .center)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Open in \(tool.title)")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text(tool.subtitle)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 8)
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                } header: {
                    Text("Open in…")
                } footer: {
                    Text("Copies the best format for that destination, then opens the site (or the app via a universal link). Paste in Figma with ⌘V on desktop, or into the chat field on mobile.")
                }

                // MARK: Export
                Section {
                    if canExportAsPNG {
                        Button { exportAsPNG() } label: {
                            Label("Export as PNG…", systemImage: "photo")
                        }
                    }
                    if let urls = photoShareURLs {
                        Button {
                            shareItems = [urls]
                            isSharing = true
                        } label: {
                            Label("Share image references…", systemImage: "square.and.arrow.up")
                        }
                    }
                } header: {
                    Text("Export")
                } footer: {
                    Text("PNG opens in the iOS share sheet — save to Photos, AirDrop, or drop into Figma.")
                }

                // MARK: Copy
                Section {
                    if let s = DraftExportFormatters.cssVariables(payload: payload, directionIndex: directionIndex) {
                        copyRow("Copy CSS variables", value: s, systemImage: "curlybraces")
                    }
                    if let s = DraftExportFormatters.figmaPaletteSVG(payload: payload, directionIndex: directionIndex) {
                        copyRow("Copy Figma palette (SVG)", value: s, systemImage: "rectangle.split.3x1")
                    }
                    if let s = DraftExportFormatters.commaSeparatedHexes(payload: payload, directionIndex: directionIndex) {
                        copyRow("Copy hex codes", value: s, systemImage: "number")
                    }
                    if let s = DraftExportFormatters.photoReferenceList(payload: payload, directionIndex: directionIndex) {
                        copyRow("Copy image URLs + credits", value: s, systemImage: "photo.on.rectangle.angled")
                    }
                    if let s = DraftExportFormatters.illustratorSwatchTSV(payload: payload, directionIndex: directionIndex) {
                        copyRow("Copy for Illustrator (TSV)", value: s, systemImage: "eyedropper.halffull")
                    }
                    if let s = DraftExportFormatters.uiDirectionJSON(payload: payload, directionIndex: directionIndex) {
                        copyRow("Copy UI tokens (JSON)", value: s, systemImage: "paintpalette")
                    }
                } header: {
                    Text("Copy")
                }

                // MARK: Advanced
                Section {
                    if let s = ArtifactPayloadParser.primaryEmbeddedJSONString(html: artifactHTML) {
                        copyRow("Copy structured data (JSON)", value: s, systemImage: "doc.text")
                    }
                    copyRow("Copy raw HTML", value: artifactHTML, systemImage: "chevron.left.forwardslash.chevron.right")
                    Button {
                        shareHTMLFile()
                    } label: {
                        Label("Share HTML file…", systemImage: "doc.richtext")
                    }
                } header: {
                    Text("Advanced")
                }

                if let copiedLabel {
                    Section {
                        Text("Copied: \(copiedLabel)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Export draft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $isSharing) {
                ActivityView(activityItems: shareItems)
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    private var canExportAsPNG: Bool {
        switch payload {
        case .palette(let o): return o.indices.contains(directionIndex)
        case .ui(let o): return o.indices.contains(directionIndex)
        default: return false
        }
    }

    private var photoShareURLs: String? {
        DraftExportFormatters.photoReferenceList(payload: payload, directionIndex: directionIndex)
    }

    private func copyRow(_ title: String, value: String, systemImage: String) -> some View {
        Button {
            UIPasteboard.general.string = value
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            copiedLabel = title
        } label: {
            Label(title, systemImage: systemImage)
        }
    }

    private func openInExternalTool(_ tool: DraftExternalOpenTool) {
        let text = tool.pasteboardString(artifactHTML: artifactHTML, payload: payload, directionIndex: directionIndex)
        UIPasteboard.general.string = text
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        copiedLabel = "Copied for \(tool.title)"
        openURL(tool.destinationURL)
    }

    @MainActor
    private func exportAsPNG() {
        let card = DraftExportCard(payload: payload, directionIndex: directionIndex)
            .frame(width: 390)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        guard let image = renderer.uiImage else { return }
        shareItems = [image]
        isSharing = true
    }

    private func shareHTMLFile() {
        do {
            let url = try DraftExportFileWriter.writeHTMLToTemporaryFile(html: artifactHTML)
            shareItems = [url]
            isSharing = true
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}
