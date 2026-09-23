# Keep WallpaperService, QuickTileService, BootReceiver — referenced by AndroidManifest
-keep class com.pentra.android.VideoWallpaperService { *; }
-keep class com.pentra.android.QuickTileService { *; }
-keep class com.pentra.android.BootReceiver { *; }

# Keep ExoPlayer
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keep,includedescriptorclasses class com.pentra.android.**$$serializer { *; }
-keepclassmembers class com.pentra.android.** {
    *** Companion;
}
