package com.pentra.android

import android.content.Context
import android.content.SharedPreferences
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

object WallpaperPrefs {

    private const val PREFS_NAME = "pentra_prefs"

    const val KEY_ACTIVE_PATH = "active_path"
    const val KEY_PLAYLIST = "playlist_paths"
    const val KEY_SHUFFLE = "shuffle"
    const val KEY_INTERVAL_MINUTES = "interval_minutes"
    const val KEY_BATTERY_THRESHOLD = "battery_threshold"
    const val KEY_PLAYBACK_SPEED = "playback_speed"
    const val KEY_VOLUME = "volume"
    const val KEY_BLUR_RADIUS = "blur_radius"
    const val KEY_BRIGHTNESS = "brightness"
    const val KEY_PLAYING_OVERRIDE = "is_playing_override"

    fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun getActivePath(context: Context): String =
        prefs(context).getString(KEY_ACTIVE_PATH, "") ?: ""

    fun setActivePath(context: Context, path: String) {
        prefs(context).edit().putString(KEY_ACTIVE_PATH, path).apply()
    }

    fun getPlaylist(context: Context): List<String> {
        val json = prefs(context).getString(KEY_PLAYLIST, "[]") ?: "[]"
        return try {
            Json.decodeFromString(json)
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun setPlaylist(context: Context, paths: List<String>) {
        prefs(context).edit()
            .putString(KEY_PLAYLIST, Json.encodeToString(paths))
            .apply()
    }

    fun getShuffle(context: Context): Boolean =
        prefs(context).getBoolean(KEY_SHUFFLE, false)

    fun setShuffle(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_SHUFFLE, enabled).apply()
    }

    fun getIntervalMinutes(context: Context): Int =
        prefs(context).getInt(KEY_INTERVAL_MINUTES, 0)

    fun setIntervalMinutes(context: Context, minutes: Int) {
        prefs(context).edit().putInt(KEY_INTERVAL_MINUTES, minutes).apply()
    }

    fun getBatteryThreshold(context: Context): Int =
        prefs(context).getInt(KEY_BATTERY_THRESHOLD, 20)

    fun setBatteryThreshold(context: Context, percent: Int) {
        prefs(context).edit().putInt(KEY_BATTERY_THRESHOLD, percent).apply()
    }

    fun getPlaybackSpeed(context: Context): Float =
        prefs(context).getFloat(KEY_PLAYBACK_SPEED, 1.0f)

    fun setPlaybackSpeed(context: Context, speed: Float) {
        prefs(context).edit().putFloat(KEY_PLAYBACK_SPEED, speed).apply()
    }

    fun getVolume(context: Context): Float =
        prefs(context).getFloat(KEY_VOLUME, 0.0f)

    fun setVolume(context: Context, volume: Float) {
        prefs(context).edit().putFloat(KEY_VOLUME, volume).apply()
    }

    fun getBlurRadius(context: Context): Float =
        prefs(context).getFloat(KEY_BLUR_RADIUS, 0.0f)

    fun setBlurRadius(context: Context, radius: Float) {
        prefs(context).edit().putFloat(KEY_BLUR_RADIUS, radius).apply()
    }

    fun getBrightness(context: Context): Float =
        prefs(context).getFloat(KEY_BRIGHTNESS, 1.0f)

    fun setBrightness(context: Context, brightness: Float) {
        prefs(context).edit().putFloat(KEY_BRIGHTNESS, brightness).apply()
    }

    fun getPlayingOverride(context: Context): Boolean =
        prefs(context).getBoolean(KEY_PLAYING_OVERRIDE, true)

    fun setPlayingOverride(context: Context, playing: Boolean) {
        prefs(context).edit().putBoolean(KEY_PLAYING_OVERRIDE, playing).apply()
    }
}
