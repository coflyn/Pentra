# Pentra Live Wallpaper

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg?style=flat)
![macOS](https://img.shields.io/badge/macOS-13.0+-black.svg?style=flat&logo=apple)
![Framework](https://img.shields.io/badge/Framework-SwiftUI-blue.svg?style=flat)
![Version](https://img.shields.io/badge/Version-1.2.0-blue.svg?style=flat)
![License](https://img.shields.io/badge/License-GPLv3-blue.svg?style=flat)

Pentra is a lightweight, high-performance Live Wallpaper engine for macOS built natively with Swift, SwiftUI, and AppKit. It allows you to set any MP4/MOV video, animated GIF, or static image as your desktop background without sacrificing system performance.

## Features

- **Native & Lightweight:** Built directly on top of macOS APIs (`NSWindow` and `AVFoundation`) for a minimal memory footprint (~60MB RAM).
- **Universal Media Engine:** Seamlessly supports Videos (MP4, MOV, M4V, 3GP), Animated GIFs, and High-Res Images (JPG, PNG, WebP, HEIC).
- **Visual Playlist Manager:** Manage wallpapers with interactive thumbnail previews. Click any thumbnail to activate it immediately with real-time active indicators.
- **Menu Bar Quick Controls:** Control playback directly from the macOS Menu Bar (Now Playing title, Play/Pause, Next Wallpaper, Mute/Unmute).
- **Drag & Drop Import:** Drag video and image files directly from Finder into the Settings window to instantly add them to your playlist.
- **Shuffle & Flexible Timers:** Cycle wallpapers sequentially or randomly, with custom intervals (1 min to 1 hour) or a **Never** static mode.
- **Menu Bar Color Sync:** Automatically syncs your native macOS wallpaper behind the scenes for translucent menu bar color matching without desktop caching lag.
- **Dynamic 4K Native Support:** Native hardware-accelerated playback and Menu Bar sync up to **4K (3840x2160)** resolution.
- **Smart Battery Threshold:** Leverages `IOKit` to read raw battery capacity and automatically pause playback below your chosen battery percentage.
- **Smart Auto-Pause & Recovery:**
  - Automatically pauses video playback when your Mac goes to sleep or when full-screen applications/games are active.
  - **Deep Sleep Hardware Recovery:** Dynamic CoreVideo context rebuilding prevents the infamous `AVPlayer` black screen bug after waking from long sleep.
- **Cinematic Controls:** Adjust playback speed (0.5x to 2.0x), apply real-time Gaussian Blur, tweak brightness, and control volume.
- **Start at Login:** Automatically launches quietly in the background when you start your Mac.

## Project Structure

```text
Pentra/
├── Pentra.xcodeproj/              # Xcode Project Configuration
├── Pentra/                        # Source Code
│   ├── PentraApp.swift            # Main Engine, Window Layering, & Menu Bar Controls
│   ├── ContentView.swift          # SwiftUI Settings Interface & Visual Playlist Manager
│   └── Assets.xcassets/           # App Icons & Asset Catalog
├── README.md                      # Documentation & Release Notes
├── LICENSE                        # GNU General Public License v3.0 (GPLv3)
└── .gitignore                     # Git Ignore Rules
```

## What's New in v1.2.0

- **Menu Bar Quick Controls:** Added a quick-access dropdown in the macOS Menu Bar featuring the currently playing title ("Now Playing: <name>"), instant Play/Pause toggle, Next Wallpaper button, and Mute/Unmute audio control.
- **Shuffle Playlist Mode:** Introduced a "Shuffle Playlist" toggle in settings to randomly cycle through playlist wallpapers rather than strictly sequential order.
- **Drag & Drop File Import:** Enabled native `.onDrop` support on the Wallpaper Source card, allowing users to drag video and image files directly from Finder into Pentra.
- **Unrestricted Manual Next Wallpaper:** Refactored manual wallpaper cycling (`nextPlaylistVideo()`) to allow instant manual switching even when the auto-rotation timer is set to "Never".
- **Interactive Thumbnail Selection:** Click any wallpaper thumbnail in the Settings window to instantly activate and play it, highlighted by a real-time blue stroke and checkmark badge indicator.
- **"Never" Auto-Cycle Option:** Added a "Never" option to the playlist timer dropdown, allowing users to keep a single active wallpaper playing without automatic rotation.
- **macOS Menu Bar Cache Bypass:** Implemented alternating temporary file rotation (`pentra_sync_a.png` & `pentra_sync_b.png`) to break `NSWorkspace` URL caching, ensuring instant Menu Bar color and translucency updates when switching wallpapers.
- **Dynamic 4K Native Support:** Upgraded Menu Bar wallpaper sync to dynamically match target screen resolutions up to **4K (3840x2160)** for ultra-crisp Menu Bar aesthetics on 4K/Retina displays.
- **RAM Spike Prevention:** Introduced GPU-friendly bitmap downscaling for high-resolution static images (JPG, PNG, HEIC, GIF), eliminating uncompressed TIFF memory spikes.
- **Sync Task Cancellation Token:** Added strict `Task` cancellation handling (`syncTask?.cancel()`) to prevent I/O file write collisions during rapid playlist switches.
- **Strict Format Validation:** Restricted `NSOpenPanel` file picker to natively supported AVFoundation containers (`MP4`, `MOV`, `M4V`, `3GP`) and image formats (`JPG`, `PNG`, `HEIC`, `WEBP`, `GIF`), explicitly disallowing unsupported containers like `.mkv` and `.webm`.
- **Automatic Dead Path Filter:** Added `validPlaylistPaths` validation via `FileManager` to automatically skip deleted files or unmounted external drives without black screen freezes.

## Previous Updates in v1.1.0

- **Zero-Leak Engine Architecture:** Fixed strong reference cycles in `PlayerNSView` timer loops and observers, completely eliminating RAM leaks during playlist cycling and display configuration changes.
- **Instant Sleep/Wake Recovery:** Restructured wake handlers to preserve `AVPlayerItem` status and seek gracefully without destroying looper instances, eliminating black screen delays when waking from sleep.
- **Disk Footprint Optimization:** Optimized native wallpaper sync to use a single fixed temporary image file, preventing `/tmp` file accumulation.
- **Task Cancellation & Anti-Race Engine:** Added strict task cancellation tokens (`loadTask?.cancel()`) to prevent out-of-order video loading when changing playlist items rapidly.
- **Accurate Power Detection:** Upgraded battery status check to read `kIOPSPowerSourceStateKey` directly from `IOKit`, fixing false AC power reporting while estimating battery life.
- **Safe UI Playlist Operations:** Updated playlist deletion logic to remove items by path reference, preventing out-of-bounds array exceptions.

## Installation & Gatekeeper Fix

1. Download **[Pentra.dmg](Pentra.dmg)** from this repository.
2. Open the `.dmg` file and drag **Pentra.app** into your `/Applications` folder.

> [!IMPORTANT]
> **macOS Gatekeeper Warning ("App is damaged" or "Developer cannot be verified"):**
> Because Pentra is a free open-source app distributed directly without a paid Apple Developer ID signature, macOS Gatekeeper may flag the downloaded app with a quarantine attribute.
> 
> To bypass this restriction and launch Pentra, open your **Terminal** app and run:
> ```bash
> sudo xattr -cr /Applications/Pentra.app
> ```

## Requirements

- macOS 13.0 (Ventura) or later.
- Xcode 15+ (for building).

## Built With

- Swift & SwiftUI (User Interface)
- AppKit (Window Layering & Occlusion Detection)
- AVKit / AVFoundation (Video Rendering Engine)

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. See the [LICENSE](LICENSE) file for details.
