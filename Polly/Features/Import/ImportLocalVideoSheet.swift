import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers
import AVFoundation

/// 用户从「文件」app 选 mp4 / mov → 拷到 Application Support → WhisperKit 跑字幕。
/// 生成完字幕后，"开始学习"用 native PlayerView 走 AVPlayer 播本地文件 + Polly 字幕 UI。
struct ImportLocalVideoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    @Query(sort: \LocalVideo.importedAt, order: .reverse) private var localVideos: [LocalVideo]

    @State private var showPicker: Bool = false
    @State private var activeProgress: ActiveProgress?
    @State private var pendingError: String?
    @State private var playerHandoff: PlayerHandoff?

    struct ActiveProgress: Identifiable {
        let id: UUID
        var value: Double
        var label: String
    }

    struct PlayerHandoff: Identifiable {
        let id = UUID()
        let video: DemoVideo
        let subtitle: SubtitleDocument
    }

    var body: some View {
        ZStack {
            AppColors.bgPrimary.ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                header
                pickerButton
                if let progress = activeProgress { progressCard(progress: progress) }
                if let err = pendingError { errorCard(err) }
                list
            }
            .padding(AppSpacing.lg)
        }
        .sheet(isPresented: $showPicker) {
            DocumentPicker(types: [.movie, .audio]) { url in
                handlePicked(url: url)
            }
        }
        .fullScreenCover(item: $playerHandoff) { h in
            PlayerView(video: h.video, preloadedSubtitle: h.subtitle)
        }
    }

    // MARK: - UI

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("导入本地视频")
                    .font(AppFonts.display(22, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("文件 app 选 mp4 / mov · WhisperKit 离线生成字幕")
                    .font(AppFonts.body(11))
                    .foregroundColor(AppColors.aiPrimary)
            }
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(AppColors.bgElevated))
            }
            .buttonStyle(.plain)
        }
    }

    private var pickerButton: some View {
        Button { showPicker = true } label: {
            HStack(spacing: 6) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 14, weight: .bold))
                Text("选择视频文件")
                    .font(AppFonts.body(15, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(AppColors.brandPrimary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.chip))
        }
        .buttonStyle(.plain)
        .disabled(activeProgress != nil)
    }

    private func progressCard(progress: ActiveProgress) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ProgressView().tint(AppColors.brandPrimary).scaleEffect(0.8)
                Text(progress.label)
                    .font(AppFonts.body(13, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(Int(progress.value * 100))%")
                    .font(AppFonts.mono(11))
                    .foregroundColor(AppColors.textTertiary)
            }
            ProgressView(value: progress.value).tint(AppColors.brandPrimary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }

    private func errorCard(_ msg: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red.opacity(0.85))
            Text(msg)
                .font(AppFonts.body(12))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: AppSpacing.sm) {
                if localVideos.isEmpty {
                    Text("还没导入过 · 上方选个视频开始")
                        .font(AppFonts.body(12))
                        .foregroundColor(AppColors.textTertiary)
                        .padding(.top, AppSpacing.xl)
                } else {
                    ForEach(localVideos) { v in
                        row(v)
                    }
                }
            }
        }
    }

    private func row(_ v: LocalVideo) -> some View {
        Button { openPlayer(local: v) } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "film.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.brandPrimary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(v.displayName)
                        .font(AppFonts.body(14, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    Text(statusLabel(v))
                        .font(AppFonts.body(10))
                        .foregroundColor(AppColors.textTertiary)
                }
                Spacer()
                Image(systemName: v.subtitleStatus == "done" ? "play.circle.fill" : "ellipsis.circle")
                    .font(.system(size: 18))
                    .foregroundColor(v.subtitleStatus == "done" ? AppColors.brandPrimary : AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
            .background(AppColors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadii.cardSmall))
        }
        .buttonStyle(.plain)
        .disabled(v.subtitleStatus != "done")
    }

    private func statusLabel(_ v: LocalVideo) -> String {
        switch v.subtitleStatus {
        case "pending": return "等待中"
        case "running": return "字幕生成中…"
        case "done": return "字幕已就绪 · \(v.subtitleSegmentCount ?? 0) 句"
        case "failed": return "失败：\(v.subtitleError ?? "未知")"
        default: return v.subtitleStatus
        }
    }

    // MARK: - Logic

    private func handlePicked(url: URL) {
        Task { @MainActor in
            do {
                let local = try ingest(picked: url)
                try await runTranscription(for: local)
            } catch {
                pendingError = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            }
        }
    }

    /// 拷贝 picker 给的临时 URL 到 Application Support，写一条 SwiftData 记录。
    private func ingest(picked source: URL) throws -> LocalVideo {
        let needsScope = source.startAccessingSecurityScopedResource()
        defer { if needsScope { source.stopAccessingSecurityScopedResource() } }

        let id = UUID()
        let ext = source.pathExtension.isEmpty ? "mp4" : source.pathExtension
        let relative = "\(id.uuidString).\(ext)"
        let dest = LocalVideo.applicationSupportRoot().appendingPathComponent(relative)
        try FileManager.default.copyItem(at: source, to: dest)

        // 取时长
        let asset = AVURLAsset(url: dest)
        let duration: Double = {
            let cm = asset.duration
            return cm.timescale > 0 ? Double(cm.value) / Double(cm.timescale) : 0
        }()

        let v = LocalVideo(
            id: id,
            displayName: source.deletingPathExtension().lastPathComponent,
            fileRelativePath: relative,
            durationSeconds: duration
        )
        ctx.insert(v)
        try ctx.save()
        return v
    }

    private func runTranscription(for local: LocalVideo) async throws {
        local.subtitleStatus = "running"
        try? ctx.save()

        activeProgress = ActiveProgress(id: local.id, value: 0, label: "字幕生成中…")
        defer { activeProgress = nil }

        let subRelative = "\(local.id.uuidString).subtitle.json"
        let outURL = LocalVideo.applicationSupportRoot().appendingPathComponent(subRelative)

        do {
            let count = try await LocalSubtitleService.transcribe(
                videoURL: local.fileURL,
                outURL: outURL,
                videoId: local.id.uuidString,
                progress: { v in
                    activeProgress?.value = v
                }
            )
            local.subtitleStatus = "done"
            local.subtitleRelativePath = subRelative
            local.subtitleSegmentCount = count
            local.subtitleError = nil
            try ctx.save()
        } catch {
            local.subtitleStatus = "failed"
            local.subtitleError = (error as? LocalizedError)?.errorDescription ?? "\(error)"
            try? ctx.save()
            throw error
        }
    }

    private func openPlayer(local: LocalVideo) {
        guard let subURL = local.subtitleURL,
              let doc = SubtitleService.load(from: subURL) else {
            pendingError = "字幕文件读不到"
            return
        }
        // 借 DemoVideo 这个 UI model：videoURL 给本地文件路径，PlayerView 走 AVPlayer 播放。
        let video = DemoVideo(
            id: local.id.uuidString,
            title: local.displayName,
            author: "我导入的",
            source: "本地",
            durationSeconds: Int(local.durationSeconds),
            cefrLevel: "—",
            thumbnailName: nil,
            categoryColorHex: 0xB8C4FF,
            isRecommended: false,
            categories: [],
            thumbnailURL: nil,
            videoURL: local.fileURL.absoluteString
        )
        playerHandoff = PlayerHandoff(video: video, subtitle: doc)
    }
}

// MARK: - UIDocumentPicker bridge

struct DocumentPicker: UIViewControllerRepresentable {
    let types: [UTType]
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coord { Coord(onPick: onPick) }

    final class Coord: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
