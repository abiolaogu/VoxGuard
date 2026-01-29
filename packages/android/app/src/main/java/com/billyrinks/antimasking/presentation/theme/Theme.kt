package com.billyrinks.antimasking.presentation.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

// Nigerian-inspired color palette
private val NigeriaGreen = Color(0xFF008751)
private val NairaGreen = Color(0xFF008751)

// Light theme colors
private val LightPrimary = Color(0xFF1890FF)
private val LightOnPrimary = Color.White
private val LightPrimaryContainer = Color(0xFFE6F7FF)
private val LightOnPrimaryContainer = Color(0xFF001F33)

private val LightSecondary = Color(0xFF722ED1)
private val LightOnSecondary = Color.White
private val LightSecondaryContainer = Color(0xFFF9F0FF)
private val LightOnSecondaryContainer = Color(0xFF1F0041)

private val LightTertiary = NigeriaGreen
private val LightOnTertiary = Color.White
private val LightTertiaryContainer = Color(0xFFE6F5EF)
private val LightOnTertiaryContainer = Color(0xFF00261A)

private val LightError = Color(0xFFFF4D4F)
private val LightOnError = Color.White
private val LightErrorContainer = Color(0xFFFFF2F0)
private val LightOnErrorContainer = Color(0xFF410002)

private val LightBackground = Color(0xFFF9FAFB)
private val LightOnBackground = Color(0xFF1F2937)
private val LightSurface = Color.White
private val LightOnSurface = Color(0xFF1F2937)
private val LightSurfaceVariant = Color(0xFFF3F4F6)
private val LightOnSurfaceVariant = Color(0xFF6B7280)
private val LightOutline = Color(0xFFE5E7EB)

// Dark theme colors
private val DarkPrimary = Color(0xFF40A9FF)
private val DarkOnPrimary = Color(0xFF00344D)
private val DarkPrimaryContainer = Color(0xFF004D73)
private val DarkOnPrimaryContainer = Color(0xFFE6F7FF)

private val DarkSecondary = Color(0xFF9254DE)
private val DarkOnSecondary = Color(0xFF2D0066)
private val DarkSecondaryContainer = Color(0xFF531DAB)
private val DarkOnSecondaryContainer = Color(0xFFF9F0FF)

private val DarkTertiary = Color(0xFF52C41A)
private val DarkOnTertiary = Color(0xFF003300)
private val DarkTertiaryContainer = Color(0xFF008751)
private val DarkOnTertiaryContainer = Color(0xFFE6F5EF)

private val DarkError = Color(0xFFFF7875)
private val DarkOnError = Color(0xFF690005)
private val DarkErrorContainer = Color(0xFF93000A)
private val DarkOnErrorContainer = Color(0xFFFFF2F0)

private val DarkBackground = Color(0xFF111827)
private val DarkOnBackground = Color(0xFFF9FAFB)
private val DarkSurface = Color(0xFF1F2937)
private val DarkOnSurface = Color(0xFFF9FAFB)
private val DarkSurfaceVariant = Color(0xFF374151)
private val DarkOnSurfaceVariant = Color(0xFFD1D5DB)
private val DarkOutline = Color(0xFF374151)

private val LightColorScheme = lightColorScheme(
    primary = LightPrimary,
    onPrimary = LightOnPrimary,
    primaryContainer = LightPrimaryContainer,
    onPrimaryContainer = LightOnPrimaryContainer,
    secondary = LightSecondary,
    onSecondary = LightOnSecondary,
    secondaryContainer = LightSecondaryContainer,
    onSecondaryContainer = LightOnSecondaryContainer,
    tertiary = LightTertiary,
    onTertiary = LightOnTertiary,
    tertiaryContainer = LightTertiaryContainer,
    onTertiaryContainer = LightOnTertiaryContainer,
    error = LightError,
    onError = LightOnError,
    errorContainer = LightErrorContainer,
    onErrorContainer = LightOnErrorContainer,
    background = LightBackground,
    onBackground = LightOnBackground,
    surface = LightSurface,
    onSurface = LightOnSurface,
    surfaceVariant = LightSurfaceVariant,
    onSurfaceVariant = LightOnSurfaceVariant,
    outline = LightOutline
)

private val DarkColorScheme = darkColorScheme(
    primary = DarkPrimary,
    onPrimary = DarkOnPrimary,
    primaryContainer = DarkPrimaryContainer,
    onPrimaryContainer = DarkOnPrimaryContainer,
    secondary = DarkSecondary,
    onSecondary = DarkOnSecondary,
    secondaryContainer = DarkSecondaryContainer,
    onSecondaryContainer = DarkOnSecondaryContainer,
    tertiary = DarkTertiary,
    onTertiary = DarkOnTertiary,
    tertiaryContainer = DarkTertiaryContainer,
    onTertiaryContainer = DarkOnTertiaryContainer,
    error = DarkError,
    onError = DarkOnError,
    errorContainer = DarkErrorContainer,
    onErrorContainer = DarkOnErrorContainer,
    background = DarkBackground,
    onBackground = DarkOnBackground,
    surface = DarkSurface,
    onSurface = DarkOnSurface,
    surfaceVariant = DarkSurfaceVariant,
    onSurfaceVariant = DarkOnSurfaceVariant,
    outline = DarkOutline
)

@Composable
fun AntiMaskingTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context)
            else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.surface.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}

// Typography
val Typography = Typography()
