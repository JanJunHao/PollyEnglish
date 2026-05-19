import SwiftUI
import SwiftData

/// 文件 tab（设计交付 v2 §三）：视频导入入口 + 已导入列表。
struct FilesView: View {
    @Environment(\.theme) private var theme
    @Query(sort: \LocalVideo.importedAt, order: .reverse) private var localVideos: [LocalVideo]

    @State private var showImportSheet = false
    @State private var showYouTubeNotice = false

    /// 加工中（pending / running）的条数。
    private var processingCount: Int {
        localVideos.filter { ImportStatus($0.subtitleStatus) != .ready }.count
    }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("文件")
                        .font(AppFonts.body(17, weight: .semibold))
                        .foregroundColor(theme.text)
                        .padding(.horizontal, 22)
                        .padding(.top, 10)

                    heroTitle
                    importTiles
                    aiHintBar
                    importedSection
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showImportSheet) {
            ImportLocalVideoSheet()
        }
        .alert("YouTube 导入即将开放", isPresented: $showYouTubeNotice) {
            Button("好") {}
        } message: {
            Text("正在打通服务端下载与 AI 加工管线，敬请期待。当前可先用「相册视频」导入本地文件。")
        }
    }

    // MARK: - 大标题

    private var heroTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Import a video")
                .font(AppFonts.display(32, weight: .medium))
                .foregroundColor(theme.text)
            Text("任何视频都能被 AI 加工成一节精读课")
                .font(AppFonts.body(13))
                .foregroundColor(theme.textSec)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.top, 14)
        .padding(.bottom, 18)
    }

    // MARK: - 导入卡

    private var importTiles: some View {
        HStack(spacing: 10) {
            ImportTile(
                icon: "photo.fill",
                tint: theme.brand,
                label: "相册视频",
                hint: "从相册或文件",
                action: { showImportSheet = true }
            )
            ImportTile(
                icon: "link",
                tint: theme.ai,
                label: "YouTube 链接",
                hint: "粘贴视频网址",
                action: { showYouTubeNotice = true }
            )
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 18)
    }

    // MARK: - AI 能力提示条

    private var aiHintBar: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(theme.ai)
                .frame(width: 22, height: 22)
                .background(theme.ai.opacity(0.24), in: RoundedRectangle(cornerRadius: 6))

            (Text("AI 加工").foregroundColor(theme.aiText).fontWeight(.semibold)
             + Text(" · 自动识别音轨、生成英文字幕、翻译成中文、标注关键词。整个过程通常 2–5 分钟。"))
                .font(AppFonts.body(12))
                .foregroundColor(theme.textSec)
                .lineSpacing(3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [theme.ai.opacity(0.10), .clear],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(theme.ai.opacity(0.22), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 14)
        .padding(.bottom, 18)
    }

    // MARK: - 已导入列表

    private var importedSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("已导入 · \(localVideos.count)")
                    .font(AppFonts.body(13, weight: .medium))
                    .tracking(0.3)
                    .foregroundColor(theme.textSec)
                Spacer()
                if processingCount > 0 {
                    Text("\(processingCount) 项加工中")
                        .font(AppFonts.mono(10))
                        .foregroundColor(theme.textTer)
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 10)

            if localVideos.isEmpty {
                emptyHint
            } else {
                VStack(spacing: 8) {
                    ForEach(localVideos) { video in
                        ImportRow(video: video) { showImportSheet = true }
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }

    private var emptyHint: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray")
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(theme.textTer)
            Text("还没有导入视频")
                .font(AppFonts.body(13))
                .foregroundColor(theme.textTer)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

// MARK: - 导入状态

enum ImportStatus {
    case ready, processing, queued, failed

    init(_ raw: String) {
        switch raw {
        case "done":    self = .ready
        case "running": self = .processing
        case "failed":  self = .failed
        default:        self = .queued   // pending
        }
    }
}

// MARK: - 导入卡片

private struct ImportTile: View {
    @Environment(\.theme) private var theme
    let icon: String
    let tint: Color
    let label: String
    let hint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.22), in: RoundedRectangle(cornerRadius: 11))

                Spacer(minLength: 14)

                Text(label)
                    .font(AppFonts.body(14, weight: .semibold))
                    .foregroundColor(theme.text)
                Text(hint)
                    .font(AppFonts.body(11))
                    .foregroundColor(theme.textTer)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 124)
            .padding(14)
            .background(theme.surfaceElev)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadii.cardSmall).stroke(theme.divider, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 已导入行

private struct ImportRow: View {
    @Environment(\.theme) private var theme
    let video: LocalVideo
    let onTap: () -> Void

    private var status: ImportStatus { ImportStatus(video.subtitleStatus) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                statusThumb

                VStack(alignment: .leading, spacing: 0) {
                    Text(video.displayName)
                        .font(AppFonts.body(13.5, weight: .medium))
                        .foregroundColor(theme.text)
                        .lineLimit(1)

                    switch status {
                    case .ready:
                        Text("\(durationText) · 来自 相册 · \(importedText)")
                            .font(AppFonts.mono(10))
                            .foregroundColor(theme.textTer)
                            .padding(.top, 4)
                    case .processing:
                        processingDetail(stage: "生成字幕", animated: true)
                    case .queued:
                        processingDetail(stage: "排队中 · 等待 ASR", animated: false)
                    case .failed:
                        Text("加工失败 · 点按重试")
                            .font(AppFonts.mono(9.5, weight: .bold))
                            .foregroundColor(Color(hex: 0xFF6E6E))
                            .padding(.top, 6)
                    }
                }

                Spacer(minLength: 0)

                if status == .ready {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.textTer)
                }
            }
            .padding(12)
            .background(theme.surfaceElev)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadii.cardSmall).stroke(theme.divider, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
        }
        .buttonStyle(.plain)
    }

    /// 左侧 76×52 状态块。
    private var statusThumb: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(theme.surface)
            switch status {
            case .ready:
                ZStack {
                    Circle().fill(theme.brand).frame(width: 30, height: 30)
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .offset(x: 1)
                }
            case .processing:
                ProgressView()
                    .controlSize(.small)
                    .tint(theme.aiText)
            case .queued:
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textTer)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: 0xFF6E6E))
            }
        }
        .frame(width: 76, height: 52)
    }

    private func processingDetail(stage: String, animated: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(theme.ai)
                    .frame(width: 5, height: 5)
                    .opacity(animated ? 1 : 0.5)
                Text(animated ? "AI 加工中 · \(stage)" : stage)
                    .font(AppFonts.mono(9.5, weight: .bold))
                    .foregroundColor(theme.aiText)
            }
            if animated {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(theme.ai)
                    .frame(height: 2.5)
            } else {
                Capsule()
                    .fill(theme.chipBgActive)
                    .frame(height: 2.5)
            }
        }
        .padding(.top, 6)
    }

    private var durationText: String {
        let total = Int(video.durationSeconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private var importedText: String {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: video.importedAt),
                                      to: cal.startOfDay(for: Date())).day ?? 0
        switch days {
        case ..<1: return "今天"
        case 1:    return "昨天"
        default:   return "\(days) 天前"
        }
    }
}
