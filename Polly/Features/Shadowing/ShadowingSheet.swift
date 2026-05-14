import SwiftUI
import AVFoundation

/// 跟读评分骨架：录音 + 回放当前句。评分接口未接，按钮显示占位分数。
/// 上线前接 Whisper 转文本 + 自研对齐评分（plan 文档 04.13 策略 2）。
struct ShadowingSheet: View {
    let referenceText: String
    let referenceTranslation: String?
    let onClose: () -> Void

    @StateObject private var recorder = ShadowingRecorder()

    var body: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                header
                referenceCard

                Spacer()

                statusArea

                Spacer()

                controls
                tip
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .task { await recorder.requestPermissionIfNeeded() }
        .onDisappear { recorder.cleanup() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("跟读评分")
                    .font(AppFonts.display(22, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("AI 评分功能 ✦ 即将开放")
                    .font(AppFonts.body(11))
                    .foregroundColor(AppColors.aiPrimary)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColors.bgElevated))
            }
            .buttonStyle(.plain)
        }
    }

    private var referenceCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("跟读这句")
                .font(AppFonts.body(11, weight: .semibold))
                .tracking(0.5)
                .foregroundColor(AppColors.textTertiary)
            Text(referenceText)
                .font(AppFonts.body(17, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
            if let zh = referenceTranslation, !zh.isEmpty {
                Text(zh)
                    .font(AppFonts.body(12))
                    .foregroundColor(AppColors.subtitleChinese)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }

    // MARK: - Status

    private var statusArea: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(recorder.isRecording ? Color.red.opacity(0.18) : AppColors.brandPrimary.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .scaleEffect(recorder.isRecording ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: recorder.isRecording)
                Image(systemName: recorder.isRecording ? "waveform" : (recorder.hasRecording ? "checkmark" : "mic.fill"))
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(recorder.isRecording ? .red : AppColors.brandPrimary)
            }
            Text(statusText)
                .font(AppFonts.body(14, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private var statusText: String {
        if let err = recorder.errorMessage { return err }
        if recorder.isRecording { return "录音中… \(String(format: "%.1f", recorder.elapsed))s" }
        if recorder.isPlaying { return "回放中…" }
        if recorder.hasRecording { return "录音完成 · 可回放或重录" }
        return "点击麦克风开始跟读"
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: AppSpacing.md) {
            if recorder.hasRecording {
                actionButton(title: "回放", icon: "play.fill", color: AppColors.brandPrimary, filled: false) {
                    recorder.playback()
                }
                actionButton(title: "重录", icon: "arrow.counterclockwise", color: AppColors.textPrimary, filled: false) {
                    recorder.discard()
                }
                actionButton(title: "AI 评分", icon: "sparkle", color: AppColors.aiPrimary, filled: true) {
                    // 占位：未来调 POST /v1/shadowing/score
                }
            } else {
                actionButton(
                    title: recorder.isRecording ? "停止" : "开始录音",
                    icon: recorder.isRecording ? "stop.fill" : "mic.fill",
                    color: AppColors.brandPrimary,
                    filled: true
                ) {
                    if recorder.isRecording { recorder.stop() } else { recorder.start() }
                }
            }
        }
    }

    private func actionButton(title: String, icon: String, color: Color, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon).font(.system(size: 14, weight: .bold))
                Text(title).font(AppFonts.body(14, weight: .semibold))
            }
            .foregroundColor(filled ? .black : color)
            .padding(.horizontal, AppSpacing.lg)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(filled ? color : AppColors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
        }
        .buttonStyle(.plain)
    }

    private var tip: some View {
        Text("AI 评分功能（错音定位、音节准确度）正在接入，稍后上线。")
            .font(AppFonts.body(11))
            .foregroundColor(AppColors.textTertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSpacing.lg)
    }
}

// MARK: - Recorder

@MainActor
final class ShadowingRecorder: NSObject, ObservableObject, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var hasRecording = false
    @Published var elapsed: Double = 0
    @Published var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var fileURL: URL?

    func requestPermissionIfNeeded() async {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            return
        case .denied:
            errorMessage = "麦克风权限被拒绝，请到设置开启"
        case .undetermined:
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                session.requestRecordPermission { _ in cont.resume() }
            }
        @unknown default:
            break
        }
    }

    func start() {
        errorMessage = nil
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            errorMessage = "音频会话失败：\(error.localizedDescription)"
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("polly-shadow-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        do {
            let rec = try AVAudioRecorder(url: url, settings: settings)
            rec.delegate = self
            rec.isMeteringEnabled = true
            rec.record()
            self.recorder = rec
            self.fileURL = url
            self.isRecording = true
            self.elapsed = 0
            startTimer()
        } catch {
            errorMessage = "录音失败：\(error.localizedDescription)"
        }
    }

    func stop() {
        recorder?.stop()
        recorder = nil
        timer?.invalidate(); timer = nil
        isRecording = false
        hasRecording = (fileURL != nil)
    }

    func playback() {
        guard let url = fileURL else { return }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.play()
            self.player = p
            self.isPlaying = true
        } catch {
            errorMessage = "回放失败：\(error.localizedDescription)"
        }
    }

    func discard() {
        if let url = fileURL { try? FileManager.default.removeItem(at: url) }
        fileURL = nil
        hasRecording = false
        elapsed = 0
        errorMessage = nil
    }

    func cleanup() {
        recorder?.stop(); recorder = nil
        player?.stop(); player = nil
        timer?.invalidate(); timer = nil
        if let url = fileURL { try? FileManager.default.removeItem(at: url); fileURL = nil }
        isRecording = false
        isPlaying = false
        hasRecording = false
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isRecording else { return }
                self.elapsed = self.recorder?.currentTime ?? 0
            }
        }
    }

    // MARK: - AVAudioPlayerDelegate

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.isPlaying = false }
    }
}
