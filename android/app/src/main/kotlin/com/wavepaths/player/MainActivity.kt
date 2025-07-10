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

    // FIXME: try to stop music player in other way - issue was reported on Samsung device
    // With usage of new audio backend seems to also be found on
    // Xiaomi 1.0.19.0.THGMIXM (Android 13 TKQ1.221114.001) - this device seems to have the bug
    // consistently in such setup but personally not sure
    // Reproducing:
    //   - On playing music close app from resent - music still playing
    // Debug and (fix attempts) info:
    //   - Even on initially reported Samsung device just detached std::thread is been closed
    //     (it stopped sending timed messages via udp to udp server)
    //   - Sending message from onDestroy to Dart to stop via ffi - failed
    //   - Checking/polling parent process id on detached thread - failed (thread was closed)
    //   - Usage on std::atexit - failed
    // Ideas to consider:
    //   - Specifically for android make wrapper in Kotlin as a service - and use on close of
    //     service to stop music
    //   - Maybe investigate miniaudio and AAUDIO in native code

    private fun unsafeWorkaroundOnDestroy() {
        Process.killProcess(Process.myPid())
    }
}
