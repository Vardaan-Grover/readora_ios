import AVFoundation
import Foundation

@MainActor
final class PronunciationService {
    static let shared = PronunciationService()
    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    func speak(_ text: String, language: String = "en-US", rate: Float? = nil) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        if let rate = rate {
            utterance.rate = rate
        }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
