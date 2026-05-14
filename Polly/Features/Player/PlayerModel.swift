import Foundation
import AVFoundation
import Combine

/// 播放器状态机：协调 AVPlayer / 字幕索引 / 控件操作。
final class PlayerModel: ObservableObject {

    // MARK: - Output
    let player: AVPlayer
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var subtitle: SubtitleDocument?
    @Published private(set) var currentSegmentId: Int = 0
    @Published private(set) var isReady: Bool = false
    /// 当前单句循环的 segment id；nil 表示不循环。
    @Published private(set) var loopSegmentId: Int? = nil
    /// 整段循环（视频播完自动重新开始）
    @Published var videoLoop: Bool = false
    /// 当前播放速率
    @Published private(set) var playbackRate: Float = 1.0

    // MARK: - Private
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?

    /// 手动选句时，临时锁定 currentSegmentId 不被 currentTime 反向覆盖，
    /// 避免 seek 完成前后 currentTime 在 segment 边界附近抖动导致句子跳变。
    private var manualSelectLockId: Int?

    // MARK: - Init
    init(videoURL: URL, subtitleVideoId: String?) {
        // 配置 AVAudioSession 为播放模式，让模拟器/真机静音键开启也能出声音。
        Self.configureAudioSession()

        let item = AVPlayerItem(url: videoURL)
        self.player = AVPlayer(playerItem: item)
        self.player.automaticallyWaitsToMinimizeStalling = true

        if let id = subtitleVideoId {
            self.subtitle = SubtitleService.load(videoId: id)
        }

        attachTimeObserver()
        observeDurationFallback(item: item)

        // KVO 监听 status：ready → 自动 play（如果 isPlaying 已被 onAppear 标记）
        statusObservation = item.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            guard let self else { return }
            if item.status == .readyToPlay {
                DispatchQueue.main.async {
                    self.isReady = true
                    self.refreshDuration()
                    if self.isPlaying {
                        self.player.play()
                    }
                }
            }
        }
    }

    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
    }

    /// 注入字幕（远端拉到的 / 外部生成的）。覆盖 init 时的 bundle 加载结果。
    /// 当 video.subtitleURL 非空时，PlayerView 用 SubtitleService.loadAsync 拉好后调这个。
    func setSubtitle(_ doc: SubtitleDocument) {
        self.subtitle = doc
    }

    // MARK: - Setup

    private static func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession configure failed: \(error)")
        }
    }

    private func attachTimeObserver() {
        // 30 fps tick：兼顾 currentTime 平滑度与电耗
        let interval = CMTime(value: 1, timescale: 30)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] t in
            guard let self else { return }
            self.currentTime = CMTimeGetSeconds(t)
            self.checkLoop()
            self.updateCurrentSegment()
        }
    }

    /// 单句循环检查（文档 03.8）：当前时间到达循环段尾部时 seek 回起点。
    private func checkLoop() {
        guard let loopId = loopSegmentId,
              let segs = subtitle?.segments,
              loopId < segs.count else { return }
        let seg = segs[loopId]
        if currentTime >= seg.end - 0.05 {
            player.seek(to: CMTime(seconds: seg.start, preferredTimescale: 600),
                        toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }

    private func observeDurationFallback(item: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.timeJumpedNotification,
            object: item, queue: .main
        ) { [weak self] _ in
            self?.refreshDuration()
        }
        // 视频播完时若开启了整段循环，自动回到开头
        NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if self.videoLoop {
                self.player.seek(to: .zero) { [weak self] _ in
                    self?.player.play()
                    self?.player.rate = self?.playbackRate ?? 1.0
                    self?.isPlaying = true
                }
            } else {
                self.isPlaying = false
            }
        }
        Task { @MainActor [weak self] in
            for _ in 0..<60 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                self?.refreshDuration()
                if (self?.duration ?? 0) > 0 { break }
            }
        }
    }

    private func refreshDuration() {
        let d = CMTimeGetSeconds(player.currentItem?.duration ?? .zero)
        if d.isFinite && d > 0 { duration = d }
    }

    /// currentTime 推进时根据时间戳更新当前句。
    /// 手动选句加锁期间不更新，避免抖动。
    private func updateCurrentSegment() {
        // 如果手动锁定中：currentTime 进入锁定 segment 范围内才解锁
        if let lockId = manualSelectLockId,
           let segs = subtitle?.segments,
           lockId < segs.count {
            let seg = segs[lockId]
            if currentTime >= seg.start && currentTime <= seg.end {
                manualSelectLockId = nil  // 解锁，恢复正常跟随
            }
            return
        }

        guard let segs = subtitle?.segments,
              let idx = segs.currentIndex(at: currentTime),
              idx != currentSegmentId else { return }
        currentSegmentId = idx
    }

    // MARK: - Actions

    func play() {
        guard !isPlaying else { return }
        player.play()
        player.rate = playbackRate  // 恢复速率（暂停后 rate 会被清掉）
        isPlaying = true
    }

    func pause() {
        guard isPlaying else { return }
        player.pause()
        isPlaying = false
    }

    func togglePlay() {
        if isPlaying { pause() } else { play() }
    }

    func setRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying { player.rate = rate }
    }

    func seek(by delta: Double) {
        let target = Swift.max(0, Swift.min(duration, currentTime + delta))
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600),
                    toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func seekTo(progress: Double) {
        guard duration > 0 else { return }
        let target = Swift.max(0, Swift.min(duration, progress * duration))
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600),
                    toleranceBefore: .zero, toleranceAfter: .zero)
    }

    /// 手动选句：立即更新 currentSegmentId + 加锁 + seek。
    /// seek completion 不解锁——而是等 currentTime 真的进入这段后由 updateCurrentSegment 解锁。
    func seekToSegment(_ id: Int) {
        guard let segs = subtitle?.segments,
              id >= 0, id < segs.count else { return }
        let seg = segs[id]
        manualSelectLockId = id
        currentSegmentId = id
        // seek 用 tolerance positive infinity：宁可 seek 到 segment 内部也别落在 segment.start 之前
        player.seek(to: CMTime(seconds: seg.start, preferredTimescale: 600),
                    toleranceBefore: .zero,
                    toleranceAfter: CMTime(seconds: 0.05, preferredTimescale: 600))
    }

    func previousSegment() {
        seekToSegment(currentSegmentId - 1)
    }

    func nextSegment() {
        seekToSegment(currentSegmentId + 1)
    }

    /// 切换单句循环（文档 03.8）：双击同一句取消循环。
    func toggleLoop(segmentId: Int) {
        if loopSegmentId == segmentId {
            loopSegmentId = nil
        } else {
            loopSegmentId = segmentId
            seekToSegment(segmentId)
            // 循环态下持续显示控件
            if !isPlaying { togglePlay() }
        }
    }
}
