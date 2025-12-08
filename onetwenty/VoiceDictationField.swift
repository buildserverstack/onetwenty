import SwiftUI
import Speech
import AVFoundation
import Combine

struct VoiceDictationField: View {
    @Binding var text: String
    var placeholder: String

    @StateObject private var controller = SpeechDictationController()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.25))
                    )
                    .padding(.top, 4)

                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 12)
                }
            }

            HStack(spacing: 12) {
                Button {
                    toggleDictation()
                } label: {
                    Label(controller.isListening ? "Stop Dictation" : "Dictate", systemImage: controller.isListening ? "stop.circle.fill" : "mic.fill")
                }
                .buttonStyle(.borderedProminent)

                if !controller.statusMessage.isEmpty {
                    Text(controller.statusMessage)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func toggleDictation() {
        if controller.isListening {
            controller.stopDictation()
        } else {
            controller.startDictation(seedText: text) { updated in
                text = updated
            }
        }
    }
}

final class SpeechDictationController: ObservableObject {
    @Published var isListening = false
    @Published var statusMessage = ""

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer()
    private var seededText: String = ""

    func startDictation(seedText: String, onUpdate: @escaping (String) -> Void) {
        stopDictation()
        seededText = seedText
        statusMessage = "Requesting permission…"

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                guard let self else { return }

                switch status {
                case .authorized:
                    self.beginSession(onUpdate: onUpdate)
                case .denied:
                    self.statusMessage = "Microphone access denied."
                case .restricted:
                    self.statusMessage = "Speech recognition restricted."
                case .notDetermined:
                    self.statusMessage = "Speech permission not determined."
                @unknown default:
                    self.statusMessage = "Speech permission unavailable."
                }
            }
        }
    }

    func stopDictation() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isListening = false
        statusMessage = ""
    }

    private func beginSession(onUpdate: @escaping (String) -> Void) {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            statusMessage = "Speech recognizer unavailable."
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak request] buffer, _ in
            request?.append(buffer)
        }

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let transcript = result.bestTranscription.formattedString
                let combined = self.seededText.isEmpty ? transcript : "\(self.seededText) \(transcript)"
                DispatchQueue.main.async {
                    onUpdate(combined)
                }

                if result.isFinal {
                    self.stopDictation()
                }
            }

            if let error {
                DispatchQueue.main.async {
                    self.statusMessage = "Dictation error: \(error.localizedDescription)"
                    self.stopDictation()
                }
            }
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isListening = true
            statusMessage = "Listening…"
        } catch {
            statusMessage = "Audio engine error: \(error.localizedDescription)"
        }
    }

}

#Preview {
    VoiceDictationField(text: .constant(""), placeholder: "Dictated notes")
        .padding()
}
