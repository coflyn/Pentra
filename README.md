# Pentra Live Wallpaper

![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Android-black.svg?style=flat)
![Swift](https://img.shields.io/badge/macOS-Swift%205.9%20%2F%20SwiftUI-orange.svg?style=flat&logo=apple)
![Kotlin](https://img.shields.io/badge/Android-Kotlin%202.0%20%2F%20Compose-green.svg?style=flat&logo=android)
![Version](https://img.shields.io/badge/Version-1.3.0-blue.svg?style=flat)
![License](https://img.shields.io/badge/License-GPLv3-blue.svg?style=flat)

Pentra is an open source live wallpaper manager for macOS and Android. It runs video loops, animated GIFs, and image playlists as your desktop or home screen background while keeping CPU and battery consumption low.

---

## macOS Features

- Low memory footprint (~60MB RAM) using native `NSWindow` layering and `AVFoundation`.
- Media support: MP4, MOV, M4V, 3GP, animated GIF, JPG, PNG, WebP, and HEIC.
- Window reuse on wallpaper switch, avoiding black frames during playlist rotation.
- Visual playlist manager with thumbnail previews and live active indicators.
- Menu bar controls for playback state, track navigation, and audio mute.
- Drag and drop file import from Finder directly into the playlist.
- Configurable interval timer (1 minute to 1 hour), shuffle mode, or static playback.
- Menu bar tint sync that reflects the active wallpaper color without dock cache lag.
- Hardware-accelerated rendering up to 4K (3840x2160).
- Automatic playback pause when battery drops below a user-selected percentage via `IOKit`.
- Sleep and full-screen detection: pauses automatically during full-screen apps or system sleep, resuming playback immediately on wake.
- Playback filters: speed (0.5x to 2.0x), Gaussian blur, brightness, and volume.
- Launch at login support.

---

## Android Features

- Native live wallpaper engine built with AndroidX Media3 ExoPlayer (`VideoWallpaperService`).
- Video (MP4, WebM, MKV) and image (JPG, PNG, WebP, HEIC) support with aspect-fill cropping.
- Two-column playlist picker with persistable Storage Access Framework (SAF) URI grants.
- Dark UI built with Jetpack Compose and Material 3.
- Aspect ratio preservation to prevent video stretching on vertical phone displays.
- Preview sheet with adjustments for playback speed, volume, blur radius, brightness, and battery threshold.
- Quick Settings tile to toggle wallpaper playback from the notification shade.
- Battery saver integration to stop video decoding when battery falls below threshold.
- Adaptive launcher icons matching the macOS visual identity.

---

## Project Structure

```text
Pentra/
├── Pentra/                                # macOS application source
│   ├── PentraApp.swift                    # Core engine, window layering, menu bar, wallpaper sync
│   ├── ContentView.swift                  # SwiftUI settings interface and playlist manager
│   └── Assets.xcassets/                   # macOS app icons and assets
├── PentraAndroid/                         # Android application source
│   ├── app/src/main/
│   │   ├── kotlin/com/pentra/android/
│   │   │   ├── VideoWallpaperService.kt   # Live wallpaper engine (ExoPlayer and Canvas)
│   │   │   ├── BootReceiver.kt            # Boot receiver for wallpaper restore
│   │   │   ├── QuickTileService.kt        # Quick Settings tile service
│   │   │   ├── WallpaperPrefs.kt          # SharedPreferences store
│   │   │   └── ui/                        # Jetpack Compose UI
│   │   │       ├── MainActivity.kt        # Main entry point
│   │   │       ├── PlaylistScreen.kt      # Playlist grid and top app bar
│   │   │       ├── PlaylistViewModel.kt   # UI state and SAF URI handling
│   │   │       ├── SettingsSheet.kt       # Effects and preview bottom sheet
│   │   │       └── theme/                 # Dark theme colors and typography
│   │   └── res/                           # Android drawables, icons, and mipmaps
│   ├── build.gradle.kts                   # Gradle configuration and signing
│   └── gradle.properties                  # JVM and build options
├── Pentra.dmg                             # Prebuilt macOS disk image (installer)
├── Pentra.apk                             # Prebuilt Android release APK
├── README.md                              # Project documentation
├── LICENSE                                # GPLv3 license
└── .gitignore
```

---

## Installation & Building

### macOS
1. Download [Pentra.dmg](Pentra.dmg).
2. Open the disk image and drag **Pentra.app** to `/Applications`.

> [!IMPORTANT]
> **macOS Gatekeeper Warning:**
> Pentra is not signed with an Apple Developer ID certificate. macOS may report that the app is damaged or from an unidentified developer.
>
> Clear the quarantine flag in Terminal before opening:
> ```bash
> sudo xattr -cr /Applications/Pentra.app
> ```

To build the macOS release binary locally with Xcode:
```bash
xcodebuild -scheme Pentra -configuration Release clean build
```

### Android
1. Download [Pentra.apk](Pentra.apk) and open it on your Android device to install.

To build the signed release APK with Gradle:
```bash
cd PentraAndroid
./gradlew assembleRelease
```
The output APK is written to:
`PentraAndroid/app/build/outputs/apk/release/app-release.apk`

---

## Requirements

- **macOS:** macOS 13.0 (Ventura) or later, Xcode 15+ (for local builds).
- **Android:** Android 8.0 (API 26) or later, JDK 17+ (for local builds).

---

## License

GNU General Public License v3.0 (GPLv3). See [LICENSE](LICENSE) for details.
