import SwiftUI
import UIKit
import WebKit

/// WKWebView 包裹的 YouTube IFrame Player API 组件。
/// 用于 TED 等 CC-NC 内容的合规播放——不 host 视频，仅嵌入官方频道。
///
/// 与 AVPlayer 路径相比：
/// - 字幕同步靠 4Hz 轮询 `getCurrentTime()`，精度 ~250ms（AVPlayer 走 CADisplayLink 可达 30fps）
/// - 没有字级高亮（YouTube 不暴露 word-level timing；演示阶段先用句级高亮）
/// - 进度条 / ±10s / 倍速控制走 JS bridge
///
/// 父视图通过 @Binding 双向通信：
/// - currentTime / isReady / isPlaying / duration：YT → parent
/// - command（外发指令：play / pause / seek / setRate）：parent → YT
struct YouTubeEmbedPlayer: UIViewRepresentable {
    let videoId: String
    @Binding var currentTime: Double
    @Binding var duration: Double
    @Binding var isReady: Bool
    @Binding var isPlaying: Bool
    /// YouTube IFrame Player API 抛出的错误码：
    /// 2 = invalid param, 5 = HTML5 player error, 100 = video removed,
    /// 101 / 150 = embed disabled by uploader, 152 = video unavailable (常见地理限制)
    @Binding var errorCode: Int?
    /// 父视图调 controller.send(.play) / .seek(30) 来控制播放
    let controller: YouTubeEmbedController

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let userContent = WKUserContentController()
        userContent.add(context.coordinator, name: "bridge")
        config.userContentController = userContent

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black

        controller.bind(webView: webView)
        context.coordinator.webView = webView

        let html = Coordinator.htmlTemplate(videoId: videoId)
        // baseURL 必须是 https：YT IFrame API 拒绝 file:// origin
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // 视频切换时重载（演示阶段通常不切，留个口子）
        if context.coordinator.loadedVideoId != videoId {
            context.coordinator.loadedVideoId = videoId
            let html = Coordinator.htmlTemplate(videoId: videoId)
            webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
        }
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let parent: YouTubeEmbedPlayer
        weak var webView: WKWebView?
        var loadedVideoId: String

        init(parent: YouTubeEmbedPlayer) {
            self.parent = parent
            self.loadedVideoId = parent.videoId
        }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard let dict = message.body as? [String: Any], let type = dict["type"] as? String else { return }
            switch type {
            case "ready":
                let dur = (dict["duration"] as? Double) ?? 0
                DispatchQueue.main.async {
                    self.parent.isReady = true
                    self.parent.duration = dur
                }
            case "state":
                // YT.PlayerState: -1 unstarted, 0 ended, 1 playing, 2 paused, 3 buffering, 5 cued
                if let s = dict["state"] as? Int {
                    DispatchQueue.main.async {
                        self.parent.isPlaying = (s == 1)
                    }
                }
            case "time":
                if let t = dict["t"] as? Double {
                    DispatchQueue.main.async {
                        self.parent.currentTime = t
                    }
                }
            case "error":
                if let code = dict["code"] as? Int {
                    DispatchQueue.main.async {
                        self.parent.errorCode = code
                    }
                }
            default:
                break
            }
        }

        static func htmlTemplate(videoId: String) -> String {
            """
            <!doctype html>
            <html><head>
            <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
            <style>
              html,body { margin:0; padding:0; background:#000; height:100%; overflow:hidden; }
              #player { width:100vw; height:100vh; }
            </style>
            </head><body>
            <div id="player"></div>
            <script src="https://www.youtube.com/iframe_api"></script>
            <script>
            var player;
            function send(obj) {
              try { window.webkit.messageHandlers.bridge.postMessage(obj); } catch(e) {}
            }
            function onYouTubeIframeAPIReady() {
              player = new YT.Player('player', {
                videoId: '\(videoId)',
                playerVars: {
                  playsinline: 1,          // 内联播放（不强制系统全屏）
                  controls: 1,             // 显示 YouTube 自带控件（保底：即便我们 JS bridge 失效用户也能点播放）
                  modestbranding: 1,       // 隐藏右下 YouTube logo
                  rel: 0,                  // 结尾不推荐其他频道
                  cc_load_policy: 0,
                  iv_load_policy: 3,       // 隐藏标注
                  disablekb: 1,
                  fs: 1,                   // 允许全屏（移动端常被忽略，但 iPad 用得上）
                  autoplay: 1,             // 自动播放
                  mute: 1                  // **必须**：iOS WKWebView 只允许 muted autoplay
                },
                events: {
                  onReady: function(e) {
                    send({type: 'ready', duration: e.target.getDuration()});
                    // autoplay 兜底：onReady 后主动 playVideo（个别 iOS 版本不响应 playerVars.autoplay）
                    try { e.target.playVideo(); } catch(err) {}
                  },
                  onStateChange: function(e) {
                    send({type: 'state', state: e.data});
                  },
                  onError: function(e) {
                    send({type: 'error', code: e.data});
                  }
                }
              });
              setInterval(function() {
                if (player && player.getCurrentTime) {
                  send({type: 'time', t: player.getCurrentTime()});
                }
              }, 250);
            }
            // JS API hooks called from Swift via evaluateJavaScript
            window.pollyPlay  = function() { if (player) { try { player.unMute(); } catch(_){}; player.playVideo(); } };
            window.pollyPause = function() { if (player) player.pauseVideo(); };
            window.pollySeek  = function(t) { if (player) player.seekTo(t, true); };
            window.pollyRate  = function(r) { if (player) player.setPlaybackRate(r); };
            window.pollyUnmute = function() { if (player) player.unMute(); };
            </script>
            </body></html>
            """
        }
    }
}

/// 外发指令通道：parent → WKWebView 内的 JS。
final class YouTubeEmbedController: ObservableObject {
    private weak var webView: WKWebView?

    func bind(webView: WKWebView) {
        self.webView = webView
    }

    func play()           { eval("window.pollyPlay()") }   // 内含 unMute（muted autoplay 之后用户手势 → 取消静音）
    func pause()          { eval("window.pollyPause()") }
    func seek(to t: Double) { eval("window.pollySeek(\(t))") }
    func setRate(_ r: Float) { eval("window.pollyRate(\(r))") }
    func unmute()         { eval("window.pollyUnmute()") }

    private func eval(_ js: String) {
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }
}
