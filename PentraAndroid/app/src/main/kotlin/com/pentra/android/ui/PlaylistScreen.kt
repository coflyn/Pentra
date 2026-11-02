package com.pentra.android.ui

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Intent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import coil.request.ImageRequest
import coil.decode.VideoFrameDecoder
import com.pentra.android.VideoWallpaperService
import com.pentra.android.ui.theme.*

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun PlaylistScreen(vm: PlaylistViewModel = viewModel()) {
    val state by vm.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    var showSettings by remember { mutableStateOf(false) }
    var itemToDelete by remember { mutableStateOf<String?>(null) }

    val filePicker = rememberLauncherForActivityResult(
        ActivityResultContracts.OpenMultipleDocuments()
    ) { uris -> if (uris.isNotEmpty()) vm.addItems(uris) }

    Scaffold(
        containerColor = Background,
        floatingActionButton = {
            FloatingActionButton(
                onClick = { filePicker.launch(arrayOf("video/*", "image/*")) },
                containerColor = Accent,
                contentColor = OnAccent,
                shape = RoundedCornerShape(16.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add wallpaper")
            }
        },
        topBar = {
            PentraTopBar(
                onSettingsClick = { showSettings = true }
            )
        }
    ) { padding ->
        Box(
            Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when {
                state.isLoading -> LoadingState()
                state.error != null -> ErrorState(state.error!!, onRetry = { vm.load() })
                state.playlist.isEmpty() -> EmptyState(
                    onAdd = { filePicker.launch(arrayOf("video/*", "image/*")) }
                )
                else -> {
                    LazyVerticalGrid(
                        columns = GridCells.Fixed(2),
                        contentPadding = PaddingValues(12.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.fillMaxSize()
                    ) {
                        items(state.playlist, key = { it }) { path ->
                            WallpaperTile(
                                path = path,
                                isActive = path == state.activePath,
                                onClick = { vm.setActive(path) },
                                onLongClick = { itemToDelete = path }
                            )
                        }
                        // Bottom padding so FAB doesn't overlap last row
                        item { Spacer(Modifier.height(72.dp)) }
                        item { Spacer(Modifier.height(72.dp)) }
                    }
                }
            }
        }
    }

    // Delete confirmation
    itemToDelete?.let { path ->
        AlertDialog(
            onDismissRequest = { itemToDelete = null },
            containerColor = SurfaceElevated,
            title = {
                Text("Remove wallpaper?", color = TextPrimary, style = MaterialTheme.typography.titleMedium)
            },
            text = {
                val name = path.substringAfterLast("/")
                Text(name, color = TextSecondary, style = MaterialTheme.typography.bodySmall, maxLines = 2, overflow = TextOverflow.Ellipsis)
            },
            confirmButton = {
                TextButton(onClick = { vm.removeItem(path); itemToDelete = null }) {
                    Text("Remove", color = Error)
                }
            },
            dismissButton = {
                TextButton(onClick = { itemToDelete = null }) {
                    Text("Cancel", color = TextSecondary)
                }
            }
        )
    }

    // Settings bottom sheet
    if (showSettings) {
        SettingsSheet(
            state = state,
            onDismiss = { showSettings = false },
            onSpeedChange = { vm.setPlaybackSpeed(it) },
            onVolumeChange = { vm.setVolume(it) },
            onBlurChange = { vm.setBlurRadius(it) },
            onBrightnessChange = { vm.setBrightness(it) },
            onBatteryThresholdChange = { vm.setBatteryThreshold(it) },
            onSetWallpaper = {
                val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
                    putExtra(
                        WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                        ComponentName(context, VideoWallpaperService::class.java)
                    )
                }
                context.startActivity(intent)
            }
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun WallpaperTile(
    path: String,
    isActive: Boolean,
    onClick: () -> Unit,
    onLongClick: () -> Unit
) {
    val borderColor by animateColorAsState(
        if (isActive) Accent else Color.Transparent,
        animationSpec = tween(200),
        label = "tile_border"
    )

    Box(
        modifier = Modifier
            .aspectRatio(9f / 16f)
            .clip(RoundedCornerShape(10.dp))
            .combinedClickable(onClick = onClick, onLongClick = onLongClick)
    ) {
        AsyncImage(
            model = ImageRequest.Builder(LocalContext.current)
                .data(path)
                .decoderFactory(VideoFrameDecoder.Factory())
                .crossfade(true)
                .build(),
            contentDescription = null,
            contentScale = ContentScale.Crop,
            modifier = Modifier.fillMaxSize()
        )

        // Dark gradient for readability at the bottom of tile
        Box(
            Modifier
                .fillMaxWidth()
                .fillMaxHeight(0.35f)
                .align(Alignment.BottomCenter)
                .background(
                    androidx.compose.ui.graphics.Brush.verticalGradient(
                        listOf(Color.Transparent, Color(0xCC0F0F0F))
                    )
                )
        )

        // Amber border — the identity motif for active state
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = Color.Transparent,
            shape = RoundedCornerShape(10.dp),
            border = BorderStroke(2.dp, borderColor)
        ) {}

        // Active checkmark badge
        if (isActive) {
            Surface(
                modifier = Modifier
                    .size(22.dp)
                    .align(Alignment.TopEnd)
                    .offset((-6).dp, 6.dp),
                shape = RoundedCornerShape(6.dp),
                color = Accent
            ) {
                Icon(
                    Icons.Default.Check,
                    contentDescription = "Active",
                    tint = OnAccent,
                    modifier = Modifier.padding(4.dp)
                )
            }
        }

        // File name at bottom
        Text(
            text = path.substringAfterLast("/"),
            style = MaterialTheme.typography.labelMedium,
            color = TextPrimary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(horizontal = 8.dp, vertical = 6.dp)
        )
    }
}

@Composable
private fun PentraTopBar(
    onSettingsClick: () -> Unit
) {
    Surface(color = Background, shadowElevation = 0.dp) {
        Row(
            Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                "Pentra",
                style = MaterialTheme.typography.titleLarge,
                color = TextPrimary,
                modifier = Modifier.weight(1f)
            )

            IconButton(onClick = onSettingsClick) {
                Icon(Icons.Default.Settings, contentDescription = "Settings", tint = TextSecondary)
            }
        }
    }
}

@Composable
private fun EmptyState(onAdd: () -> Unit) {
    Column(
        Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("No wallpapers yet", style = MaterialTheme.typography.titleMedium, color = TextPrimary)
        Spacer(Modifier.height(6.dp))
        Text(
            "Tap + to add a video or image from your device",
            style = MaterialTheme.typography.bodySmall,
            color = TextSecondary
        )
        Spacer(Modifier.height(24.dp))
        OutlinedButton(
            onClick = onAdd,
            border = BorderStroke(1.dp, Accent),
            colors = ButtonDefaults.outlinedButtonColors(contentColor = Accent)
        ) {
            Text("Add wallpaper")
        }
    }
}

@Composable
private fun LoadingState() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        CircularProgressIndicator(color = Accent, strokeWidth = 2.dp)
    }
}

@Composable
private fun ErrorState(message: String, onRetry: () -> Unit) {
    Column(
        Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text("Something went wrong", style = MaterialTheme.typography.titleMedium, color = TextPrimary)
        Spacer(Modifier.height(4.dp))
        Text(message, style = MaterialTheme.typography.bodySmall, color = TextSecondary)
        Spacer(Modifier.height(20.dp))
        OutlinedButton(
            onClick = onRetry,
            border = BorderStroke(1.dp, Error),
            colors = ButtonDefaults.outlinedButtonColors(contentColor = Error)
        ) {
            Text("Retry")
        }
    }
}
