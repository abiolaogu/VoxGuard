# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.

# Keep data classes for serialization
-keepclassmembers class com.billyrinks.antimasking.domain.model.** {
    *;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Apollo GraphQL
-keep class com.apollographql.apollo3.** { *; }
-keep class com.billyrinks.antimasking.graphql.** { *; }
-dontwarn com.apollographql.apollo3.**

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# Hilt
-keepnames @dagger.hilt.android.lifecycle.HiltViewModel class * extends androidx.lifecycle.ViewModel

# Orbit MVI
-keep class org.orbitmvi.orbit.** { *; }
-dontwarn org.orbitmvi.orbit.**

# Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

# Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# Keep Compose
-keep class androidx.compose.** { *; }
-dontwarn androidx.compose.**

# Keep Material3
-keep class androidx.compose.material3.** { *; }

# R8 full mode
-allowaccessmodification
-repackageclasses
