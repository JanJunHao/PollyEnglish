import AVFoundation

/// 单词朗读服务（AVSpeechSynthesizer 系统 TTS）。
/// singleton 保持 synthesizer 活着，避免播放中被释放打断。
@MainActor
final class SpeechService {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()
    private init() {}

    /// 默认 en-US 美音；rate 0.45 接近正常语速。
    func speak(_ text: String, language: String = "en-US", rate: Float = 0.45) {
        synthesizer.stopSpeaking(at: .immediate)
        let utt = AVSpeechUtterance(string: text)
        utt.voice = AVSpeechSynthesisVoice(language: language)
        utt.rate = rate
        utt.pitchMultiplier = 1.0
        synthesizer.speak(utt)
    }
}
