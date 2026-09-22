import SwiftUI
import AVKit
import ServiceManagement
import IOKit.ps

struct PlaylistItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
}

final class PowerManager {
    static let shared = PowerManager()
    private(set) var isOnBattery: Bool = false
    private(set) var batteryPercentage: Int = 100
    private var lastUpdate: Date = .distantPast
    
    private init() {
        updatePowerStatus()
    }
    
    func refreshIfNeeded(force: Bool = false) {
        if force || Date().timeIntervalSince(lastUpdate) >= 15.0 {
            updatePowerStatus()
        }
    }
    
    private func updatePowerStatus() {
        lastUpdate = Date()
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            isOnBattery = false
            batteryPercentage = 100
            return
        }
        
        var batteryFound = false
        var currentCap = 100
        var maxCap = 100
        
        for source in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                if let state = info[kIOPSPowerSourceStateKey] as? String, state == kIOPSBatteryPowerValue {
                    batteryFound = true
                }
                if let current = info[kIOPSCurrentCapacityKey] as? Int,
                   let max = info[kIOPSMaxCapacityKey] as? Int, max > 0 {
                    currentCap = current
                    maxCap = max
                }
            }
        }
        isOnBattery = batteryFound
        batteryPercentage = maxCap > 0 ? Int((Double(currentCap) / Double(maxCap)) * 100) : 100
    }
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
    @AppStorage("smartPowerSaving") var smartPowerSaving: Bool = false
    @AppStorage("blurRadius") var blurRadius: Double = 0.0
    @AppStorage("isShuffle") var isShuffle: Bool = false
    
    @AppStorage("syncMenuBar") var syncMenuBar: Bool = true {
        didSet { if syncMenuBar { syncCurrentWallpaper() } }
    }
    
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false {
        didSet { toggleLaunchAtLogin() }
    }
    
    @Published var activeItems: [PlaylistItem] = []
    private var playlistTimer: Timer?
    private var currentIndex: Int = 0
    private var syncTask: Task<Void, Never>?
    private var transitionWorkItem: DispatchWorkItem?
    
    var validPlaylistPaths: [String] {
        return playlistPaths.filter { path in
            guard FileManager.default.fileExists(atPath: path) else { return false }
            let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
            return ["mp4", "mov", "m4v", "3gp", "jpg", "jpeg", "png", "heic", "webp", "gif"].contains(ext)
        }
    }
    
    func updatePlaylistTimer() {
        playlistTimer?.invalidate()
        let paths = validPlaylistPaths
        
        if paths.count > 1 && playlistInterval > 0 {
            let safeInterval = max(1, playlistInterval)
            playlistTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(safeInterval * 60), repeats: true) { [weak self] _ in
                self?.nextPlaylistVideo()
            }
        }
        
        if let currentItem = activeItems.last, paths.contains(currentItem.url.path) {
            if let newIndex = paths.firstIndex(of: currentItem.url.path) {
                currentIndex = newIndex
            }
            if syncMenuBar {
                syncCurrentWallpaper()
            }
            return
        }
        
        withAnimation(.easeInOut(duration: 1.5)) {
            if paths.isEmpty {
                activeItems = []
            } else {
                let safeIndex = (currentIndex >= 0 && currentIndex < paths.count) ? currentIndex : 0
                currentIndex = safeIndex
                let item = PlaylistItem(url: URL(fileURLWithPath: paths[safeIndex]))
                activeItems = [item]
            }
        }
        
        if !paths.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                if let item = self?.activeItems.first {
                    self?.syncNativeWallpaper(with: item)
                }
            }
        }
    }
    
    func selectWallpaper(at index: Int) {
        let paths = validPlaylistPaths
        guard index >= 0 && index < paths.count else { return }
        
        currentIndex = index
        let selectedPath = paths[index]
        
        if activeItems.last?.url.path == selectedPath { return }
        
        transitionWorkItem?.cancel()
        
        // If there's an ongoing transition, immediately collapse to the most recent item
        if activeItems.count > 1 {
            activeItems = [activeItems.last!]
        }
        
        let newItem = PlaylistItem(url: URL(fileURLWithPath: selectedPath))
        
        withAnimation(.easeInOut(duration: 1.5)) {
            activeItems.append(newItem)
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.activeItems.count > 1 {
                self.activeItems.removeFirst(self.activeItems.count - 1)
            }
            self.syncNativeWallpaper(with: newItem)
            self.transitionWorkItem = nil
        }
        transitionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: workItem)
    }
    
    func nextPlaylistVideo() {
        let paths = validPlaylistPaths
        guard paths.count > 1 else { return }
        
        DispatchQueue.main.async {
            self.transitionWorkItem?.cancel()
            
            if self.isShuffle {
                var newIndex = Int.random(in: 0..<paths.count)
                if newIndex == self.currentIndex {
                    newIndex = (self.currentIndex + 1) % paths.count
                }
                self.currentIndex = newIndex
            } else {
                self.currentIndex = (self.currentIndex + 1) % paths.count
            }
            
            // If there's an ongoing transition, immediately collapse to the most recent item
            if self.activeItems.count > 1 {
                self.activeItems = [self.activeItems.last!]
            }
            
            let newItem = PlaylistItem(url: URL(fileURLWithPath: paths[self.currentIndex]))
            
            withAnimation(.easeInOut(duration: 1.5)) {
                self.activeItems.append(newItem)
            }
            
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                if self.activeItems.count > 1 {
                    self.activeItems.removeFirst(self.activeItems.count - 1)
                }
                self.syncNativeWallpaper(with: newItem)
                self.transitionWorkItem = nil
            }
            self.transitionWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: workItem)
        }
    }
    
    private func resizedImage(_ image: NSImage, maxPixelSize: CGSize) -> NSImage {
        let originalSize = image.size
        guard originalSize.width > maxPixelSize.width || originalSize.height > maxPixelSize.height else {
            return image
        }
        let widthRatio  = maxPixelSize.width / originalSize.width
        let heightRatio = maxPixelSize.height / originalSize.height
        let scaleFactor = min(widthRatio, heightRatio)
        let newSize = CGSize(width: originalSize.width * scaleFactor, height: originalSize.height * scaleFactor)
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: originalSize), operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
    
    func syncCurrentWallpaper() {
        guard syncMenuBar else { return }
        if let item = activeItems.last {
            syncNativeWallpaper(with: item)
        } else if let firstValid = validPlaylistPaths.first {
            let item = PlaylistItem(url: URL(fileURLWithPath: firstValid))
            syncNativeWallpaper(with: item)
        }
    }
    
    func syncNativeWallpaper(with item: PlaylistItem) {
        guard syncMenuBar else { return }
        syncTask?.cancel()
        
        syncTask = Task {
            let ext = item.url.pathExtension.lowercased()
            let isImage = ["jpg", "jpeg", "png", "heic", "webp"].contains(ext)
            var imageToSet: NSImage?
            
            let mainScreenSize = await MainActor.run {
                NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
            }
            let target4KSize = CGSize(
                width: min(3840, max(1920, mainScreenSize.width * 2)),
                height: min(2160, max(1080, mainScreenSize.height * 2))
            )
            
            if Task.isCancelled { return }
            
            if isImage || ext == "gif" {
                if let rawImage = NSImage(contentsOf: item.url) {
                    imageToSet = self.resizedImage(rawImage, maxPixelSize: target4KSize)
                }
            } else {
                let asset = AVURLAsset(url: item.url)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                imageGenerator.maximumSize = target4KSize
                let time = CMTime(seconds: 1.0, preferredTimescale: 600)
                
                if let (cgImage, _) = try? await imageGenerator.image(at: time) {
                    imageToSet = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                } else if let (cgImage, _) = try? await imageGenerator.image(at: .zero) {
                    imageToSet = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                }
            }
            
            if Task.isCancelled { return }
            
            guard let finalImage = imageToSet,
                  let tiffData = finalImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else { return }
            
            if Task.isCancelled { return }
            
            // Alternating sync file in Application Support/coflyn.Pentra ensures macOS Dock detects changes
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
            let syncDir = appSupport.appendingPathComponent("coflyn.Pentra", isDirectory: true)
            try? FileManager.default.createDirectory(at: syncDir, withIntermediateDirectories: true)
            
            let syncA = syncDir.appendingPathComponent("pentra_sync_a.png")
            let syncB = syncDir.appendingPathComponent("pentra_sync_b.png")
            
            let currentURL = await MainActor.run {
                NSScreen.main.flatMap { NSWorkspace.shared.desktopImageURL(for: $0) }
            }
            let targetURL = (currentURL?.lastPathComponent == "pentra_sync_a.png") ? syncB : syncA
            
            do {
                try pngData.write(to: targetURL)
                if Task.isCancelled { return }
                
                // Perform setDesktopImageURL off the Main RunLoop so Dock IPC delays never beachball the UI
                Task.detached(priority: .utility) {
                    let screens = await MainActor.run { NSScreen.screens }
                    let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
                        .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
                        .allowClipping: true
                    ]
                    for screen in screens {
                        try? NSWorkspace.shared.setDesktopImageURL(targetURL, for: screen, options: options)
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

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var wallpaperWindows: [NSWindow] = []
    var settingsWindow: NSWindow?
    private var screenChangeWorkItem: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWallpaperWindow()
        setupSettingsWindow()
        globalSettings.syncLaunchAtLoginState()
        globalSettings.updatePlaylistTimer()
        globalSettings.syncCurrentWallpaper()
        
        // Listen for screen changes with debounce to prevent window creation storms on wake
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            self?.screenChangeWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.setupWallpaperWindow()
            }
            self?.screenChangeWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
    }
    
    func setupWallpaperWindow() {
        let screens = NSScreen.screens
        
        if wallpaperWindows.count == screens.count && !wallpaperWindows.isEmpty {
            for (index, screen) in screens.enumerated() {
                wallpaperWindows[index].setFrame(screen.frame, display: true)
            }
            return
        }
        
        // Clean up previous windows and tear down their views
        for window in wallpaperWindows {
            window.contentView = nil
            window.orderOut(nil)
            window.close()
        }
        wallpaperWindows.removeAll()
        
        for screen in screens {
            let window = NSWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.stationary, .canJoinAllSpaces, .ignoresCycle]
            window.backgroundColor = .black
            
            let hostingView = NSHostingView(rootView: WallpaperView().environmentObject(globalSettings))
            window.contentView = hostingView
            window.orderBack(nil)
            wallpaperWindows.append(window)
        }
    }
    
    func setupSettingsWindow() {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 550), styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        window.title = "Live Wallpaper Settings"
        window.delegate = self
        
        let hostingView = NSHostingView(rootView: ContentView().environmentObject(globalSettings))
        window.contentView = hostingView
        
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        self.settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == settingsWindow {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NSApp.setActivationPolicy(.regular)
        settingsWindow?.makeKeyAndOrderFront(nil)
        return true
    }
}

class PlayerNSView: NSView {
    let playerLayer = AVPlayerLayer()
    var batteryTimer: Timer?
    var pauseWorkItem: DispatchWorkItem?
    var wakeWorkItem: DispatchWorkItem?
    var occlusionWorkItem: DispatchWorkItem?
    var onWake: (() -> Void)?
    private var isCleanedUp = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer = CALayer()
        playerLayer.videoGravity = .resizeAspectFill
        self.layer?.addSublayer(playerLayer)
        
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            PowerManager.shared.refreshIfNeeded(force: true)
            self?.evaluatePlayback()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    deinit {
        cleanup()
    }
    
    func cleanup() {
        guard !isCleanedUp else { return }
        isCleanedUp = true
        
        batteryTimer?.invalidate()
        batteryTimer = nil
        pauseWorkItem?.cancel()
        pauseWorkItem = nil
        wakeWorkItem?.cancel()
        wakeWorkItem = nil
        occlusionWorkItem?.cancel()
        occlusionWorkItem = nil
        
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        
        if let player = playerLayer.player as? AVQueuePlayer {
            player.pause()
            player.removeAllItems()
        }
        playerLayer.player = nil
    }
    
    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = self.bounds
        CATransaction.commit()
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        
        guard let window = self.window else {
            // View removed from window, pause to conserve resources
            (playerLayer.player as? AVQueuePlayer)?.pause()
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleOcclusionChange), name: NSWindow.didChangeOcclusionStateNotification, object: window)
        
        // Handle both screen sleep/wake and system sleep/wake
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepMac), name: NSWorkspace.screensDidSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepMac), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleWake), name: NSWorkspace.didWakeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePowerChange), name: NSNotification.Name.NSProcessInfoPowerStateDidChange, object: nil)
    }
    
    @objc private func handlePowerChange() {
        PowerManager.shared.refreshIfNeeded(force: true)
        evaluatePlayback()
    }
    
    @objc private func handleOcclusionChange() {
        // Debounce occlusion change by 100ms so moving windows around doesn't rapidly bounce playback
        occlusionWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.evaluatePlayback()
        }
        occlusionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }
    
    @objc func evaluatePlayback() {
        guard let player = playerLayer.player as? AVQueuePlayer, !isCleanedUp else { return }
        
        if globalSettings.isPaused {
            if player.timeControlStatus != .paused {
                player.pause()
            }
            return
        }
        
        PowerManager.shared.refreshIfNeeded()
        let onBattery = PowerManager.shared.isOnBattery
        let batteryPct = PowerManager.shared.batteryPercentage
        let lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        if globalSettings.pauseBatteryThreshold > 0 && onBattery {
            if globalSettings.pauseBatteryThreshold == 100 || batteryPct <= globalSettings.pauseBatteryThreshold {
                if player.timeControlStatus != .paused {
                    player.pause()
                }
                return
            }
        }
        
        guard let window = self.window else {
            if player.timeControlStatus != .playing {
                player.play()
            }
            return
        }
        
        if window.occlusionState.contains(.visible) {
            pauseWorkItem?.cancel()
            pauseWorkItem = nil
            
            let targetRate: Float
            if globalSettings.smartPowerSaving && (lowPowerMode || onBattery) {
                if lowPowerMode || batteryPct <= 20 {
                    targetRate = Float(globalSettings.playbackSpeed) * 0.25
                } else if onBattery {
                    targetRate = Float(globalSettings.playbackSpeed) * 0.5
                } else {
                    targetRate = Float(globalSettings.playbackSpeed)
                }
            } else {
                targetRate = Float(globalSettings.playbackSpeed)
            }
            
            // Only update rate if it actually changed, avoiding timebase clock jitter
            if abs(player.rate - targetRate) > 0.01 {
                player.rate = targetRate
            }
            
            // Only call play() if not already playing
            if player.timeControlStatus != .playing {
                player.play()
            }
        } else {
            if pauseWorkItem == nil {
                let workItem = DispatchWorkItem { [weak self, weak player] in
                    guard let self = self, let window = self.window, !window.occlusionState.contains(.visible) else { return }
                    if player?.timeControlStatus != .paused {
                        player?.pause()
                    }
                    self.pauseWorkItem = nil
                }
                pauseWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
            }
        }
    }
    
    @objc func sleepMac() {
        pauseWorkItem?.cancel()
        pauseWorkItem = nil
        wakeWorkItem?.cancel()
        wakeWorkItem = nil
        (playerLayer.player as? AVQueuePlayer)?.pause()
    }
    
    @objc func handleWake() {
        wakeWorkItem?.cancel()
        // Allow macOS WindowServer and Metal GPU context 0.8s to fully stabilize after wake
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, !self.isCleanedUp else { return }
            self.onWake?()
            self.evaluatePlayback()
        }
        wakeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: workItem)
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
        case 1:
            nsView.imageScaling = .scaleProportionallyUpOrDown
        case 2:
            nsView.imageScaling = .scaleAxesIndependently
        default: // 0: Fill
            nsView.imageScaling = .scaleProportionallyUpOrDown
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
        context.coordinator.currentURL = url
        play(url: url, player: player, coordinator: context.coordinator)
        applySettings(to: player, layer: view.playerLayer, view: view)
        
        view.onWake = { [weak player, weak coordinator = context.coordinator] in
            guard let player = player, let coordinator = coordinator, let currentURL = coordinator.currentURL else { return }
            if player.currentItem == nil {
                play(url: currentURL, player: player, coordinator: coordinator)
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: PlayerNSView, context: Context) {
        if let player = nsView.playerLayer.player as? AVQueuePlayer {
            if context.coordinator.currentURL != url {
                context.coordinator.currentURL = url
                play(url: url, player: player, coordinator: context.coordinator)
            }
            // Ensure onWake always references the currently active URL even when view is reused
            nsView.onWake = { [weak player, weak coordinator = context.coordinator] in
                guard let player = player, let coordinator = coordinator, let currentURL = coordinator.currentURL else { return }
                if player.currentItem == nil {
                    play(url: currentURL, player: player, coordinator: coordinator)
                }
            }
            applySettings(to: player, layer: nsView.playerLayer, view: nsView)
        }
    }
    
    static func dismantleNSView(_ nsView: PlayerNSView, coordinator: Coordinator) {
        coordinator.loadTask?.cancel()
        coordinator.loadTask = nil
        coordinator.looper?.disableLooping()
        coordinator.looper = nil
        nsView.cleanup()
    }
    
    private func applySettings(to player: AVQueuePlayer, layer: AVPlayerLayer, view: PlayerNSView) {
        let isMuted = settings.isMuted
        if player.isMuted != isMuted {
            player.isMuted = isMuted
        }
        let targetVolume = isMuted ? 0.0 : Float(settings.volume)
        if abs(player.volume - targetVolume) > 0.01 {
            player.volume = targetVolume
        }
        
        let targetRate = Float(settings.playbackSpeed)
        if abs(player.defaultRate - targetRate) > 0.01 {
            player.defaultRate = targetRate
        }
        
        let targetGravity: AVLayerVideoGravity
        switch settings.scaleMode {
        case 1: targetGravity = .resizeAspect
        case 2: targetGravity = .resize
        default: targetGravity = .resizeAspectFill
        }
        if layer.videoGravity != targetGravity {
            layer.videoGravity = targetGravity
        }
        
        view.evaluatePlayback()
    }
    
    private func play(url: URL, player: AVQueuePlayer, coordinator: Coordinator) {
        coordinator.currentURL = url
        coordinator.loadTask?.cancel()
        
        // Execute player item clearing on MainActor to avoid background data races
        coordinator.looper?.disableLooping()
        coordinator.looper = nil
        player.removeAllItems()
        
        coordinator.loadTask = Task {
            let asset = AVURLAsset(url: url)
            var assetToPlay: AVAsset = asset
            
            let composition = AVMutableComposition()
            if let tracks = try? await asset.load(.tracks) {
                if Task.isCancelled { return }
                let videoTracks = tracks.filter { $0.mediaType == .video }
                
                if !videoTracks.isEmpty {
                    if let videoTimeRange = try? await videoTracks[0].load(.timeRange) {
                        if Task.isCancelled { return }
                        let videoDuration = videoTimeRange.duration
                        
                        for videoTrack in videoTracks {
                            if let compTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
                                try? compTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration), of: videoTrack, at: .zero)
                                if let transform = try? await videoTrack.load(.preferredTransform) {
                                    compTrack.preferredTransform = transform
                                }
                            }
                        }
                        
                        let audioTracks = tracks.filter { $0.mediaType == .audio }
                        for audioTrack in audioTracks {
                            if let compTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                                if let audioTimeRange = try? await audioTrack.load(.timeRange) {
                                    let safeDuration = CMTimeMinimum(videoDuration, audioTimeRange.duration)
                                    try? compTrack.insertTimeRange(CMTimeRange(start: .zero, duration: safeDuration), of: audioTrack, at: .zero)
                                }
                            }
                        }
                        
                        assetToPlay = composition
                    }
                }
            }
            
            if Task.isCancelled { return }
            let item = AVPlayerItem(asset: assetToPlay)
            
            await MainActor.run {
                if Task.isCancelled { return }
                player.preventsDisplaySleepDuringVideoPlayback = false
                coordinator.looper = AVPlayerLooper(player: player, templateItem: item)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator {
        var looper: AVPlayerLooper?
        var playerLayer: AVPlayerLayer?
        var currentURL: URL?
        var loadTask: Task<Void, Never>?
    }
}

struct OptionalBlurModifier: ViewModifier {
    let radius: Double
    func body(content: Content) -> some View {
        if radius > 0 {
            content.blur(radius: radius)
        } else {
            content
        }
    }
}

struct StaticImageView: View {
    let url: URL
    let scaleMode: Int
    @State private var image: NSImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: scaleMode == 1 ? .fit : .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
            } else {
                Color.black
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let img = NSImage(contentsOf: url) {
                DispatchQueue.main.async {
                    self.image = img
                }
            }
        }
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
                            StaticImageView(url: item.url, scaleMode: settings.scaleMode)
                        } else if ext == "gif" {
                            GIFPlayerView(url: item.url)
                        } else {
                            LoopingPlayerView(url: item.url)
                        }
                    }
                    .transition(.opacity)
                    .edgesIgnoringSafeArea(.all)
                }
                .modifier(OptionalBlurModifier(radius: settings.blurRadius))
                
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
    @ObservedObject var settings = globalSettings
    
    var activeItemTitle: String {
        guard let item = settings.activeItems.last else { return "No Wallpaper" }
        return item.url.deletingPathExtension().lastPathComponent
    }
    
    var body: some Scene {
        MenuBarExtra("Pentra", systemImage: "photo.tv") {
            Text("Now Playing: \(activeItemTitle)")
                .font(.caption)
            
            Divider()
            
            Button(settings.isPaused ? "Resume Playback" : "Pause Playback") {
                settings.isPaused.toggle()
            }
            
            Button("Next Wallpaper") {
                settings.nextPlaylistVideo()
            }
            
            Button(settings.isMuted ? "Unmute Audio" : "Mute Audio") {
                settings.isMuted.toggle()
            }
            
            Divider()
            
            Button("Open Settings") {
                NSApp.setActivationPolicy(.regular)
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
