# Pentra Live Wallpaper

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg?style=flat)
![macOS](https://img.shields.io/badge/macOS-13.0+-black.svg?style=flat&logo=apple)
![Framework](https://img.shields.io/badge/Framework-SwiftUI-blue.svg?style=flat)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat)

Pentra is a lightweight, high-performance Live Wallpaper engine for macOS built natively with Swift, SwiftUI, and AppKit. It allows you to set any MP4 or MOV video file as your desktop background without sacrificing system performance.

## Features

- **Native & Lightweight:** Built directly on top of macOS APIs (`NSWindow` and `AVFoundation`) for minimal memory footprint.
- **Hardware Acceleration:** Utilizes Apple's native hardware decoding for video playback, taking the load off your CPU.
- **Smart Auto-Pause:**
  - Automatically pauses video playback when your Mac goes to sleep.
  - Automatically pauses when a full-screen application (like a game or browser) is active, ensuring 100% of your Mac's resources go to your active task.
- **Start at Login:** Automatically launches quietly in the background when you turn on your Mac.
- **Menu Bar Integration:** Easily accessible from your macOS Menu Bar.
- **Customizable Display:** Choose between Fill, Fit, or Stretch scale modes.
- **Volume Control:** Enjoy silent wallpapers or enable audio with an adjustable volume slider.

## Requirements

- macOS 13.0 (Ventura) or later.
- Xcode 15+ (for building).

## Built With

- Swift & SwiftUI (User Interface)
- AppKit (Window Layering & Occlusion Detection)
- AVKit / AVFoundation (Video Rendering Engine)
