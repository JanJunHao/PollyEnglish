import SwiftUI
import AVKit

/// AVPlayerLayer 的 SwiftUI 包装。比 VideoPlayer 更可控（无系统控件、自定义 gravity）。
struct AVPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.player = player
    }
}

final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    /// 必须强引用持有，否则 controller 被释放后画中画不工作。
    private var pipController: AVPictureInPictureController?

    var player: AVPlayer? {
        get { playerLayer.player }
        set {
            playerLayer.player = newValue
            playerLayer.videoGravity = .resizeAspect
            backgroundColor = .black
            setupPiPIfNeeded()
        }
    }

    /// 内嵌播放时切后台自动进画中画小窗。controller 关联的是 layer，
    /// 换视频（layer.player 变）时 PiP 自动跟随，无需重建。
    private func setupPiPIfNeeded() {
        guard pipController == nil,
              AVPictureInPictureController.isPictureInPictureSupported() else { return }
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.canStartPictureInPictureAutomaticallyFromInline = true
    }
}
