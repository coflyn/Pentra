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
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 15)
                .padding(.horizontal, 10)
                
                Spacer()
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
                                ForEach(settings.playlistPaths.indices, id: \.self) { index in
                                    let path = settings.playlistPaths[index]
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
                                            paths.remove(at: index)
                                            settings.playlistPaths = paths
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
                            Picker("", selection: $settings.pauseBatteryThreshold) {
                                Text("Never").tag(0)
                                Text("< 20%").tag(20)
                                Text("< 50%").tag(50)
                                Text("Always").tag(100)
                            }
                            .frame(width: 120)
                        }
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
        DispatchQueue.global(qos: .userInitiated).async {
            let url = URL(fileURLWithPath: path)
            let ext = url.pathExtension.lowercased()
            if ["jpg", "jpeg", "png", "heic", "gif", "webp"].contains(ext) {
                if let image = NSImage(contentsOf: url) {
                    DispatchQueue.main.async { self.thumbnail = image }
                }
                return
            }
            
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 300, height: 300)
            
            let time = CMTime(seconds: 1.0, preferredTimescale: 600)
            
            if let cgImage = try? imageGenerator.copyCGImage(at: time, actualTime: nil) {
                let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                DispatchQueue.main.async { self.thumbnail = image }
            } else {
                let timeZero = CMTime(seconds: 0.0, preferredTimescale: 600)
                if let cgImage = try? imageGenerator.copyCGImage(at: timeZero, actualTime: nil) {
                    let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                    DispatchQueue.main.async { self.thumbnail = image }
                }
            }
        }
    }
}
