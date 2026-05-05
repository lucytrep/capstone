import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var speechRecognizer = SpeechRecognizer()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0x30171D),
                    Color(hex: 0x6D244F),
                    Color(hex: 0xC15A95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 20)

                VStack(spacing: 14) {
                    Text("Draft")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.95))

                    Text(appModel.transcript.isEmpty ? "Tap to dictate" : appModel.transcript)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)

                    Text(speechRecognizer.errorMessage.isEmpty ? speechRecognizer.statusMessage : speechRecognizer.errorMessage)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }

                TextEditor(text: Binding(
                    get: { appModel.transcript },
                    set: { appModel.updateTranscript($0) }
                ))
                .scrollContentBackground(.hidden)
                .padding(18)
                .frame(minHeight: 160)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.white.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )
                )
                .foregroundStyle(.white)

                VStack(spacing: 14) {
                    Button {
                        Task {
                            await speechRecognizer.toggleListening(seedTranscript: appModel.transcript)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(speechRecognizer.isListening ? 0.28 : 0.18))
                                .frame(width: 118, height: 118)

                            Circle()
                                .fill(Color.white.opacity(0.92))
                                .frame(width: 92, height: 92)

                            Image(systemName: speechRecognizer.isListening ? "waveform.circle.fill" : "mic.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(Color(hex: 0xB74989))
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        appModel.startFlow()
                    } label: {
                        Text("Generate")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(appModel.canGenerate ? Color.white : Color.white.opacity(0.35))
                            .foregroundStyle(Color(hex: 0x541A3B))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .disabled(!appModel.canGenerate)
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
        }
        .task {
            await speechRecognizer.requestPermissions()
        }
        .onReceive(speechRecognizer.$transcript) { value in
            guard value != appModel.transcript else { return }
            appModel.updateTranscript(value)
        }
        .fullScreenCover(isPresented: $appModel.isFlowPresented) {
            GenerationFlowView()
                .environmentObject(appModel)
        }
    }
}
