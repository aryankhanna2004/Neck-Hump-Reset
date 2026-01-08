//
//  VideoPlayerViews.swift
//  Neck Hump Reset
//
//  Extracted from PostureCheckView.swift
//

import SwiftUI
import AVKit

// MARK: - Side Pose Video Player (Silent - No Audio Track)
struct SidePoseVideoPlayer: View {
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            if player != nil {
                SilentVideoPlayerView(player: $player)
                    .onAppear {
                        player?.play()
                    }
                    .onDisappear {
                        player?.pause()
                    }
            } else {
                // Fallback if video not found
                ZStack {
                    AppTheme.Colors.primaryBlue.opacity(0.3)
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "person.fill.viewfinder")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.Colors.accentCyan)
                        
                        Text("Stand sideways to the camera")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.mutedGray)
                    }
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
    }
    
    private func setupPlayer() {
        guard let videoURL = Bundle.main.url(forResource: "SidePose", withExtension: "mp4") else { return }
        
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        #endif
        
        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = 0
        player?.isMuted = true
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

// MARK: - Silent Video Player UIViewRepresentable
#if os(iOS)
struct SilentVideoPlayerView: UIViewRepresentable {
    @Binding var player: AVPlayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView()
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let playerView = uiView as? PlayerUIView else { return }
        playerView.playerLayer.player = player
    }
}

class PlayerUIView: UIView {
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
}
#else
// macOS fallback
struct SilentVideoPlayerView: View {
    @Binding var player: AVPlayer?
    
    var body: some View {
        if let player = player {
            VideoPlayer(player: player)
        }
    }
}
#endif

// MARK: - Fullscreen Video Player (Silent)
struct FullscreenVideoPlayer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if player != nil {
                SilentVideoPlayerView(player: $player)
                    #if os(iOS)
                    .ignoresSafeArea()
                    #endif
                    .onAppear {
                        player?.play()
                    }
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func setupPlayer() {
        guard let videoURL = Bundle.main.url(forResource: "SidePose", withExtension: "mp4") else { return }
        
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        #endif
        
        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = 0
        player?.isMuted = true
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

// MARK: - Timer Option Button
struct TimerOptionButton: View {
    let title: String
    let value: Int
    @Binding var selectedValue: Int
    
    var isSelected: Bool { selectedValue == value }
    
    var body: some View {
        Button(action: { selectedValue = value }) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white : Color.clear)
                )
        }
    }
}
