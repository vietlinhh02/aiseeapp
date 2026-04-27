package com.aisee.aiseeapp

import android.content.Context
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
    private val supportedWakeWordAbis = setOf("arm64-v8a")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        preferNearSixtyHzDisplayMode()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            platformChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWakeWordRuntimeSupport" -> {
                    val supportedAbis = Build.SUPPORTED_ABIS?.toList().orEmpty()
                    val processAbi = supportedAbis.firstOrNull()
                    val isSupported = processAbi != null && supportedWakeWordAbis.contains(processAbi)
                    val reason =
                        if (isSupported) {
                            "Wake-word JNI available for process ABI $processAbi"
                        } else {
                            "Wake-word JNI is only bundled for ${supportedWakeWordAbis.joinToString()}, process ABI is ${processAbi ?: "unknown"}, device reports ${supportedAbis.joinToString().ifBlank { "unknown" }}"
                        }
                    result.success(
                        mapOf(
                            "isSupported" to isSupported,
                            "reason" to reason,
                            "supportedAbis" to supportedAbis,
                            "requiredAbis" to supportedWakeWordAbis.toList(),
                            "isEmulator" to isProbablyEmulator(),
                        ),
                    )
                }

                else -> result.notImplemented()
            }
        }
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
