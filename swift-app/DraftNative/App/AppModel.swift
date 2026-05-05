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

    private let sessionStore: SessionStoring
    private let generator: ArtifactGenerating

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
        guard canGenerate else { return }
        generationState = .generating
        isFlowPresented = true
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
            artifactHTML = artifact.html
            sessionStore.saveArtifactHTML(artifact.html)
            generationState = .ready
        } catch {
            generationState = .failed(error.localizedDescription)
        }
    }

    func retryGeneration() async {
        await generateArtifact()
    }

    func dismissFlow() {
        isFlowPresented = false
    }

    func resetSession() {
        transcript = ""
        artifactHTML = ""
        generationState = .idle
        isFlowPresented = false
        sessionStore.clear()
    }
}
