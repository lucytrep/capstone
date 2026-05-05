import AVFoundation
import Foundation
import Speech

@MainActor
final class SpeechRecognizer: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var isListening = false
    @Published var statusMessage = "Speak clearly and pause when finished"
    @Published var errorMessage = ""
    @Published private(set) var speechAuthorized = false
    @Published private(set) var microphoneAuthorized = false

    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func requestPermissions() async {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        speechAuthorized = speechStatus == .authorized

        let micAllowed = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }

        microphoneAuthorized = micAllowed

        if !speechAuthorized || !microphoneAuthorized {
            statusMessage = "Voice is unavailable. You can still type a prompt."
        }
    }

    func toggleListening(seedTranscript: String) async {
        if isListening {
            stopListening()
            return
        }

        errorMessage = ""
        transcript = seedTranscript

        if !speechAuthorized || !microphoneAuthorized {
            await requestPermissions()
            if !speechAuthorized || !microphoneAuthorized {
                errorMessage = "Microphone or speech permissions were denied."
                return
            }
        }

        do {
            try startListening()
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Voice capture failed. Try again."
            stopListening()
        }
    }

    func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        isListening = false
        if transcript.isEmpty {
            statusMessage = "Speak clearly and pause when finished"
        } else {
            statusMessage = "Voice capture finished."
        }
    }

    private func startListening() throws {
        guard let recognizer, recognizer.isAvailable else {
            throw NSError(domain: "DraftNativeSpeech", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Speech recognition is not available right now."
            ])
        }

        stopListening()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        statusMessage = "Listening..."
        isListening = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
                Task { @MainActor in
                    self.transcript = text
                    self.statusMessage = result.isFinal ? "Voice capture finished." : "Listening..."
                }

                if result.isFinal {
                    Task { @MainActor in
                        self.stopListening()
                    }
                }
            }

            if let error {
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                    self.statusMessage = "Voice capture failed. Try again."
                    self.stopListening()
                }
            }
        }
    }
}
