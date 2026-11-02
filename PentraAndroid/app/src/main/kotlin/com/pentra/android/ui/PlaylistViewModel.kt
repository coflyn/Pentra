package com.pentra.android.ui

import android.app.Application
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.pentra.android.WallpaperPrefs
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class PlaylistUiState(
    val playlist: List<String> = emptyList(),
    val activePath: String = "",
    val playbackSpeed: Float = 1.0f,
    val volume: Float = 0.0f,
    val blurRadius: Float = 0.0f,
    val brightness: Float = 1.0f,
    val batteryThreshold: Int = 20,
    val isLoading: Boolean = true,
    val error: String? = null
)

class PlaylistViewModel(app: Application) : AndroidViewModel(app) {

    private val ctx: Context get() = getApplication()

    private val _state = MutableStateFlow(PlaylistUiState())
    val state: StateFlow<PlaylistUiState> = _state.asStateFlow()

    private val prefsListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
        when (key) {
            WallpaperPrefs.KEY_ACTIVE_PATH -> {
                val path = WallpaperPrefs.getActivePath(ctx)
                _state.update { it.copy(activePath = path) }
            }
            WallpaperPrefs.KEY_PLAYLIST -> {
                val list = WallpaperPrefs.getPlaylist(ctx)
                _state.update { it.copy(playlist = list) }
            }
            WallpaperPrefs.KEY_PLAYBACK_SPEED -> {
                _state.update { it.copy(playbackSpeed = WallpaperPrefs.getPlaybackSpeed(ctx)) }
            }
            WallpaperPrefs.KEY_VOLUME -> {
                _state.update { it.copy(volume = WallpaperPrefs.getVolume(ctx)) }
            }
            WallpaperPrefs.KEY_BLUR_RADIUS -> {
                _state.update { it.copy(blurRadius = WallpaperPrefs.getBlurRadius(ctx)) }
            }
            WallpaperPrefs.KEY_BRIGHTNESS -> {
                _state.update { it.copy(brightness = WallpaperPrefs.getBrightness(ctx)) }
            }
            WallpaperPrefs.KEY_BATTERY_THRESHOLD -> {
                _state.update { it.copy(batteryThreshold = WallpaperPrefs.getBatteryThreshold(ctx)) }
            }
        }
    }

    init {
        WallpaperPrefs.prefs(ctx).registerOnSharedPreferenceChangeListener(prefsListener)
        load()
    }

    override fun onCleared() {
        WallpaperPrefs.prefs(ctx).unregisterOnSharedPreferenceChangeListener(prefsListener)
        super.onCleared()
    }

    fun load() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            try {
                _state.update {
                    PlaylistUiState(
                        playlist = WallpaperPrefs.getPlaylist(ctx),
                        activePath = WallpaperPrefs.getActivePath(ctx),
                        playbackSpeed = WallpaperPrefs.getPlaybackSpeed(ctx),
                        volume = WallpaperPrefs.getVolume(ctx),
                        blurRadius = WallpaperPrefs.getBlurRadius(ctx),
                        brightness = WallpaperPrefs.getBrightness(ctx),
                        batteryThreshold = WallpaperPrefs.getBatteryThreshold(ctx),
                        isLoading = false
                    )
                }
            } catch (e: Exception) {
                _state.update { it.copy(isLoading = false, error = "Failed to load playlist") }
            }
        }
    }

    fun addItems(uris: List<Uri>) {
        // Persist URI grants so WallpaperService (different lifecycle) can read them later.
        // Without this, content:// grants expire and ExoPlayer renders black.
        uris.forEach { uri ->
            try {
                ctx.contentResolver.takePersistableUriPermission(
                    uri, Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            } catch (_: Exception) {
                // file:// or non-persistable URIs — no action needed
            }
        }
        val paths = uris.map { it.toString() }
        val updated = (_state.value.playlist + paths).distinct()
        WallpaperPrefs.setPlaylist(ctx, updated)
        if (_state.value.activePath.isBlank() && updated.isNotEmpty()) {
            setActive(updated.first())
        }
        _state.update { it.copy(playlist = updated) }
    }

    fun removeItem(path: String) {
        val updated = _state.value.playlist.filter { it != path }
        WallpaperPrefs.setPlaylist(ctx, updated)
        if (_state.value.activePath == path) {
            val next = updated.firstOrNull() ?: ""
            WallpaperPrefs.setActivePath(ctx, next)
        }
        _state.update { it.copy(playlist = updated) }
    }

    fun setActive(path: String) {
        WallpaperPrefs.setActivePath(ctx, path)
        _state.update { it.copy(activePath = path) }
    }

    fun setPlaybackSpeed(speed: Float) {
        WallpaperPrefs.setPlaybackSpeed(ctx, speed)
        _state.update { it.copy(playbackSpeed = speed) }
    }

    fun setVolume(volume: Float) {
        WallpaperPrefs.setVolume(ctx, volume)
        _state.update { it.copy(volume = volume) }
    }

    fun setBlurRadius(radius: Float) {
        WallpaperPrefs.setBlurRadius(ctx, radius)
        _state.update { it.copy(blurRadius = radius) }
    }

    fun setBrightness(brightness: Float) {
        WallpaperPrefs.setBrightness(ctx, brightness)
        _state.update { it.copy(brightness = brightness) }
    }

    fun setBatteryThreshold(percent: Int) {
        WallpaperPrefs.setBatteryThreshold(ctx, percent)
        _state.update { it.copy(batteryThreshold = percent) }
    }
}
