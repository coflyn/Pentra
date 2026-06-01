import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var settings: WallpaperSettings
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 70, height: 70)
                        .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "photo.tv")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text("Pentra")
                        .font(.system(size: 22, weight: .bold))
                    Text("Live Wallpaper")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Current Video")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    if !settings.videoPath.isEmpty {
                        Text(URL(fileURLWithPath: settings.videoPath).lastPathComponent)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    } else {
                        Text("None")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)
                
                Button(action: selectVideoFile) {
                    Label("Select Video", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.purple)
            }
            .padding(25)
            .frame(width: 220)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Preferences")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 2)
                    
                    SettingsCard(title: "General") {
                        ToggleRow(icon: "power", title: "Start at Login", isOn: $settings.launchAtLogin)
                        Divider()
                        ToggleRow(icon: "pause.circle", title: "Pause Wallpaper", isOn: $settings.isPaused)
                    }
                    
                    SettingsCard(title: "Audio") {
                        ToggleRow(icon: "speaker.slash", title: "Mute Audio", isOn: $settings.isMuted)
                        
                        if !settings.isMuted {
                            Divider()
                            HStack {
                                Image(systemName: "speaker.wave.1")
                                    .foregroundColor(.secondary)
                                Slider(value: $settings.volume, in: 0.0...1.0)
                                    .tint(.purple)
                                Image(systemName: "speaker.wave.3")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    
                    SettingsCard(title: "Display") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Scale Mode", systemImage: "aspectratio")
                                .font(.headline)
                            
                            Picker("", selection: $settings.scaleMode) {
                                Text("Fill").tag(0)
                                Text("Fit").tag(1)
                                Text("Stretch").tag(2)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                }
                .padding(25)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 550, minHeight: 400)
        .background(.ultraThinMaterial)
        .onAppear {
            settings.syncLaunchAtLoginState()
        }
    }
    
    private func selectVideoFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.movie, UTType.mpeg4Movie, UTType.quickTimeMovie]
        
        if panel.runModal() == .OK, let url = panel.url {
            settings.videoPath = url.path
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
            
            VStack(spacing: 10) {
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
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(.purple)
        }
    }
}
