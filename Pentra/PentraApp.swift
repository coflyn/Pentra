import SwiftUI
import AVKit
import ServiceManagement

class WallpaperSettings: ObservableObject {
    @AppStorage("wallpaperVideoPath") var videoPath: String = ""
    @AppStorage("isMuted") var isMuted: Bool = true
    @AppStorage("volume") var volume: Double = 0.5
    @AppStorage("scaleMode") var scaleMode: Int = 0
    @AppStorage("isPaused") var isPaused: Bool = false
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet { toggleLaunchAtLogin() }
    }
    
    var videoURL: URL? {
        guard !videoPath.isEmpty else { return nil }
        return URL(fileURLWithPath: videoPath)
    }
    
    func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to toggle launch at login: \(error)")
            }
        }
    }
    
    func syncLaunchAtLoginState() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

let globalSettings = WallpaperSettings()

class AppDelegate: NSObject, NSApplicationDelegate {
    var wallpaperWindow: NSWindow?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWallpaperWindow()
        setupSettingsWindow()
        globalSettings.syncLaunchAtLoginState()
    }
    
    func setupWallpaperWindow() {
        guard let screen = NSScreen.main else { return }
        
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.stationary, .canJoinAllSpaces, .ignoresCycle]
        window.backgroundColor = .black
        
        let hostingView = NSHostingView(rootView: WallpaperView().environmentObject(globalSettings))
        window.contentView = hostingView
        
        window.orderBack(nil)
        self.wallpaperWindow = window
    }
    
    func setupSettingsWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Live Wallpaper Settings"
        
        let hostingView = NSHostingView(rootView: ContentView().environmentObject(globalSettings))
        window.contentView = hostingView
        
        window.makeKeyAndOrderFront(nil)
        self.settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindow?.makeKeyAndOrderFront(nil)
        return true
    }
}

class PlayerNSView: NSView {
    let playerLayer = AVPlayerLayer()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer = CALayer()
        playerLayer.videoGravity = .resizeAspectFill
        self.layer?.addSublayer(playerLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        super.layout()
        playerLayer.frame = self.bounds
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = self.window {
            NotificationCenter.default.addObserver(self, selector: #selector(evaluatePlayback), name: NSWindow.didChangeOcclusionStateNotification, object: window)
            
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepMac), name: NSWorkspace.screensDidSleepNotification, object: nil)
            NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(evaluatePlayback), name: NSWorkspace.screensDidWakeNotification, object: nil)
        }
    }
    
    @objc func evaluatePlayback() {
        guard let player = playerLayer.player as? AVQueuePlayer else { return }
        
        if globalSettings.isPaused {
            player.pause()
            return
        }
        
        guard let window = self.window else {
            player.play()
            return
        }
        
        if window.occlusionState.contains(.visible) {
            player.play()
        } else {
            player.pause()
        }
    }
    
    @objc func sleepMac() {
        (playerLayer.player as? AVQueuePlayer)?.pause()
    }
}

struct LoopingPlayerView: NSViewRepresentable {
    @EnvironmentObject var settings: WallpaperSettings
    let url: URL
    
    func makeNSView(context: Context) -> PlayerNSView {
        let view = PlayerNSView(frame: .zero)
        let player = AVQueuePlayer()
        view.playerLayer.player = player
        
        context.coordinator.playerLayer = view.playerLayer
        play(url: url, player: player, context: context)
        applySettings(to: player, layer: view.playerLayer, view: view)
        
        return view
    }
    
    func updateNSView(_ nsView: PlayerNSView, context: Context) {
        if let player = nsView.playerLayer.player as? AVQueuePlayer {
            if context.coordinator.currentURL != url {
                play(url: url, player: player, context: context)
            }
            applySettings(to: player, layer: nsView.playerLayer, view: nsView)
        }
    }
    
    private func applySettings(to player: AVQueuePlayer, layer: AVPlayerLayer, view: PlayerNSView) {
        player.volume = settings.isMuted ? 0.0 : Float(settings.volume)
        
        switch settings.scaleMode {
        case 1: layer.videoGravity = .resizeAspect
        case 2: layer.videoGravity = .resize
        default: layer.videoGravity = .resizeAspectFill
        }
        
        view.evaluatePlayback()
    }
    
    private func play(url: URL, player: AVQueuePlayer, context: Context) {
        context.coordinator.currentURL = url
        player.removeAllItems()
        let item = AVPlayerItem(url: url)
        
        player.preventsDisplaySleepDuringVideoPlayback = false
        
        context.coordinator.looper = AVPlayerLooper(player: player, templateItem: item)
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    class Coordinator {
        var looper: AVPlayerLooper?
        var playerLayer: AVPlayerLayer?
        var currentURL: URL?
    }
}

struct WallpaperView: View {
    @EnvironmentObject var settings: WallpaperSettings
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            if let url = settings.videoURL {
                LoopingPlayerView(url: url)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Text("No Wallpaper.\nSelect a Video in Settings!")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

@main
struct PentraApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Pentra", systemImage: "photo.tv") {
            Button("Open Settings") {
                appDelegate.settingsWindow?.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
