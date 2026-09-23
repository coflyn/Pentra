package com.pentra.android

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) return

        // If the user had a wallpaper active before reboot, Android restores
        // WallpaperService automatically. BootReceiver exists to re-apply
        // settings that may have been cleared (e.g., playing override reset).
        WallpaperPrefs.setPlayingOverride(context, true)
    }
}
