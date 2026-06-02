# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ONNX Runtime
-keep class ai.onnxruntime.** { *; }

# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# LiveKit / WebRTC
-keep class livekit.** { *; }
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Record plugin
-keep class com.llfbandit.record.** { *; }

# Camera plugin
-keep class io.flutter.plugins.camera.** { *; }

# PCM Sound
-keep class com.ymd.flutter_pcm_sound.** { *; }

# Audio plugins
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.ryanheise.audio_session.** { *; }

# TTS
-keep class com.tundralabs.fluttertts.** { *; }

# Foreground task
-keep class com.pravera.flutter_foreground_task.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# RevenueCat
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Connectivity
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# WebView
-keep class io.flutter.plugins.webviewflutter.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Keep all Flutter plugin registration
-keep class ** extends io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class ** extends io.flutter.plugin.common.MethodChannel.MethodCallHandler { *; }
-keep class ** extends io.flutter.plugin.common.EventChannel.StreamHandler { *; }

# Keep Rust bridge
-keep class frb_generated.** { *; }

-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# General rules
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Remove debug logging in release
-assumenosideeffects class android.util.Log {
    public static *** v(...);
    public static *** d(...);
}
