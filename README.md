# Pentra Live Wallpaper

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg?style=flat)
![macOS](https://img.shields.io/badge/macOS-13.0+-black.svg?style=flat&logo=apple)
![Framework](https://img.shields.io/badge/Framework-SwiftUI-blue.svg?style=flat)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat)

Pentra is a lightweight, high-performance Live Wallpaper engine for macOS built natively with Swift, SwiftUI, and AppKit. It allows you to set any MP4/MOV video, animated GIF, or static image as your desktop background without sacrificing system performance.

## Features

- **Native & Lightweight:** Built directly on top of macOS APIs (`NSWindow` and `AVFoundation`) for minimal memory footprint.
- **Universal Media Engine:** Seamlessly supports Videos (MP4, MOV), Animated GIFs, and High-Res Images (JPG, PNG, WebP, HEIC).
- **Visual Playlist Manager:** Select multiple media files and auto-cycle through them at a user-defined interval.
- **Menu Bar Sync:** Automatically updates your native macOS wallpaper behind the scenes to seamlessly match the current video's color palette, fixing dark menu bars on bright videos. This feature is fully toggleable.
- **Smart Battery Threshold:** Leverages `IOKit` to read raw battery capacity and automatically pause the engine when the battery drops below your chosen threshold (e.g., < 20%, < 50%, or always on battery).
- **Hardware Acceleration:** Utilizes Apple's native hardware decoding for video playback, taking the load off your CPU.
- **Smart Auto-Pause:**
  - Automatically pauses video playback when your Mac goes to sleep.
  - Automatically pauses when a full-screen application (like a game or browser) is active, ensuring 100% of your Mac's resources go to your active task.
- **Cinematic Controls:** Customize your experience by adjusting playback speed (0.5x to 2.0x), applying a real-time Gaussian Blur, and tweaking wallpaper brightness so your desktop icons always pop.
- **Start at Login:** Automatically launches quietly in the background when you turn on your Mac.
- **Menu Bar Integration:** Easily accessible from your macOS Menu Bar.
- **Customizable Display & Audio:** Choose between Fill, Fit, or Stretch scale modes, and adjust video volume (or mute completely).

## What's New

- **Universal Format Support:** Added native rendering logic for animated GIFs and static images (JPG/PNG/WebP/HEIC), making Pentra a fully versatile wallpaper engine.
- **Smart Renderer Routing:** Dynamically delegates rendering to `AVPlayer` for video, `NSImageView` for GIFs, and SwiftUI `Image` for static formats to ensure optimal performance.
- **Anti-Flicker Playlist Engine:** Re-architected the playlist timer logic to seamlessly handle interval changes and video deletions without black flashes or visual resets.
- **Cinematic Blur Slider:** Added GPU-accelerated real-time blurring (`.blur()`) to create stunning frosted-glass aesthetics for your desktop videos.
- **Advanced Power Management:** Upgraded the battery saver from a simple toggle to a precision dropdown, letting you set custom pause thresholds (e.g., < 20% battery).
- **Custom Minute Intervals:** Replaced the rigid stepper with a smart dropdown that dynamically reveals a text field for entering custom playlist intervals.
- **Broadcast-Grade Crossfades:** Implemented a dual-player ZStack architecture for perfectly seamless video transitions.
- **Refined Hitboxes:** Re-engineered the playlist UI with expanded `.contentShape(Rectangle())` for frictionless interaction when adding videos.
- **Centered Navigation:** Architecturally re-aligned the sidebar for perfect vertical centering, emphasizing the app logo and title.
- **Pure Monochrome UI:** Adopted a sleek, distraction-free monochrome design language across the entire application interface.

## Requirements

- macOS 13.0 (Ventura) or later.
- Xcode 15+ (for building).

## Built With

- Swift & SwiftUI (User Interface)
- AppKit (Window Layering & Occlusion Detection)
- AVKit / AVFoundation (Video Rendering Engine)
