package com.pentra.android

import android.content.SharedPreferences
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

class QuickTileService : TileService() {

    private val prefsListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        if (key == WallpaperPrefs.KEY_PLAYING_OVERRIDE) updateTile()
    }

    override fun onStartListening() {
        WallpaperPrefs.prefs(this).registerOnSharedPreferenceChangeListener(prefsListener)
        updateTile()
    }

    override fun onStopListening() {
        WallpaperPrefs.prefs(this).unregisterOnSharedPreferenceChangeListener(prefsListener)
    }

    override fun onClick() {
        val playing = WallpaperPrefs.getPlayingOverride(this)
        WallpaperPrefs.setPlayingOverride(this, !playing)
        updateTile()
    }

    private fun updateTile() {
        val tile = qsTile ?: return
        val playing = WallpaperPrefs.getPlayingOverride(this)
        tile.state = if (playing) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = if (playing) "Pentra: On" else "Pentra: Off"
        tile.updateTile()
    }
}
