package com.aisee.aiseeapp

import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

class MainActivity : FlutterFragmentActivity() {
    private val platformChannel = "com.aisee.aiseeapp/platform"
    private val wakeWordChannel = "com.aisee.aiseeapp/livekit_wake_word"
    private val audioRouteChannel = "com.aisee.aiseeapp/audio_route"
    private var wakeWordEngine: LiveKitWakeWordEngine? = null
    private var audioManager: AudioManager? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        preferNearSixtyHzDisplayMode()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val wakeChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            wakeWordChannel,
        )
        wakeWordEngine = LiveKitWakeWordEngine(applicationContext, wakeChannel)
        wakeChannel.setMethodCallHandler { call, result ->
            try {
                val engine = requireNotNull(wakeWordEngine)
                when (call.method) {
                    "configure" -> {
                        val modelNames = call.argument<List<String>>("modelNames").orEmpty()
                        val threshold = call.argument<Double>("threshold")?.toFloat() ?: 0.5f
                        val debounceMs = call.argument<Int>("debounceMs")?.toLong() ?: 2_000L
                        engine.configure(modelNames, threshold, debounceMs)
                        result.success(null)
                    }

                    "startListening" -> {
                        engine.startListening()
                        result.success(null)
                    }

                    "stopListening" -> {
                        engine.stopListening()
                        result.success(null)
                    }

                    "dispose" -> {
                        engine.dispose()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("WAKE_WORD_ERROR", e.message, null)
            }
        }

        audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            audioRouteChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "forceSpeakerphone" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    val ok = audioManager?.setSpeakerphoneOn(enabled) ?: false
                    Log.i("MainActivity", "forceSpeakerphone enabled=$enabled ok=$ok")
                    result.success(ok)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            platformChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWakeWordRuntimeSupport" -> {
                    val supportedAbis = Build.SUPPORTED_ABIS?.toList().orEmpty()
                    val processAbi = supportedAbis.firstOrNull()
                    val reason =
                        if (processAbi != null) {
                            "LiveKit wake-word runtime available for process ABI $processAbi"
                        } else {
                            "Unable to determine process ABI; device reports " +
                                supportedAbis.joinToString().ifBlank { "unknown" }
                        }
                    result.success(
                        mapOf(
                            "isSupported" to (processAbi != null),
                            "reason" to reason,
                            "supportedAbis" to supportedAbis,
                            "requiredAbis" to supportedAbis,
                            "isEmulator" to isProbablyEmulator(),
                        ),
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        wakeWordEngine?.dispose()
        wakeWordEngine = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    /// Chọn [Display.Mode] có refresh gần 60 Hz (giảm nóng so với 90/120 Hz).
    private fun preferNearSixtyHzDisplayMode() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        try {
            val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
            @Suppress("DEPRECATION")
            val display = wm.defaultDisplay
            @Suppress("DEPRECATION")
            val modes = display.supportedModes ?: return
            if (modes.isEmpty()) return
            val inBand = modes.filter { it.refreshRate in 55f..66f }
            val candidates = if (inBand.isNotEmpty()) inBand else modes.toList()
            val best = candidates.minByOrNull { abs(it.refreshRate - 60f) } ?: return
            val lp = window.attributes
            lp.preferredDisplayModeId = best.modeId
            window.attributes = lp
        } catch (e: Exception) {
            Log.w("MainActivity", "preferNearSixtyHzDisplayMode", e)
        }
    }

    private fun isProbablyEmulator(): Boolean {
        return Build.FINGERPRINT.startsWith("generic") ||
            Build.FINGERPRINT.startsWith("unknown") ||
            Build.MODEL.contains("google_sdk") ||
            Build.MODEL.contains("Emulator") ||
            Build.MODEL.contains("Android SDK built for") ||
            Build.MANUFACTURER.contains("Genymotion") ||
            Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic") ||
            "google_sdk" == Build.PRODUCT
    }
}
