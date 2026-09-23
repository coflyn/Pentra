package com.pentra.android

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.graphics.Canvas
import android.graphics.PorterDuff
import android.os.BatteryManager
import android.os.Handler
import android.os.Looper
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer

class VideoWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = VideoEngine()

    inner class VideoEngine : Engine() {

        private var player: ExoPlayer? = null
        private val handler = Handler(Looper.getMainLooper())
        private var isVisible = false
        private var batteryLevel = 100
        private var playingOverride = true
        private var lastRotationTime: Long = System.currentTimeMillis()

        private val prefsListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            when (key) {
                WallpaperPrefs.KEY_ACTIVE_PATH -> reloadMedia()
                WallpaperPrefs.KEY_PLAYBACK_SPEED -> applySpeed()
                WallpaperPrefs.KEY_VOLUME -> applyVolume()
                WallpaperPrefs.KEY_BATTERY_THRESHOLD -> updatePlayback()
                WallpaperPrefs.KEY_PLAYING_OVERRIDE -> {
                    playingOverride = WallpaperPrefs.getPlayingOverride(this@VideoWallpaperService)
                    updatePlayback()
                }
                WallpaperPrefs.KEY_INTERVAL_MINUTES,
                WallpaperPrefs.KEY_PLAYLIST -> scheduleRotationIfNeeded()
            }
        }

        private val batteryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
                batteryLevel = if (scale > 0) (level * 100 / scale) else 100
                updatePlayback()
            }
        }

        private val rotationHandler = Runnable { scheduleNextWallpaper() }

        override fun onCreate(surfaceHolder: SurfaceHolder) {
            super.onCreate(surfaceHolder)
            WallpaperPrefs.prefs(this@VideoWallpaperService)
                .registerOnSharedPreferenceChangeListener(prefsListener)
            registerReceiver(batteryReceiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        }

        override fun onSurfaceCreated(holder: SurfaceHolder) {
            super.onSurfaceCreated(holder)
            initPlayer(holder)
        }

        override fun onSurfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
            super.onSurfaceChanged(holder, format, width, height)
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            releasePlayer()
            super.onSurfaceDestroyed(holder)
        }

        override fun onVisibilityChanged(visible: Boolean) {
            isVisible = visible
            updatePlayback()
            if (visible) {
                checkPendingRotation()
            }
        }

        override fun onDestroy() {
            handler.removeCallbacksAndMessages(null)
            WallpaperPrefs.prefs(this@VideoWallpaperService)
                .unregisterOnSharedPreferenceChangeListener(prefsListener)
            try { unregisterReceiver(batteryReceiver) } catch (_: Exception) {}
            releasePlayer()
            super.onDestroy()
        }

        private fun initPlayer(holder: SurfaceHolder) {
            releasePlayer()
            val path = WallpaperPrefs.getActivePath(this@VideoWallpaperService)
            if (path.isBlank()) {
                drawFallback(holder)
                return
            }

            player = ExoPlayer.Builder(this@VideoWallpaperService).build().apply {
                setVideoSurfaceHolder(holder)
                videoScalingMode = C.VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING
                repeatMode = Player.REPEAT_MODE_ONE
                volume = WallpaperPrefs.getVolume(this@VideoWallpaperService)
                setPlaybackSpeed(WallpaperPrefs.getPlaybackSpeed(this@VideoWallpaperService))
                setMediaItem(MediaItem.fromUri(path))
                prepare()
                playWhenReady = shouldPlay()
            }
            scheduleRotationIfNeeded()
        }

        private fun reloadMedia() {
            val holder = surfaceHolder ?: return
            initPlayer(holder)
        }

        private fun applySpeed() {
            player?.setPlaybackSpeed(WallpaperPrefs.getPlaybackSpeed(this@VideoWallpaperService))
        }

        private fun applyVolume() {
            player?.volume = WallpaperPrefs.getVolume(this@VideoWallpaperService)
        }

        private fun updatePlayback() {
            val play = shouldPlay()
            if (play) player?.play() else player?.pause()
        }

        private fun shouldPlay(): Boolean {
            if (!isVisible) return false
            if (!playingOverride) return false
            val threshold = WallpaperPrefs.getBatteryThreshold(this@VideoWallpaperService)
            if (batteryLevel < threshold) return false
            return true
        }

        private fun scheduleRotationIfNeeded(delayMs: Long? = null) {
            handler.removeCallbacks(rotationHandler)
            val minutes = WallpaperPrefs.getIntervalMinutes(this@VideoWallpaperService)
            val playlist = WallpaperPrefs.getPlaylist(this@VideoWallpaperService)
            if (minutes <= 0 || playlist.size < 2) return

            val targetDelay = delayMs ?: (minutes * 60_000L)
            handler.postDelayed(rotationHandler, maxOf(0L, targetDelay))
        }

        private fun checkPendingRotation() {
            val minutes = WallpaperPrefs.getIntervalMinutes(this@VideoWallpaperService)
            val playlist = WallpaperPrefs.getPlaylist(this@VideoWallpaperService)
            if (minutes <= 0 || playlist.size < 2) {
                handler.removeCallbacks(rotationHandler)
                return
            }

            val intervalMs = minutes * 60_000L
            val elapsed = System.currentTimeMillis() - lastRotationTime
            if (elapsed >= intervalMs) {
                scheduleNextWallpaper()
            } else {
                scheduleRotationIfNeeded(intervalMs - elapsed)
            }
        }

        private fun scheduleNextWallpaper() {
            val context = this@VideoWallpaperService
            val playlist = WallpaperPrefs.getPlaylist(context)
            if (playlist.size < 2) return

            val current = WallpaperPrefs.getActivePath(context)
            val currentIndex = playlist.indexOf(current)
            val isShuffle = WallpaperPrefs.getShuffle(context)

            val nextIndex = if (isShuffle) {
                var idx: Int
                do {
                    idx = playlist.indices.random()
                } while (idx == currentIndex && playlist.size > 1)
                idx
            } else {
                if (currentIndex >= 0) {
                    (currentIndex + 1) % playlist.size
                } else {
                    0
                }
            }

            lastRotationTime = System.currentTimeMillis()
            WallpaperPrefs.setActivePath(context, playlist[nextIndex])
            scheduleRotationIfNeeded()
        }

        private fun drawFallback(holder: SurfaceHolder) {
            val canvas: Canvas? = holder.lockCanvas()
            canvas?.drawColor(0xFF0F0F0F.toInt(), PorterDuff.Mode.SRC)
            canvas?.let { holder.unlockCanvasAndPost(it) }
        }

        private fun releasePlayer() {
            player?.release()
            player = null
        }
    }
}
