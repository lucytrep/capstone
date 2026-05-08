import AVFoundation
import Foundation
import Speech
import SwiftUI

@MainActor
final class SpeechRecognizer: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var isListening = false
    @Published var statusMessage = "Speak clearly and pause when finished"
    @Published var errorMessage = ""
    @Published private(set) var speechAuthorized = false
    @Published private(set) var microphoneAuthorized = false
    @Published private(set) var canUseVoice = true
    @Published private(set) var completedTranscriptionCount = 0

    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isFinishingRecognition = false
    private var shouldPublishCompletionOnStop = false

    func requestPermissions() async {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        speechAuthorized = speechStatus == .authorized

        let micAllowed = await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            }
        }

        microphoneAuthorized = micAllowed
        canUseVoice = speechAuthorized && microphoneAuthorized

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
                canUseVoice = false
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

    func stopListening(shouldSubmit: Bool = true) {
        isFinishingRecognition = true
        shouldPublishCompletionOnStop = shouldSubmit
        recognitionRequest?.endAudio()
        teardownAudio()

        recognitionTask?.finish()
        recognitionTask = nil
        recognitionRequest = nil

        finalizeStoppedState()
    }

    private func startListening() throws {
        guard let recognizer, recognizer.isAvailable else {
            throw NSError(domain: "DraftNativeSpeech", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Speech recognition is not available right now."
            ])
        }

        stopListening(shouldSubmit: false)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request
        isFinishingRecognition = false

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
                    if self.isFinishingRecognition {
                        self.isFinishingRecognition = false
                        self.finalizeStoppedState()
                        return
                    }

                    self.errorMessage = error.localizedDescription
                    self.statusMessage = "Voice capture failed. Try again."
                    self.teardownAudio()
                    self.recognitionTask = nil
                    self.recognitionRequest = nil
                    self.isListening = false
                }
            }
        }
    }

    private func teardownAudio() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)

        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Ignore deactivation failures; they should not block the UI state reset.
        }
    }

    private func finalizeStoppedState() {
        isListening = false
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTranscript.isEmpty {
            statusMessage = "Speak clearly and pause when finished"
        } else {
            statusMessage = "Voice capture finished."
        }

        if shouldPublishCompletionOnStop && !trimmedTranscript.isEmpty {
            completedTranscriptionCount += 1
        }

        shouldPublishCompletionOnStop = false
    }
}
