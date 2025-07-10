package com.wavepaths.player.foreground

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.wavepaths.player.core.GlobalApplication
import com.wavepaths.player.foreground.service.ForegroundService
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.StringCodec
import java.lang.ref.WeakReference
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

private const val ForegroundToForegroundChannel: String = "kotlin_foreground_to_dart_foreground"

private const val NoResponse: String = ""
private const val Error: String = "ERROR"
private const val TAG = "ForegroundDartManager"

private const val ForegroundDartEntryPoint: String = "kotlinForegroundEntryPointMain"

// Coupled with ForegroundService - both can initiate destruction of other
class ForegroundDartManager(private val foregroundService: ForegroundService) {
    private val flutterEngine = FlutterEngine(GlobalApplication.context)
    private val refForegroundService = WeakReference(foregroundService)
    private val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var isCleanedUp: Boolean = false

    private val initCleanLock = Any()

    init {
        constructor()
    }

    private fun constructor() {
        try {
            synchronized(initCleanLock) {
                if (isCleanedUp) return
                initChannelToForeground()
            }

            val flutterLoader: FlutterLoader = FlutterInjector.instance().flutterLoader()
            if (!flutterLoader.initialized())
                    flutterLoader.startInitialization(GlobalApplication.context)

            flutterLoader.ensureInitializationCompleteAsync(
                    GlobalApplication.context,
                    null,
                    Handler(Looper.getMainLooper()),
                    {
                        synchronized(initCleanLock) {
                            if (!isCleanedUp) {
                                val entryPoint =
                                        DartExecutor.DartEntrypoint(
                                                flutterLoader.findAppBundlePath(),
                                                ForegroundDartEntryPoint
                                        )
                                flutterEngine.dartExecutor.executeDartEntrypoint(entryPoint)
                            }
                        }
                    }
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start foreground Dart", e)
            cleanup()
        }
    }

    fun cleanup() {
        synchronized(initCleanLock) {
            if (isCleanedUp) return
            isCleanedUp = true

            mainScope.cancel()

            flutterEngine.destroy()
            refForegroundService.get()?.stopForegroundService()
        }
    }

    // -------------------------------------------------------------
    // Channel to foreground dart

    private lateinit var channelToForeground: BasicMessageChannel<String>

    private fun initChannelToForeground() {
        channelToForeground =
                BasicMessageChannel<String>(
                                flutterEngine.dartExecutor.binaryMessenger,
                                ForegroundToForegroundChannel,
                                StringCodec.INSTANCE
                        )
                        .apply { setMessageHandler(::dartForegroundMessageHandler) }
    }

    private fun dartForegroundMessageHandler(
            message: String?,
            reply: BasicMessageChannel.Reply<String>
    ) {
        if (message == null) {
            reply.reply(NoResponse)
            return
        }

        try {
            sendToForegroundService(message)
            reply.reply(NoResponse)
        } catch (e: Exception) {
            Log.e(TAG, "Error handling message: $message", e)
            reply.reply(Error)
        }
    }

    fun sendToDartForeground(message: String) {
        mainScope.launch {
            if (isCleanedUp) return@launch

            try {
                channelToForeground.send(message)
            } catch (e: Exception) {
                Log.e(TAG, "Error sending message to Main isolate of Dart: $message", e)
            }
        }
    }

    // -------------------------------------------------------------
    // Channel to foreground kotlin

    private fun sendToForegroundService(message: String) {
        if (isCleanedUp) return

        refForegroundService.get()?.handleMessageFromForeground(message)
    }
}
