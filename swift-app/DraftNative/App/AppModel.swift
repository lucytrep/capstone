import Foundation

@MainActor
final class AppModel: ObservableObject {
    enum GenerationState: Equatable {
        case idle
        case generating
        case failed(String)
        case ready
    }

    @Published var transcript: String
    @Published var artifactHTML: String
    @Published var generationState: GenerationState = .idle
    @Published var isFlowPresented = false
    @Published var pendingLibraryNavigation = false
    @Published var boards: [LibraryBoard] = LibrarySeedData.boards

    private let sessionStore: SessionStoring
    private let generator: ArtifactGenerating
    private var generationTask: Task<Void, Never>?

    init(
        sessionStore: SessionStoring = SessionStore(),
        generator: ArtifactGenerating = MockArtifactGenerator()
    ) {
        self.sessionStore = sessionStore
        self.generator = generator
        self.transcript = sessionStore.loadTranscript()
        self.artifactHTML = sessionStore.loadArtifactHTML()

        if !artifactHTML.isEmpty {
            generationState = .ready
        }
    }

    var canGenerate: Bool {
        !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func updateTranscript(_ value: String) {
        transcript = value
        sessionStore.saveTranscript(value)
    }

    func startFlow() {
        guard canGenerate, !isFlowPresented else { return }
        generationTask?.cancel()
        artifactHTML = ""
        sessionStore.saveArtifactHTML("")
        generationState = .generating
        isFlowPresented = true
        generationTask = Task { [weak self] in
            await self?.generateArtifact()
        }
    }

    func generateArtifact() async {
        let prompt = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else {
            generationState = .failed("Add a prompt before generating.")
            return
        }

        generationState = .generating

        do {
            let artifact = try await generator.generateArtifact(from: prompt)
            guard !Task.isCancelled else { return }
            artifactHTML = artifact.html
            sessionStore.saveArtifactHTML(artifact.html)
            generationState = .ready
        } catch {
            guard !Task.isCancelled else { return }
            generationState = .failed(error.localizedDescription)
        }
    }

    func retryGeneration() async {
        generationTask?.cancel()
        await generateArtifact()
    }

    func dismissFlow() {
        generationTask?.cancel()
        generationTask = nil
        transcript = ""
        artifactHTML = ""
        generationState = .idle
        isFlowPresented = false
        sessionStore.saveTranscript("")
        sessionStore.saveArtifactHTML("")
    }

    func dismissFlowToLibrary() {
        pendingLibraryNavigation = true
        dismissFlow()
    }

    func moveItems(itemIDs: Set<String>, from sourceBoardID: String, to destinationBoardID: String) {
        guard let srcIdx = boards.firstIndex(where: { $0.id == sourceBoardID }),
              let dstIdx = boards.firstIndex(where: { $0.id == destinationBoardID }) else { return }
        let toMove = boards[srcIdx].items.filter { itemIDs.contains($0.id) }
        let remaining = boards[srcIdx].items.filter { !itemIDs.contains($0.id) }
        let src = boards[srcIdx]
        boards[srcIdx] = LibraryBoard(id: src.id, promptTitle: src.promptTitle, itemCount: remaining.count, updatedAtLabel: "Just now", generationID: src.generationID, items: remaining)
        let dst = boards[dstIdx]
        let merged = dst.items + toMove
        boards[dstIdx] = LibraryBoard(id: dst.id, promptTitle: dst.promptTitle, itemCount: merged.count, updatedAtLabel: "Just now", generationID: dst.generationID, items: merged)
    }

    func copyItems(itemIDs: Set<String>, from sourceBoardID: String, to destinationBoardID: String) {
        guard let srcIdx = boards.firstIndex(where: { $0.id == sourceBoardID }),
              let dstIdx = boards.firstIndex(where: { $0.id == destinationBoardID }) else { return }
        let toCopy = boards[srcIdx].items.filter { itemIDs.contains($0.id) }
        let dst = boards[dstIdx]
        let merged = dst.items + toCopy
        boards[dstIdx] = LibraryBoard(id: dst.id, promptTitle: dst.promptTitle, itemCount: merged.count, updatedAtLabel: "Just now", generationID: dst.generationID, items: merged)
    }

    func removeItems(itemIDs: Set<String>, from boardID: String) {
        guard let idx = boards.firstIndex(where: { $0.id == boardID }) else { return }
        let remaining = boards[idx].items.filter { !itemIDs.contains($0.id) }
        let board = boards[idx]
        boards[idx] = LibraryBoard(id: board.id, promptTitle: board.promptTitle, itemCount: remaining.count, updatedAtLabel: "Just now", generationID: board.generationID, items: remaining)
    }

    func resetSession() {
        generationTask?.cancel()
        generationTask = nil
        transcript = ""
        artifactHTML = ""
        generationState = .idle
        isFlowPresented = false
        sessionStore.clear()
    }
}
