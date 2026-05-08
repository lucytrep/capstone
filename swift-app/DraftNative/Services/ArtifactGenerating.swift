import Foundation

struct GeneratedArtifact {
    let html: String
}

protocol ArtifactGenerating {
    func generateArtifact(from prompt: String) async throws -> GeneratedArtifact
}

enum ArtifactGenerationError: LocalizedError {
    case unavailableBackend
    case unavailableImageGeneration

    var errorDescription: String? {
        switch self {
        case .unavailableBackend:
            return "The native app is scaffolded, but the backend generator still needs to be wired up."
        case .unavailableImageGeneration:
            return "Image generation is unavailable right now. Check the configured image providers and try again."
        }
    }
}
