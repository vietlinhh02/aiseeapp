package com.aisee.aiseeapp

import android.content.Context
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import kotlin.math.abs

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        preferNearSixtyHzDisplayMode()
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
}
