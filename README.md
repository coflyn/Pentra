# Pentra Live Wallpaper

![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Android-black.svg?style=flat)
![Swift](https://img.shields.io/badge/macOS-Swift%205.9%20%2F%20SwiftUI-orange.svg?style=flat&logo=apple)
![Kotlin](https://img.shields.io/badge/Android-Kotlin%202.0%20%2F%20Compose-green.svg?style=flat&logo=android)
![Version](https://img.shields.io/badge/Version-1.2.0-blue.svg?style=flat)
![License](https://img.shields.io/badge/License-GPLv3-blue.svg?style=flat)

Pentra is a lightweight, high-performance Live Wallpaper engine for macOS and Android. It allows you to set video wallpapers, animated loops, or playlists as your desktop or mobile background without sacrificing battery or system performance.

---

## macOS Features

- **Native & Lightweight:** Built directly on top of macOS APIs (`NSWindow` and `AVFoundation`) for a minimal memory footprint (~60MB RAM).
- **Universal Media Engine:** Seamlessly supports Videos (MP4, MOV, M4V, 3GP), Animated GIFs, and High-Res Images (JPG, PNG, WebP, HEIC).
- **Zero Black Flash Window Reuse:** Seamlessly reuses existing wallpaper windows across playlist changes, eliminating the 0.5s black flash on wallpaper switch.
- **Visual Playlist Manager:** Manage wallpapers with interactive thumbnail previews. Click any thumbnail to activate it immediately with real-time active indicators.
- **Menu Bar Quick Controls:** Control playback directly from the macOS Menu Bar (Now Playing title, Play/Pause, Next Wallpaper, Mute/Unmute).
- **Drag & Drop Import:** Drag video and image files directly from Finder into the Settings window to instantly add them to your playlist.
- **Shuffle & Flexible Timers:** Cycle wallpapers sequentially or randomly, with custom intervals (1 min to 1 hour) or a **Never** static mode.
- **Display Keep-Awake:** Optional toggle in settings to prevent display sleep via `IOPMAssertion` while keeping system power management intact.
- **Menu Bar Color Sync:** Automatically syncs your native macOS wallpaper behind the scenes for translucent menu bar color matching without desktop caching lag.
- **Dynamic 4K Native Support:** Native hardware-accelerated playback and Menu Bar sync up to **4K (3840x2160)** resolution.
- **Smart Battery Threshold:** Leverages `IOKit` to read raw battery capacity and automatically pause playback below your chosen battery percentage.
- **Smart Auto-Pause & Deep Sleep Recovery:**
  - Automatically pauses video playback when your Mac goes to sleep or when full-screen applications/games are active.
  - Session active listeners, looper stall handlers, and screen guard logic guarantee instant playback resumption without black screen when opening the lid or waking from sleep.
- **Cinematic Controls:** Adjust playback speed (0.5x to 2.0x), apply real-time Gaussian Blur, tweak brightness, and control volume.
- **Start at Login:** Automatically launches quietly in the background when you start your Mac.

---

## Android Features (PentraAndroid)

- **Native Android Live Wallpaper Service:** Powered by Media3 ExoPlayer with hardware-accelerated video decoding (`VideoWallpaperService`).
- **Universal Media Engine:** Supports both high-performance videos (MP4, WebM, MKV) and static images (JPG, PNG, WebP, HEIC) with aspect-fill cropping.
- **Instant Wallpaper Selection:** Pick and activate any wallpaper directly from the 2-column playlist grid with persistable SAF URI grants.
- **Modern Jetpack Compose UI:** Premium dark-themed interface built with Material 3.
- **Aspect Ratio Preservation:** Native 9:16 vertical previews and fill-with-crop live wallpaper scaling to prevent video stretching or distortion.
- **Live Wallpaper Preview Sheet:** Interactive bottom sheet with real-time effects preview (speed, volume, blur radius, brightness, battery threshold).
- **Quick Settings Tile:** Toggle wallpaper playback directly from your Android notification/quick settings panel.
- **Power Saver:** Automatically pauses live wallpaper when battery drops below your chosen threshold.
- **Matching Visual Identity:** Native adaptive icons and round icons matching the original macOS Pentra icon.

---

## Project Structure

```text
Pentra/
├── Pentra/                                # macOS Application Source
│   ├── PentraApp.swift                    # Main Engine, Multi-screen Window Layering, Menu Bar & Display Sleep Preventer
│   ├── ContentView.swift                  # SwiftUI Settings Interface & Visual Playlist Manager
│   └── Assets.xcassets/                   # macOS App Icons & Asset Catalog
├── PentraAndroid/                         # Android Application Source
│   ├── app/src/main/
│   │   ├── kotlin/com/pentra/android/
│   │   │   ├── VideoWallpaperService.kt   # Live Wallpaper Engine (ExoPlayer & Canvas Image Rendering)
│   │   │   ├── BootReceiver.kt            # Boot Receiver for Wallpaper State Restoration
│   │   │   ├── QuickTileService.kt        # Quick Settings Tile (Play/Pause Toggle)
│   │   │   ├── WallpaperPrefs.kt          # SharedPreferences State Store
│   │   │   └── ui/                        # Jetpack Compose UI
│   │   │       ├── MainActivity.kt        # App Entry Point
│   │   │       ├── PlaylistScreen.kt      # Visual 2-Column Wallpaper Grid & Top Bar
│   │   │       ├── PlaylistViewModel.kt   # UI State & SAF Persistable URI Grants
│   │   │       ├── SettingsSheet.kt       # Effects Sheet (Speed, Blur, Brightness, Preview)
│   │   │       └── theme/                 # Jetpack Compose Dark Theme & Colors
│   │   └── res/                           # Android Adaptive Icons, Vectors & Mipmaps
│   ├── build.gradle.kts                   # Gradle Build Config & Signing
│   └── gradle.properties                  # JVM & R8 Heap Settings
├── Pentra.dmg                             # Compiled macOS Disk Image (with Applications Shortcut)
├── Pentra.apk                             # Compiled Android Signed Release APK
├── README.md                              # Documentation & Release Notes
├── LICENSE                                # GNU General Public License v3.0 (GPLv3)
└── .gitignore                             # Git Ignore Rules
```

---

## Installation & Building

### macOS
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

### Android
1. Download **[Pentra.apk](Pentra.apk)** directly from this repository and install on your device.

Or build signed release APK with Gradle:
```bash
cd PentraAndroid
./gradlew assembleRelease
```
The compiled APK will be generated at:
`PentraAndroid/app/build/outputs/apk/release/app-release.apk`

---

## Requirements

- **macOS:** macOS 13.0 (Ventura) or later, Xcode 15+ (for building).
- **Android:** Android 8.0 (API 26) or later, JDK 17+ (for building).

## License

This project is licensed under the **GNU General Public License v3.0 (GPLv3)**. See the [LICENSE](LICENSE) file for details.
