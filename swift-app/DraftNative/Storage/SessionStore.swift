import Foundation

protocol SessionStoring {
    func loadTranscript() -> String
    func saveTranscript(_ value: String)
    func loadArtifactHTML() -> String
    func saveArtifactHTML(_ value: String)
    func clear()
}

struct SessionStore: SessionStoring {
    private let defaults = UserDefaults.standard
    private let transcriptKey = "draft.native.session.transcript"
    private let artifactKey = "draft.native.session.artifact"

    func loadTranscript() -> String {
        defaults.string(forKey: transcriptKey) ?? ""
    }

    func saveTranscript(_ value: String) {
        defaults.set(value, forKey: transcriptKey)
    }

    func loadArtifactHTML() -> String {
        defaults.string(forKey: artifactKey) ?? ""
    }

    func saveArtifactHTML(_ value: String) {
        defaults.set(value, forKey: artifactKey)
    }

    func clear() {
        defaults.removeObject(forKey: transcriptKey)
        defaults.removeObject(forKey: artifactKey)
    }
}
