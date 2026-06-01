import SwiftUI
import AVKit
import ServiceManagement
import IOKit.ps

struct PlaylistItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
}

class WallpaperSettings: ObservableObject {
    @AppStorage("playlistData") var playlistData: Data = Data() {
        didSet { updatePlaylistTimer() }
    }
    
    var playlistPaths: [String] {
        get {
            if let decoded = try? JSONDecoder().decode([String].self, from: playlistData) { return decoded }
            return []
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) { 
                playlistData = encoded 
                updatePlaylistTimer()
            }
        }
    }
    
    @AppStorage("playlistInterval") var playlistInterval: Int = 5 {
        didSet { updatePlaylistTimer() }
    }
    
    @AppStorage("isMuted") var isMuted: Bool = true
    @AppStorage("volume") var volume: Double = 0.5
    @AppStorage("scaleMode") var scaleMode: Int = 0
    @AppStorage("brightness") var brightness: Double = 1.0
    @AppStorage("playbackSpeed") var playbackSpeed: Double = 1.0
    
    @AppStorage("isPaused") var isPaused: Bool = false
    @AppStorage("pauseBatteryThreshold") var pauseBatteryThreshold: Int = 100
    @AppStorage("blurRadius") var blurRadius: Double = 0.0
    
    @AppStorage("syncMenuBar") var syncMenuBar: Bool = true {
        didSet { if syncMenuBar, let item = activeItems.last { syncNativeWallpaper(with: item) } }
    }
    
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet { toggleLaunchAtLogin() }
    }
    
    @Published var activeItems: [PlaylistItem] = []
    private var playlistTimer: Timer?
    private var currentIndex: Int = 0
    
    func updatePlaylistTimer() {
        playlistTimer?.invalidate()
        let paths = playlistPaths
        
        if paths.count > 1 {
            let safeInterval = max(1, playlistInterval)
            playlistTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(safeInterval * 60), repeats: true) { [weak self] _ in
                self?.nextPlaylistVideo()
            }
        }
        
        if let currentItem = activeItems.last, paths.contains(currentItem.url.path) {
            if let newIndex = paths.firstIndex(of: currentItem.url.path) {
                currentIndex = newIndex
            }
            return
        }
        
        withAnimation(.easeInOut(duration: 1.5)) {
            if paths.isEmpty {
                activeItems = []
            } else {
                currentIndex = 0
                let item = PlaylistItem(url: URL(fileURLWithPath: paths[0]))
                activeItems = [item]
                syncNativeWallpaper(with: item)
            }
        }
    }
    
    func nextPlaylistVideo() {
        let paths = playlistPaths
        guard paths.count > 1 else { return }
        
        DispatchQueue.main.async {
            self.currentIndex = (self.currentIndex + 1) % paths.count
            let newItem = PlaylistItem(url: URL(fileURLWithPath: paths[self.currentIndex]))
            
            withAnimation(.easeInOut(duration: 1.5)) {
                self.activeItems.append(newItem)
                self.syncNativeWallpaper(with: newItem)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.activeItems.count > 1 {
                    self.activeItems.removeFirst(self.activeItems.count - 1)
                }
            }
        }
    }
    
    func syncNativeWallpaper(with item: PlaylistItem) {
        guard syncMenuBar else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let ext = item.url.pathExtension.lowercased()
            let isImage = ["jpg", "jpeg", "png", "heic", "webp"].contains(ext)
            var imageToSet: NSImage?
            
            if isImage || ext == "gif" {
                imageToSet = NSImage(contentsOf: item.url)
            } else {
                let asset = AVAsset(url: item.url)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                imageGenerator.maximumSize = CGSize(width: 1920, height: 1080)
                let time = CMTime(seconds: 1.0, preferredTimescale: 600)
                
                if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
                    imageToSet = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                } else if let cgImage = try? imageGenerator.copyCGImage(at: .zero, actualTime: nil) {
                    imageToSet = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                }
            }
            
            guard let finalImage = imageToSet, let tiffData = finalImage.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiffData), let pngData = bitmap.representation(using: .png, properties: [:]) else { return }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("pentra_sync_\(item.id.uuidString).png")
            do {
                try pngData.write(to: tempURL)
                DispatchQueue.main.async {
                    for screen in NSScreen.screens {
                        try? NSWorkspace.shared.setDesktopImageURL(tempURL, for: screen, options: [:])
                    }
                }
            } catch {
                print("Failed to sync native wallpaper: \(error)")
            }
        }
    }
    
    func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
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
        globalSettings.updatePlaylistTimer()
    }
    
    func setupWallpaperWindow() {
        guard let screen = NSScreen.main else { return }
        let window = NSWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
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
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 550), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
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
    var batteryTimer: Timer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer = CALayer()
        playerLayer.videoGravity = .resizeAspectFill
        self.layer?.addSublayer(playerLayer)
        
        batteryTimer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(evaluatePlayback), userInfo: nil, repeats: true)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
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
    
    func isOnBatteryPower() -> Bool {
        let timeRemaining = IOPSGetTimeRemainingEstimate()
        return timeRemaining > 0 && timeRemaining != kIOPSTimeRemainingUnlimited
    }
    
    func getBatteryPercentage() -> Int {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else { return 100 }
        
        for source in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
               let current = info[kIOPSCurrentCapacityKey] as? Int,
               let max = info[kIOPSMaxCapacityKey] as? Int, max > 0 {
                return Int((Double(current) / Double(max)) * 100)
            }
        }
        return 100
    }
    
    @objc func evaluatePlayback() {
        guard let player = playerLayer.player as? AVQueuePlayer else { return }
        
        if globalSettings.isPaused {
            player.pause()
            return
        }
        
        if globalSettings.pauseBatteryThreshold > 0 && isOnBatteryPower() {
            if globalSettings.pauseBatteryThreshold == 100 || getBatteryPercentage() <= globalSettings.pauseBatteryThreshold {
                player.pause()
                return
            }
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

struct GIFPlayerView: NSViewRepresentable {
    @EnvironmentObject var settings: WallpaperSettings
    let url: URL
    
    func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.animates = true
        view.imageAlignment = .alignCenter
        return view
    }
    
    func updateNSView(_ nsView: NSImageView, context: Context) {
        if context.coordinator.currentURL != url {
            context.coordinator.currentURL = url
            nsView.image = NSImage(contentsOf: url)
        }
        switch settings.scaleMode {
        case 0: nsView.imageScaling = .scaleAxesIndependently
        case 1: nsView.imageScaling = .scaleProportionallyUpOrDown
        case 2: nsView.imageScaling = .scaleAxesIndependently
        default: break
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator { var currentURL: URL? }
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
        player.defaultRate = Float(settings.playbackSpeed)
        if player.rate != 0 {
            player.rate = Float(settings.playbackSpeed)
        }
        
        switch settings.scaleMode {
        case 1: layer.videoGravity = .resizeAspect
        case 2: layer.videoGravity = .resize
        default: layer.videoGravity = .resizeAspectFill
        }
        
        view.evaluatePlayback()
    }
    
    private func play(url: URL, player: AVQueuePlayer, context: Context) {
        context.coordinator.currentURL = url
        context.coordinator.looper?.disableLooping()
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
            
            if settings.activeItems.isEmpty {
                VStack(spacing: 20) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                    Text("No Wallpaper Configured.\nAdd Videos in Settings!")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            } else {
                ForEach(settings.activeItems) { item in
                    Group {
                        let ext = item.url.pathExtension.lowercased()
                        if ["jpg", "jpeg", "png", "heic", "webp"].contains(ext) {
                            if let image = NSImage(contentsOf: item.url) {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: settings.scaleMode == 1 ? .fit : .fill)
                                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                    .clipped()
                            } else { Color.black }
                        } else if ext == "gif" {
                            GIFPlayerView(url: item.url)
                        } else {
                            LoopingPlayerView(url: item.url)
                        }
                    }
                    .transition(.opacity)
                    .edgesIgnoringSafeArea(.all)
                }
                .blur(radius: settings.blurRadius)
                
                // Brightness Overlay
                Color.black
                    .opacity(1.0 - settings.brightness)
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(false)
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
