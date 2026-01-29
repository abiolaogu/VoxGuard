package com.billyrinks.antimasking

import android.app.Application
import coil.ImageLoader
import coil.ImageLoaderFactory
import coil.disk.DiskCache
import coil.memory.MemoryCache
import dagger.hilt.android.HiltAndroidApp

/**
 * Anti-Call Masking Platform Android Application
 * 
 * This is the main application class that initializes:
 * - Hilt dependency injection
 * - Coil image loading with caching
 */
@HiltAndroidApp
class AntiMaskingApp : Application(), ImageLoaderFactory {

    override fun onCreate() {
        super.onCreate()
        // Application-wide initialization
    }

    override fun newImageLoader(): ImageLoader {
        return ImageLoader.Builder(this)
            .memoryCache {
                MemoryCache.Builder(this)
                    .maxSizePercent(0.25)
                    .build()
            }
            .diskCache {
                DiskCache.Builder()
                    .directory(cacheDir.resolve("image_cache"))
                    .maxSizePercent(0.02)
                    .build()
            }
            .respectCacheHeaders(false)
            .crossfade(true)
            .build()
    }
}
