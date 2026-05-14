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
    /// After saving a draft from the output flow: switch to Drafts tab and scroll grids to the newest content.
    @Published var pendingLibrarySelectDraftsTab = false
    @Published var pendingLibraryScrollDraftsToBottom = false
    @Published var pendingLibraryScrollAllItemsToBottom = false
    @Published var pendingLibraryScrollIndividualViewToBottom = false
    @Published var boards: [LibraryBoard] = LibrarySeedData.boards
    /// Home rotating suggestions already used (exact line persisted).
    @Published private(set) var consumedIdlePromptLines: Set<String> = []

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
        self.consumedIdlePromptLines = Self.loadConsumedIdlePromptLines()

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

    func startFlow(consumingIdlePromptLine: String? = nil) {
        guard canGenerate, !isFlowPresented else { return }
        let trimmedPrompt = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if let suggestion = consumingIdlePromptLine?.trimmingCharacters(in: .whitespacesAndNewlines),
           !suggestion.isEmpty,
           trimmedPrompt.caseInsensitiveCompare(suggestion) == .orderedSame {
            var next = consumedIdlePromptLines
            if next.insert(suggestion).inserted {
                consumedIdlePromptLines = next
                Self.saveConsumedIdlePromptLines(next)
            }
        }
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
        let startedAt = Date()

        do {
            let artifact = try await generator.generateArtifact(from: prompt)
            guard !Task.isCancelled else { return }

            // Always show the generating animation for at least 2.4s so fast
            // local generations feel as intentional as slow API ones.
            let elapsed = Date().timeIntervalSince(startedAt)
            let remaining = 2.4 - elapsed
            if remaining > 0 {
                try? await Task.sleep(for: .seconds(remaining))
            }
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

    /// Saves the current artifact as a new board (end of Drafts), then dismisses the flow and focuses the library.
    func saveGeneratedDraftToLibrary(directionIndex: Int) {
        let prompt = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let html = artifactHTML.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !html.isEmpty, let board = GeneratedDraftLibraryImport.makeBoard(prompt: prompt, html: html, directionIndex: directionIndex) else {
            dismissFlow()
            return
        }
        boards.append(board)
        pendingLibraryNavigation = true
        pendingLibrarySelectDraftsTab = true
        pendingLibraryScrollDraftsToBottom = true
        pendingLibraryScrollAllItemsToBottom = true
        pendingLibraryScrollIndividualViewToBottom = true
        dismissFlow()
    }

    /// Removes a user-saved draft board and strips the same item IDs from every other board (and All items).
    func removeUserSavedBoard(id: String) {
        guard id.hasPrefix("user-saved-"), let snapshot = boards.first(where: { $0.id == id }) else { return }
        let ids = Set(snapshot.items.map(\.id))
        boards.removeAll { $0.id == id }
        removeItemsFromAllBoards(itemIDs: ids)
    }

    /// Removes any library item with these ids from **all** boards (e.g. after unsaving a draft whose assets were duplicated).
    func removeItemsFromAllBoards(itemIDs: Set<String>) {
        guard !itemIDs.isEmpty else { return }
        for idx in boards.indices {
            let b = boards[idx]
            let remaining = b.items.filter { !itemIDs.contains($0.id) }
            guard remaining.count != b.items.count else { continue }
            boards[idx] = LibraryBoard(
                id: b.id,
                promptTitle: b.promptTitle,
                itemCount: remaining.count,
                updatedAtLabel: "Just now",
                generationID: b.generationID,
                items: remaining
            )
        }
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

    func addItem(_ item: LibraryItem, to boardID: String) {
        guard let idx = boards.firstIndex(where: { $0.id == boardID }) else { return }
        let board = boards[idx]
        guard !board.items.contains(where: { $0.id == item.id }) else { return }

        let merged = board.items + [item]
        boards[idx] = LibraryBoard(
            id: board.id,
            promptTitle: board.promptTitle,
            itemCount: merged.count,
            updatedAtLabel: "Just now",
            generationID: board.generationID,
            items: merged
        )
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

    private static let consumedIdlePromptLinesKey = "draft.native.consumedIdlePromptLines"

    private static func loadConsumedIdlePromptLines() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: consumedIdlePromptLinesKey),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(decoded)
    }

    private static func saveConsumedIdlePromptLines(_ lines: Set<String>) {
        let sorted = lines.sorted()
        guard let data = try? JSONEncoder().encode(sorted) else { return }
        UserDefaults.standard.set(data, forKey: consumedIdlePromptLinesKey)
    }
}
