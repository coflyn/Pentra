import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var settings: WallpaperSettings
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 20) {
                Spacer()
                
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                
                VStack(spacing: 4) {
                    Text("Pentra")
                        .font(.system(size: 22, weight: .bold))
                    Text("Live Wallpaper")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    NSWorkspace.shared.open(URL(string: "https://sociabuzz.com/coflyn")!)
                }) {
                    HStack {
                        Image(systemName: "cup.and.saucer.fill")
                        Text("Support Me")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 15)
                .padding(.horizontal, 10)
                
                VStack(spacing: 8) {
                    Text("Find Wallpapers")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.8))
                        .textCase(.uppercase)
                    
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Button(action: {
                                NSWorkspace.shared.open(URL(string: "https://moewalls.com/")!)
                            }) {
                                Text("Moewalls")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                NSWorkspace.shared.open(URL(string: "https://motionbgs.com/")!)
                            }) {
                                Text("MotionBGS")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        HStack(spacing: 6) {
                            Button(action: {
                                NSWorkspace.shared.open(URL(string: "https://wallhaven.cc/")!)
                            }) {
                                Text("Wallhaven")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                NSWorkspace.shared.open(URL(string: "https://unsplash.com/")!)
                            }) {
                                Text("Unsplash")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .padding(.top, 10)
                
                Spacer()
                
                VStack(spacing: 12) {
                    HStack(spacing: 18) {
                        Button(action: {
                            NSWorkspace.shared.open(URL(string: "https://github.com/coflyn")!)
                        }) {
                            Image("github")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            NSWorkspace.shared.open(URL(string: "https://instagram.com/_coflyn")!)
                        }) {
                            Image("instagram")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    VStack(spacing: 6) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(settings.isPaused ? Color.yellow : Color.green)
                                .frame(width: 6, height: 6)
                            Text(settings.isPaused ? "Engine Paused" : "Engine Running")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Version 1.1.0 • © 2026 Coflyn")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                .padding(.bottom, 5)
            }
            .padding(25)
            .frame(width: 220)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Right Section
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    SettingsCard(title: "Wallpaper Source") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(settings.playlistPaths.enumerated()), id: \.element) { index, path in
                                    ZStack(alignment: .topTrailing) {
                                        VideoThumbnailView(path: path)
                                            .frame(width: 120, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                            )
                                        
                                        Button(action: {
                                            var paths = settings.playlistPaths
                                            if let idx = paths.firstIndex(of: path) {
                                                paths.remove(at: idx)
                                                settings.playlistPaths = paths
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.white))
                                        }
                                        .buttonStyle(.plain)
                                        .offset(x: 5, y: -5)
                                    }
                                }
                                
                                Button(action: addVideo) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                            .frame(width: 120, height: 80)
                                        Image(systemName: "plus").font(.title)
                                    }
                                    .contentShape(Rectangle())
                                    .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 5)
                            .padding(.trailing, 10)
                        }
                        
                        if settings.playlistPaths.count > 1 {
                            Divider()
                            HStack {
                                Text("Change Wallpaper Every:")
                                Spacer()
                                Picker("", selection: Binding(
                                    get: {
                                        let predefined = [1, 5, 10, 15, 30, 60]
                                        return predefined.contains(settings.playlistInterval) ? settings.playlistInterval : -1
                                    },
                                    set: { newValue in
                                        if newValue == -1 {
                                            if [1, 5, 10, 15, 30, 60].contains(settings.playlistInterval) {
                                                settings.playlistInterval = 2
                                            }
                                        } else {
                                            settings.playlistInterval = newValue
                                        }
                                    }
                                )) {
                                    Text("1 min").tag(1)
                                    Text("5 min").tag(5)
                                    Text("10 min").tag(10)
                                    Text("15 min").tag(15)
                                    Text("30 min").tag(30)
                                    Text("1 hour").tag(60)
                                    Text("Custom").tag(-1)
                                }
                                .frame(width: 100)
                                
                                if ![1, 5, 10, 15, 30, 60].contains(settings.playlistInterval) {
                                    TextField("Min", value: $settings.playlistInterval, formatter: NumberFormatter())
                                        .frame(width: 50)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                    }
                    
                    SettingsCard(title: "Display & Audio") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Wallpaper Brightness").font(.subheadline)
                            HStack {
                                Image(systemName: "sun.min").foregroundColor(.secondary)
                                Slider(value: $settings.brightness, in: 0.1...1.0)
                                    .tint(.gray)
                                Image(systemName: "sun.max").foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cinematic Blur").font(.subheadline)
                            HStack {
                                Image(systemName: "drop").foregroundColor(.secondary)
                                Slider(value: $settings.blurRadius, in: 0.0...30.0)
                                    .tint(.gray)
                                Image(systemName: "drop.fill").foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scale Mode").font(.subheadline)
                            Picker("", selection: $settings.scaleMode) {
                                Text("Fill").tag(0)
                                Text("Fit").tag(1)
                                Text("Stretch").tag(2)
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        Divider()
                        
                        ToggleRow(icon: "speaker.slash", title: "Mute Audio", isOn: $settings.isMuted)
                        if !settings.isMuted {
                            HStack {
                                Image(systemName: "speaker.wave.1").foregroundColor(.secondary)
                                Slider(value: $settings.volume, in: 0.0...1.0).tint(.gray)
                                Image(systemName: "speaker.wave.3").foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    
                    SettingsCard(title: "Behavior") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Playback Speed").font(.subheadline)
                            Picker("", selection: $settings.playbackSpeed) {
                                Text("0.5x").tag(0.5)
                                Text("1.0x").tag(1.0)
                                Text("1.5x").tag(1.5)
                                Text("2.0x").tag(2.0)
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        Divider()
                        ToggleRow(icon: "pause.circle", title: "Pause Wallpaper", isOn: $settings.isPaused)
                        Divider()
                        HStack {
                            Label("Pause on Battery", systemImage: "battery.50")
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Picker("", selection: Binding(
                                get: {
                                    let predefined = [0, 20, 50]
                                    return predefined.contains(settings.pauseBatteryThreshold) ? settings.pauseBatteryThreshold : -1
                                },
                                set: { newValue in
                                    if newValue == -1 {
                                        if [0, 20, 50].contains(settings.pauseBatteryThreshold) {
                                            settings.pauseBatteryThreshold = 30
                                        }
                                    } else {
                                        settings.pauseBatteryThreshold = newValue
                                    }
                                }
                            )) {
                                Text("Never").tag(0)
                                Text("< 20%").tag(20)
                                Text("< 50%").tag(50)
                                Text("Custom").tag(-1)
                            }
                            .frame(width: 90)
                            
                            if ![0, 20, 50].contains(settings.pauseBatteryThreshold) {
                                HStack(spacing: 4) {
                                    Text("<")
                                        .foregroundColor(.secondary)
                                    TextField("%", value: $settings.pauseBatteryThreshold, formatter: NumberFormatter())
                                        .frame(width: 45)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        Divider()
                        ToggleRow(icon: "leaf", title: "Smart Power Saving", isOn: $settings.smartPowerSaving)
                        Divider()
                        ToggleRow(icon: "power", title: "Start at Login", isOn: $settings.launchAtLogin)
                        Divider()
                        ToggleRow(icon: "menubar.rectangle", title: "Sync Menu Bar Color", isOn: $settings.syncMenuBar)
                    }
                }
                .padding(25)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 650, minHeight: 520)
        .background(.ultraThinMaterial)
        .onAppear { settings.syncLaunchAtLoginState() }
    }
    
    private func addVideo() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.movie, UTType.mpeg4Movie, UTType.quickTimeMovie, UTType.image, UTType.gif, UTType.png, UTType.jpeg]
        
        if panel.runModal() == .OK {
            var paths = settings.playlistPaths
            for url in panel.urls {
                if !paths.contains(url.path) {
                    paths.append(url.path)
                }
            }
            settings.playlistPaths = paths
        }
    }
}

// MARK: - Helper UI Components

struct SettingsCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 12) {
                content
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
        }
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(.gray)
        }
    }
}

struct VideoThumbnailView: View {
    let path: String
    @State private var thumbnail: NSImage?
    
    var body: some View {
        Group {
            if let img = thumbnail {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color(NSColor.controlBackgroundColor)
                    ProgressView().scaleEffect(0.5)
                }
            }
        }
        .onAppear {
            generateThumbnailAsync()
        }
    }
    
    private func generateThumbnailAsync() {
        Task {
            let url = URL(fileURLWithPath: path)
            let ext = url.pathExtension.lowercased()
            if ["jpg", "jpeg", "png", "heic", "gif", "webp"].contains(ext) {
                if let image = NSImage(contentsOf: url) {
                    DispatchQueue.main.async { self.thumbnail = image }
                }
                return
            }
            
            let asset = AVURLAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 300, height: 300)
            
            let time = CMTime(seconds: 1.0, preferredTimescale: 600)
            
            if let (cgImage, _) = try? await imageGenerator.image(at: time) {
                let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                DispatchQueue.main.async { self.thumbnail = image }
            } else {
                let timeZero = CMTime(seconds: 0.0, preferredTimescale: 600)
                if let (cgImage, _) = try? await imageGenerator.image(at: timeZero) {
                    let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                    DispatchQueue.main.async { self.thumbnail = image }
                }
            }
        }
    }
}
