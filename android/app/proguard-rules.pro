# Flutter keeps its own rules, but we need to protect third-party networking
# libraries that Dio depends on from being stripped by R8 in release builds.

# ── OkHttp (used internally by Dart's http stack on Android) ─────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

# ── Conscrypt / SSL provider ──────────────────────────────────────────────────
# Prevents SSL handshake failures in release builds on older Android versions.
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ── Keep Dio / Dart VM service models ────────────────────────────────────────
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# ── Keep JSON-serialisable model classes (prevents reflection issues) ─────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# ── General safety net for reflection-based code ─────────────────────────────
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}
