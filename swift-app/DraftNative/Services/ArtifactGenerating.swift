import Foundation

struct GeneratedArtifact {
    let html: String
}

protocol ArtifactGenerating {
    func generateArtifact(from prompt: String) async throws -> GeneratedArtifact
}

enum ArtifactGenerationError: LocalizedError {
    case unavailableBackend

    var errorDescription: String? {
        switch self {
        case .unavailableBackend:
            return "The native app is scaffolded, but the backend generator still needs to be wired up."
        }
    }
}
