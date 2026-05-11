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

    static func writePlainTextToTemporaryFile(_ text: String, filenameBase: String) throws -> URL {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let stamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(filenameBase)-\(stamp).txt")
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

enum DraftExportFormatters {
    /// Tab-separated name + hex for spreadsheet / Illustrator workflows.
    static func illustratorSwatchTSV(payload: ArtifactPayload, directionIndex: Int) -> String? {
        guard case .palette(let options) = payload,
              options.indices.contains(directionIndex) else { return nil }
        let swatches = options[directionIndex].swatches
        guard !swatches.isEmpty else { return nil }
        return swatches.map { "\($0.name)\t\($0.hex)" }.joined(separator: "\n")
    }

    /// Single-row SVG strip; paste into Figma on the canvas.
    static func figmaPaletteSVG(payload: ArtifactPayload, directionIndex: Int) -> String? {
        guard case .palette(let options) = payload,
              options.indices.contains(directionIndex) else { return nil }
        let swatches = options[directionIndex].swatches
        guard !swatches.isEmpty else { return nil }
        let cell: CGFloat = 100
        let height = cell
        let width = cell * CGFloat(swatches.count)
        var rects = ""
        for (i, s) in swatches.enumerated() {
            let x = CGFloat(i) * cell
            rects += #"<rect x="\#(x)" y="0" width="\#(cell)" height="\#(cell)" fill="\#(s.hex)"/>"#
            rects += "\n"
        }
        return """
        <svg xmlns="http://www.w3.org/2000/svg" width="\(Int(width))" height="\(Int(height))" viewBox="0 0 \(width) \(height)">
        \(rects)</svg>
        """
    }

    static func photoReferenceList(payload: ArtifactPayload, directionIndex: Int) -> String? {
        guard case .photos(let options) = payload,
              options.indices.contains(directionIndex) else { return nil }
        let photos = options[directionIndex].photos
        guard !photos.isEmpty else { return nil }
        return photos.map { p in
            var lines = [p.imageUrl, "  \(p.alt)", "  \(p.author) · \(p.source.rawValue) · \(p.detailUrl)"]
            return lines.joined(separator: "\n")
        }.joined(separator: "\n\n")
    }

    static func uiDirectionJSON(payload: ArtifactPayload, directionIndex: Int) -> String? {
        guard case .ui(let options) = payload,
              options.indices.contains(directionIndex) else { return nil }
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? enc.encode(options[directionIndex]) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func commaSeparatedHexes(payload: ArtifactPayload, directionIndex: Int) -> String? {
        guard case .palette(let options) = payload,
              options.indices.contains(directionIndex) else { return nil }
        let swatches = options[directionIndex].swatches
        guard !swatches.isEmpty else { return nil }
        return swatches.map(\.hex).joined(separator: ", ")
    }
}

// MARK: - Export sheet

struct DraftExportSheet: View {
    let artifactHTML: String
    let payload: ArtifactPayload
    let directionIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var shareItems: [Any] = []
    @State private var isSharing = false
    @State private var copiedLabel: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        shareHTMLFile()
                    } label: {
                        Label("Share HTML file…", systemImage: "doc.richtext")
                    }

                    Button {
                        shareCompanionTextIfPossible()
                    } label: {
                        Label("Share bundle (HTML + references)", systemImage: "square.stack.3d.up")
                    }
                } header: {
                    Text("Share")
                } footer: {
                    Text("Use AirDrop, Mail, or Save to Files. HTML opens in a browser; design tools can import or reference assets from the companion note when available.")
                }

                Section {
                    if let s = DraftExportFormatters.illustratorSwatchTSV(payload: payload, directionIndex: directionIndex) {
                        copyRow("Copy for Illustrator (names + hex)", value: s, systemImage: "eyedropper.halffull")
                    }
                    if let s = DraftExportFormatters.commaSeparatedHexes(payload: payload, directionIndex: directionIndex) {
                        copyRow("Copy hex list (comma-separated)", value: s, systemImage: "number")
                    }
                    if let s = DraftExportFormatters.figmaPaletteSVG(payload: payload, directionIndex: directionIndex) {
                        copyRow("Copy SVG strip for Figma", value: s, systemImage: "rectangle.split.3x1")
                    }
                    if let s = DraftExportFormatters.photoReferenceList(payload: payload, directionIndex: directionIndex) {
                        copyRow("Copy image URLs + credits", value: s, systemImage: "photo.on.rectangle.angled")
                    }
                    if let s = DraftExportFormatters.uiDirectionJSON(payload: payload, directionIndex: directionIndex) {
                        copyRow("Copy UI direction (JSON)", value: s, systemImage: "curlybraces")
                    }
                    if let s = ArtifactPayloadParser.primaryEmbeddedJSONString(html: artifactHTML) {
                        copyRow("Copy structured draft data (JSON)", value: s, systemImage: "doc.text")
                    }
                    copyRow("Copy raw HTML", value: artifactHTML, systemImage: "chevron.left.forwardslash.chevron.right")
                } header: {
                    Text("Copy")
                } footer: {
                    Text("In Figma, paste the SVG on the canvas. In Illustrator, paste hex lists or build swatches from the TSV in a spreadsheet.")
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

    private func copyRow(_ title: String, value: String, systemImage: String) -> some View {
        Button {
            copyToClipboard(value, label: title)
        } label: {
            Label(title, systemImage: systemImage)
        }
    }

    private func copyToClipboard(_ string: String, label: String) {
        UIPasteboard.general.string = string
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        copiedLabel = label
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

    private func shareCompanionTextIfPossible() {
        do {
            let htmlURL = try DraftExportFileWriter.writeHTMLToTemporaryFile(html: artifactHTML)
            var items: [Any] = [htmlURL]

            if let companion = companionText(), !companion.isEmpty {
                let txtURL = try DraftExportFileWriter.writePlainTextToTemporaryFile(companion, filenameBase: "Draft-refs")
                items.append(txtURL)
            }

            shareItems = items
            isSharing = true
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func companionText() -> String? {
        if let photos = DraftExportFormatters.photoReferenceList(payload: payload, directionIndex: directionIndex) {
            return photos
        }
        if let json = ArtifactPayloadParser.primaryEmbeddedJSONString(html: artifactHTML) {
            return json
        }
        return nil
    }
}
