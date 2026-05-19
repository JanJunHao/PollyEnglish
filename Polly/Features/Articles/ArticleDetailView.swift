import SwiftUI
import SwiftData

/// 外刊精读页：配图 + 中英对照（可切纯英）+ 点词查义 + 长按整句 AI 讲解。
/// 交互编排照搬 PlayerView：点词→WordCard，长按句→ExplanationCard。
struct ArticleDetailView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var ctx
    let article: Article
    let onClose: () -> Void

    @AppStorage("article.showTranslation") private var showTranslation = true

    @State private var wordLookup: WordLookupResult?
    @State private var aiLookupPending = false
    @State private var explanationState: ExplanationSheetState?

    /// 讲解卡 sheet 状态包装（同 PlayerView.ExplanationSheetState）。
    struct ExplanationSheetState: Identifiable {
        let id = UUID()
        let segment: ArticleSegment
        var phase: Phase
        enum Phase {
            case loading
            case loaded(ExplanationResult)
            case error(String)
        }
    }

    private var heroURL: String? {
        if !article.thumbnailURL.isEmpty { return article.thumbnailURL }
        return article.imageURLs.first
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroImage
                    header
                    bodyContent
                    attributionView
                    Spacer(minLength: 80)
                }
            }
        }
        .background(theme.bg.ignoresSafeArea())
        .sheet(item: $wordLookup) { lookup in
            WordCard(
                lookup: lookup,
                isAIPending: aiLookupPending,
                onClose: { wordLookup = nil },
                onAddToVocab: { addToVocabulary(lookup) },
                onAIDetail: {}
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.clear)
        }
        .sheet(item: $explanationState) { state in
            let cardState: ExplanationCard.State = {
                switch state.phase {
                case .loading:           return .loading
                case .loaded(let r):     return .loaded(r)
                case .error(let m):      return .error(m)
                }
            }()
            ExplanationCard(
                sentence: state.segment.text,
                state: cardState,
                onClose: { explanationState = nil },
                onRetry: { startExplanationLoad(for: state.segment) }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.clear)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.text)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(theme.surfaceElev))
            }
            .buttonStyle(.plain)

            Spacer()

            // 中英对照 / 仅英文 切换
            Button {
                showTranslation.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "character.book.closed")
                        .font(.system(size: 11, weight: .semibold))
                    Text(showTranslation ? "中英" : "英")
                        .font(AppFonts.body(12, weight: .semibold))
                }
                .foregroundColor(showTranslation ? theme.aiText : theme.textTer)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(theme.surfaceElev, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Hero Image

    @ViewBuilder
    private var heroImage: some View {
        if let url = heroURL, !url.isEmpty {
            ThumbnailImage(name: nil, url: url)
                .aspectRatio(contentMode: .fill)
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
                .padding(.bottom, 4)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(article.source.uppercased() + " · " + article.section)
                .font(AppFonts.mono(10, weight: .bold))
                .tracking(1.2)
                .foregroundColor(theme.aiText)
                .padding(.bottom, 10)

            Text(article.title)
                .font(AppFonts.display(24, weight: .semibold))
                .foregroundColor(theme.text)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 10)

            HStack(spacing: 8) {
                Text(article.author)
                Text("·")
                Text(article.cefrLevel)
                Text("·")
                Text("\(article.readingMinutes) min read")
                Text("·")
                Text(article.relativeDate)
            }
            .font(AppFonts.mono(10))
            .foregroundColor(theme.textTer)
            .lineLimit(1)
            .padding(.bottom, 16)

            Rectangle()
                .fill(theme.divider)
                .frame(height: 0.5)
                .padding(.bottom, 18)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // MARK: - Body（逐自然段 → 逐句）

    private var bodyContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(Array(article.paragraphsByParagraph.enumerated()), id: \.offset) { _, paragraph in
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(paragraph) { sentence in
                        sentenceView(sentence)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func sentenceView(_ sentence: ArticleSegment) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            // 英文句：逐词 Button，可点查词
            FlowLayout(hSpacing: 4, vSpacing: 4) {
                ForEach(Array(words(of: sentence).enumerated()), id: \.offset) { _, word in
                    Button {
                        handleWordTap(word, context: sentence.text)
                    } label: {
                        Text(word)
                            .font(AppFonts.body(16))
                            .foregroundColor(theme.text)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 中文译文
            if showTranslation, !sentence.translation.isEmpty {
                Text(sentence.translation)
                    .font(AppFonts.body(13))
                    .foregroundColor(theme.textSec)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .contentShape(Rectangle())
        // 长按整句 → AI 讲解（与 word Button tap 共存）
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in handleSentenceLongPress(sentence) }
        )
    }

    @ViewBuilder
    private var attributionView: some View {
        if let attribution = article.attribution, !attribution.isEmpty {
            Text(attribution)
                .font(AppFonts.body(10))
                .foregroundColor(theme.textTer)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
                .padding(.top, 24)
        }
    }

    /// 整句切词：按空格切分（与字幕逐词同款；DictionaryService 查词时会清标点）。
    private func words(of sentence: ArticleSegment) -> [String] {
        sentence.text.split(separator: " ").map(String.init)
    }

    // MARK: - 点词查义（编排同 PlayerView.handleWordTap）

    private func handleWordTap(_ word: String, context: String) {
        let result = DictionaryService.shared.lookup(word, contextSentence: context)
        wordLookup = result
        aiLookupPending = false

        // 本地词典未命中 → AI 实时查询
        if result.entry == nil {
            aiLookupPending = true
            Task { @MainActor in
                do {
                    let entry = try await DictionaryService.shared.aiLookup(
                        word: result.original, context: context
                    )
                    if let current = wordLookup, current.original == result.original {
                        wordLookup = WordLookupResult(
                            original: current.original,
                            lemma: current.lemma,
                            entry: entry,
                            contextSentence: current.contextSentence
                        )
                    }
                } catch {
                    print("[ArticleDetail] AI lookup failed: \(error.localizedDescription)")
                }
                aiLookupPending = false
            }
        }
    }

    // MARK: - 长按整句 → AI 讲解（编排同 PlayerView.handleSentenceLongPress）

    private func handleSentenceLongPress(_ sentence: ArticleSegment) {
        explanationState = ExplanationSheetState(segment: sentence, phase: .loading)
        startExplanationLoad(for: sentence)
    }

    private func startExplanationLoad(for sentence: ArticleSegment) {
        explanationState = ExplanationSheetState(segment: sentence, phase: .loading)
        Task { @MainActor in
            do {
                let r = try await ExplanationService.shared.deepExplain(
                    articleSentence: sentence, article: article
                )
                if explanationState?.segment.id == sentence.id {
                    explanationState?.phase = .loaded(r)
                }
            } catch {
                if explanationState?.segment.id == sentence.id {
                    explanationState?.phase = .error(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - 加入生词本（同 PlayerView.addToVocabulary）

    private func addToVocabulary(_ lookup: WordLookupResult) {
        let meanings = lookup.entry?.definitions.map { "\($0.pos) \($0.meaning)" } ?? []
        let item = VocabularyItem(
            word: lookup.original,
            lemma: lookup.lemma,
            phonetic: lookup.entry?.phonetic,
            meanings: meanings,
            contextSentence: lookup.contextSentence,
            sourceVideoId: article.id,
            sourceVideoTitle: article.title
        )
        ctx.insert(item)
        try? ctx.save()
    }
}
