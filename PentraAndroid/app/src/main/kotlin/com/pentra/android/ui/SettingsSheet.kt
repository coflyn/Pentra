package com.pentra.android.ui

import android.graphics.SurfaceTexture
import android.os.Build
import android.view.TextureView
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.BlurEffect
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.AspectRatioFrameLayout
import com.pentra.android.ui.theme.*
import kotlin.math.roundToInt

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsSheet(
    state: PlaylistUiState,
    onDismiss: () -> Unit,
    onSpeedChange: (Float) -> Unit,
    onVolumeChange: (Float) -> Unit,
    onBlurChange: (Float) -> Unit,
    onBrightnessChange: (Float) -> Unit,
    onBatteryThresholdChange: (Int) -> Unit,
    onSetWallpaper: () -> Unit
) {
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = Surface,
        dragHandle = {
            Box(
                contentAlignment = Alignment.Center,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 10.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(width = 36.dp, height = 4.dp)
                        .background(color = Divider, shape = RoundedCornerShape(2.dp))
                )
            }
        }
    ) {
        Column(
            Modifier
                .fillMaxWidth()
                .navigationBarsPadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp)
                .padding(bottom = 32.dp)
        ) {

            // Live video preview — plays the active wallpaper with real-time effects
            if (state.activePath.isNotBlank()) {
                LiveWallpaperPreview(
                    path = state.activePath,
                    blurRadius = state.blurRadius,
                    brightness = state.brightness
                )
                Spacer(Modifier.height(20.dp))
            }

            Text(
                "Playback",
                style = MaterialTheme.typography.titleMedium,
                color = TextPrimary,
                modifier = Modifier.padding(bottom = 20.dp)
            )

            SettingSlider(
                label = "Speed",
                value = state.playbackSpeed,
                valueRange = 0.5f..2.0f,
                steps = 5,
                displayValue = "${state.playbackSpeed}x",
                onValueChange = onSpeedChange
            )

            SettingSlider(
                label = "Volume",
                value = state.volume,
                valueRange = 0f..1f,
                displayValue = "${(state.volume * 100).roundToInt()}%",
                onValueChange = onVolumeChange
            )

            HorizontalDivider(color = Divider, modifier = Modifier.padding(vertical = 16.dp))

            Text(
                "Visual",
                style = MaterialTheme.typography.titleMedium,
                color = TextPrimary,
                modifier = Modifier.padding(bottom = 20.dp)
            )

            SettingSlider(
                label = "Blur",
                value = state.blurRadius,
                valueRange = 0f..25f,
                displayValue = if (state.blurRadius < 0.5f) "Off" else "${state.blurRadius.roundToInt()}px",
                onValueChange = onBlurChange
            )

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S && state.blurRadius > 0.5f) {
                Text(
                    "Blur preview requires Android 12+. Effect still applies to wallpaper.",
                    style = MaterialTheme.typography.bodySmall,
                    color = TextSecondary,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
            }

            SettingSlider(
                label = "Brightness",
                value = state.brightness,
                valueRange = 0.1f..1.0f,
                displayValue = "${(state.brightness * 100).roundToInt()}%",
                onValueChange = onBrightnessChange
            )

            HorizontalDivider(color = Divider, modifier = Modifier.padding(vertical = 16.dp))

            Text(
                "Battery",
                style = MaterialTheme.typography.titleMedium,
                color = TextPrimary,
                modifier = Modifier.padding(bottom = 4.dp)
            )
            Text(
                "Pause playback when battery drops below this level",
                style = MaterialTheme.typography.bodySmall,
                color = TextSecondary,
                modifier = Modifier.padding(bottom = 16.dp)
            )

            SettingSlider(
                label = "Pause below",
                value = state.batteryThreshold.toFloat(),
                valueRange = 0f..80f,
                displayValue = if (state.batteryThreshold == 0) "Never" else "${state.batteryThreshold}%",
                onValueChange = { onBatteryThresholdChange(it.roundToInt()) }
            )

            HorizontalDivider(color = Divider, modifier = Modifier.padding(vertical = 16.dp))

            Button(
                onClick = onSetWallpaper,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Accent,
                    contentColor = OnAccent
                ),
                shape = RoundedCornerShape(10.dp)
            ) {
                Text("Set as Live Wallpaper", style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
}

@Composable
private fun LiveWallpaperPreview(
    path: String,
    blurRadius: Float,
    brightness: Float
) {
    val context = LocalContext.current

    val player = remember(path) {
        ExoPlayer.Builder(context).build().apply {
            setMediaItem(MediaItem.fromUri(path))
            repeatMode = Player.REPEAT_MODE_ONE
            volume = 0f
            prepare()
            play()
        }
    }

    DisposableEffect(path) {
        onDispose { player.release() }
    }

    val blurModifier = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && blurRadius > 0.5f) {
        Modifier.graphicsLayer {
            renderEffect = BlurEffect(blurRadius * 2f, blurRadius * 2f, TileMode.Decal)
        }
    } else Modifier

    val darknessAlpha = (1f - brightness).coerceIn(0f, 0.9f)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .height(260.dp)
                .aspectRatio(9f / 16f)
                .clip(RoundedCornerShape(16.dp))
                .background(SurfaceElevated)
        ) {
            // AspectRatioFrameLayout + TextureView preserves aspect ratio and prevents distortion (gepeng).
            // TextureView ensures no bottom-sheet scrim punch-through.
            AndroidView(
                factory = { ctx ->
                    AspectRatioFrameLayout(ctx).apply {
                        resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                        val tv = TextureView(ctx).apply {
                            layoutParams = FrameLayout.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                ViewGroup.LayoutParams.MATCH_PARENT
                            )
                        }
                        addView(tv)
                        player.setVideoTextureView(tv)
                        player.addListener(object : Player.Listener {
                            override fun onVideoSizeChanged(videoSize: VideoSize) {
                                if (videoSize.width > 0 && videoSize.height > 0) {
                                    setAspectRatio(videoSize.width.toFloat() / videoSize.height.toFloat())
                                }
                            }
                        })
                        if (player.videoSize.width > 0 && player.videoSize.height > 0) {
                            setAspectRatio(player.videoSize.width.toFloat() / player.videoSize.height.toFloat())
                        }
                    }
                },
                modifier = Modifier
                    .fillMaxSize()
                    .then(blurModifier)
            )

            if (darknessAlpha > 0.01f) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Background.copy(alpha = darknessAlpha))
                )
            }

            Surface(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(8.dp),
                color = Background.copy(alpha = 0.72f),
                shape = RoundedCornerShape(6.dp)
            ) {
                Text(
                    "Preview",
                    style = MaterialTheme.typography.labelMedium,
                    color = TextSecondary,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                )
            }
        }
    }
}

@Composable
private fun SettingSlider(
    label: String,
    value: Float,
    valueRange: ClosedFloatingPointRange<Float>,
    displayValue: String,
    steps: Int = 0,
    onValueChange: (Float) -> Unit
) {
    Column(Modifier.padding(bottom = 20.dp)) {
        Row(
            Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(label, style = MaterialTheme.typography.bodyMedium, color = TextPrimary)
            Text(displayValue, style = MaterialTheme.typography.bodySmall, color = Accent)
        }
        Spacer(Modifier.height(6.dp))
        Slider(
            value = value,
            onValueChange = onValueChange,
            valueRange = valueRange,
            steps = steps,
            colors = SliderDefaults.colors(
                thumbColor = Accent,
                activeTrackColor = Accent,
                inactiveTrackColor = Divider
            )
        )
    }
}
