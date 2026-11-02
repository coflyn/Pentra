package com.pentra.android

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.PorterDuff
import android.graphics.RectF
import android.net.Uri
import android.os.BatteryManager
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import androidx.core.content.ContextCompat
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer

class VideoWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = VideoEngine()

    inner class VideoEngine : Engine() {

        private var player: ExoPlayer? = null
        private var isVisible = false
        private var batteryLevel = 100
        private var playingOverride = true
        private var isCurrentMediaImage = false

        private val prefsListener = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
            when (key) {
                WallpaperPrefs.KEY_ACTIVE_PATH -> reloadMedia()
                WallpaperPrefs.KEY_PLAYBACK_SPEED -> applySpeed()
                WallpaperPrefs.KEY_VOLUME -> applyVolume()
                WallpaperPrefs.KEY_BATTERY_THRESHOLD -> updatePlayback()
                WallpaperPrefs.KEY_BRIGHTNESS -> {
                    if (isCurrentMediaImage) {
                        surfaceHolder?.let { holder ->
                            val path = WallpaperPrefs.getActivePath(this@VideoWallpaperService)
                            if (path.isNotBlank()) drawImage(holder, path)
                        }
                    }
                }
                WallpaperPrefs.KEY_PLAYING_OVERRIDE -> {
                    playingOverride = WallpaperPrefs.getPlayingOverride(this@VideoWallpaperService)
                    updatePlayback()
                }
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

        override fun onCreate(surfaceHolder: SurfaceHolder) {
            super.onCreate(surfaceHolder)
            playingOverride = WallpaperPrefs.getPlayingOverride(this@VideoWallpaperService)
            WallpaperPrefs.prefs(this@VideoWallpaperService)
                .registerOnSharedPreferenceChangeListener(prefsListener)
            try {
                ContextCompat.registerReceiver(
                    this@VideoWallpaperService,
                    batteryReceiver,
                    IntentFilter(Intent.ACTION_BATTERY_CHANGED),
                    ContextCompat.RECEIVER_NOT_EXPORTED
                )
            } catch (_: Exception) {
                registerReceiver(batteryReceiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            }
        }

        override fun onSurfaceCreated(holder: SurfaceHolder) {
            super.onSurfaceCreated(holder)
            initPlayer(holder)
        }

        override fun onSurfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
            super.onSurfaceChanged(holder, format, width, height)
            if (isCurrentMediaImage) {
                val path = WallpaperPrefs.getActivePath(this@VideoWallpaperService)
                if (path.isNotBlank()) drawImage(holder, path)
            }
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            releasePlayer()
            super.onSurfaceDestroyed(holder)
        }

        override fun onVisibilityChanged(visible: Boolean) {
            isVisible = visible
            updatePlayback()
        }

        override fun onDestroy() {
            WallpaperPrefs.prefs(this@VideoWallpaperService)
                .unregisterOnSharedPreferenceChangeListener(prefsListener)
            try { unregisterReceiver(batteryReceiver) } catch (_: Exception) {}
            releasePlayer()
            super.onDestroy()
        }

        private fun isImagePath(path: String): Boolean {
            val lower = path.lowercase()
            if (lower.endsWith(".jpg") || lower.endsWith(".jpeg") || lower.endsWith(".png") ||
                lower.endsWith(".webp") || lower.endsWith(".heic")
            ) {
                return true
            }
            return try {
                val type = contentResolver.getType(Uri.parse(path))
                type?.startsWith("image/") == true
            } catch (_: Exception) {
                false
            }
        }

        private fun initPlayer(holder: SurfaceHolder) {
            releasePlayer()
            val path = WallpaperPrefs.getActivePath(this@VideoWallpaperService)
            if (path.isBlank()) {
                drawFallback(holder)
                return
            }

            if (isImagePath(path)) {
                isCurrentMediaImage = true
                drawImage(holder, path)
                return
            }

            isCurrentMediaImage = false
            try {
                player = ExoPlayer.Builder(this@VideoWallpaperService).build().apply {
                    setVideoSurfaceHolder(holder)
                    videoScalingMode = C.VIDEO_SCALING_MODE_SCALE_TO_FIT_WITH_CROPPING
                    repeatMode = Player.REPEAT_MODE_ONE
                    volume = WallpaperPrefs.getVolume(this@VideoWallpaperService)
                    setPlaybackSpeed(WallpaperPrefs.getPlaybackSpeed(this@VideoWallpaperService))
                    setMediaItem(MediaItem.fromUri(path))
                    addListener(object : Player.Listener {
                        override fun onPlayerError(error: PlaybackException) {
                            drawFallback(holder)
                        }
                    })
                    prepare()
                    playWhenReady = shouldPlay()
                }
            } catch (_: Exception) {
                drawFallback(holder)
            }
        }

        private fun drawImage(holder: SurfaceHolder, path: String) {
            releasePlayer()
            try {
                val uri = Uri.parse(path)
                val boundsOptions = BitmapFactory.Options().apply {
                    inJustDecodeBounds = true
                }
                contentResolver.openInputStream(uri)?.use { stream ->
                    BitmapFactory.decodeStream(stream, null, boundsOptions)
                }

                val frame = holder.surfaceFrame
                val targetWidth = if (frame.width() > 0) frame.width() else 1080
                val targetHeight = if (frame.height() > 0) frame.height() else 1920

                var inSampleSize = 1
                if (boundsOptions.outHeight > targetHeight || boundsOptions.outWidth > targetWidth) {
                    val halfHeight = boundsOptions.outHeight / 2
                    val halfWidth = boundsOptions.outWidth / 2
                    while ((halfHeight / inSampleSize) >= targetHeight && (halfWidth / inSampleSize) >= targetWidth) {
                        inSampleSize *= 2
                    }
                }

                val decodeOptions = BitmapFactory.Options().apply {
                    this.inSampleSize = inSampleSize
                }
                val bitmap = contentResolver.openInputStream(uri)?.use { stream ->
                    BitmapFactory.decodeStream(stream, null, decodeOptions)
                } ?: return drawFallback(holder)

                val canvas: Canvas = holder.lockCanvas() ?: return
                try {
                    val viewWidth = canvas.width.toFloat()
                    val viewHeight = canvas.height.toFloat()
                    val scale = maxOf(viewWidth / bitmap.width, viewHeight / bitmap.height)
                    val scaledWidth = bitmap.width * scale
                    val scaledHeight = bitmap.height * scale
                    val left = (viewWidth - scaledWidth) / 2f
                    val top = (viewHeight - scaledHeight) / 2f

                    canvas.drawColor(0xFF0F0F0F.toInt(), PorterDuff.Mode.SRC)
                    val destRect = RectF(left, top, left + scaledWidth, top + scaledHeight)
                    canvas.drawBitmap(bitmap, null, destRect, null)

                    val brightness = WallpaperPrefs.getBrightness(this@VideoWallpaperService)
                    if (brightness < 1.0f) {
                        val alpha = ((1.0f - brightness) * 255).toInt().coerceIn(0, 255)
                        canvas.drawColor((alpha shl 24) or 0x000000)
                    }
                } finally {
                    holder.unlockCanvasAndPost(canvas)
                    bitmap.recycle()
                }
            } catch (_: Exception) {
                drawFallback(holder)
            }
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
            if (isCurrentMediaImage) return
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
