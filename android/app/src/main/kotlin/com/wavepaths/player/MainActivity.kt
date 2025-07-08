package com.wavepaths.player

import android.os.Process
import com.wavepaths.player.foreground.MainDartToForegroundKotlinChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var foregroundToMainDartChannel: MainDartToForegroundKotlinChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        foregroundToMainDartChannel = MainDartToForegroundKotlinChannel(flutterEngine)
    }

    override fun onDestroy() {
        foregroundToMainDartChannel.cleanup()

        super.onDestroy()
        unsafeWorkaroundOnDestroy()
    }

    // -------------------------------------------------------------

    private fun unsafeWorkaroundOnDestroy() {
        // FIXME: try to stop music player in other way - issue was reported on Samsung device
        // Reason:
        //   to stop the native thread (by stopping entire process)
        //   when Flutter activity is destroyed
        //   This line is a problematic and should be replaced
        Process.killProcess(Process.myPid())
    }
}
