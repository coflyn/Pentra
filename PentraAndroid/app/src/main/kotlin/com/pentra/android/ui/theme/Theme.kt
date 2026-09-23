package com.pentra.android.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val PentraDarkColorScheme = darkColorScheme(
    background = Background,
    surface = Surface,
    surfaceVariant = SurfaceElevated,
    primary = Accent,
    onPrimary = OnAccent,
    onBackground = TextPrimary,
    onSurface = TextPrimary,
    onSurfaceVariant = TextSecondary,
    error = Error,
    outline = Divider
)

@Composable
fun PentraTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = PentraDarkColorScheme,
        typography = PentraTypography,
        content = content
    )
}
