package com.wavepaths.player.foreground

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import android.util.Log
import com.wavepaths.player.core.GlobalApplication
import com.wavepaths.player.foreground.service.ForegroundService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.StringCodec
import java.lang.ref.WeakReference
import kotlin.synchronized
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

private const val MainDartToKotlinForegroundChannel: String =
        "kotlin_foreground_to_dart_main_isolate"

private const val MainDartToForegroundControlsChannel: String =
        "kotlin_foreground_to_dart_main_control_channel"
private const val NoResponse: String = ""
private const val Error: String = "ERROR"
private const val TAG = "MainDartToForegroundKotlinChannel"

// Makes foreground process only when got message from MainDart and foreground process isn't yet
// made. Destruction of foreground process is initiated outside of scope of this class
// (via message or event). Yet destruction of foreground does affect state of this class
class MainDartToForegroundKotlinChannel(private val flutterEngine: FlutterEngine) {
    @Volatile private var channelScope: CoroutineScope? = null
    private val channelLock = Any()

    private fun getOrMakeChannelScope(): CoroutineScope {
        return channelScope
                ?: synchronized(channelLock) {
                    return channelScope
                            ?: CoroutineScope(Dispatchers.Main + SupervisorJob()).also {
                                channelScope = it
                            }
                }
    }

    // -------------------------------------------------------------
    // Foreground kotlin procedures

    @Volatile private var foregroundMessengerSend: Messenger? = null
    @Volatile private var isBindingToForegroundService: Boolean = false
    private val connectionLock = Any()

    private fun isConnectedToForegroundService(): Boolean {
        synchronized(connectionLock) {
            return foregroundMessengerSend != null
        }
    }

    private fun isForegroundExist(): Boolean {
        synchronized(connectionLock) {
            return foregroundMessengerSend != null || isBindingToForegroundService
        }
    }

    private val foregroundConnectDisposeActions =
            object : ServiceConnection {
                override fun onServiceConnected(_name: ComponentName, service: IBinder) {
                    synchronized(connectionLock) {
                        foregroundMessengerSend = Messenger(service)
                        isBindingToForegroundService = false
                    }
                }

                override fun onServiceDisconnected(_name: ComponentName) {
                    synchronized(connectionLock) { foregroundMessengerSend = null }
                }
            }

    // mainLooper is used cause Dart Main is in Main thread
    class ForegroundMessageHandlerClass(val channel: MainDartToForegroundKotlinChannel) :
            Handler(Looper.getMainLooper()) {
        val refChannel = WeakReference(channel)

        override fun handleMessage(msg: Message) {
            val channel: MainDartToForegroundKotlinChannel? = refChannel.get()

            if (channel == null) return // if garbage collected
            if (msg.obj !is String) return

            channel.sendToDartMain(msg.obj as String)
        }
    }
    val foregroundMessengerListen = Messenger(ForegroundMessageHandlerClass(this))

    // Returns: is successfully binding
    private fun bindToForegroundService(): Boolean {
        synchronized(connectionLock) {
            if (foregroundMessengerSend != null || isBindingToForegroundService) return true
            isBindingToForegroundService = true

            try {
                val foregroundService =
                        Intent(GlobalApplication.context, ForegroundService::class.java)
                GlobalApplication.context.startForegroundService(foregroundService)

                GlobalApplication.context.bindService(
                        foregroundService,
                        foregroundConnectDisposeActions,
                        Context.BIND_AUTO_CREATE
                )
                return true
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start foreground service")
                isBindingToForegroundService = false
                return false
            }
        }
    }

    private fun sendToForegroundService(message: String, messageSendRetryCount: Int = 0) {
        if (!isConnectedToForegroundService()) {
            if (messageSendRetryCount > 2 || !isBindingToForegroundService) {
                Log.e(TAG, "Failed to connect to service for message: $message")
                return
            }
            // Retry after delay
            getOrMakeChannelScope().launch {
                try {
                    delay(500)
                    sendToForegroundService(message, messageSendRetryCount + 1)
                } catch (e: Exception) {
                    Log.w(TAG, "Retry skipped due to scope cancel or failure")
                }
            }
            return
        }

        try {
            val msg = Message.obtain(null, 0, message)
            msg.replyTo = foregroundMessengerListen
            foregroundMessengerSend?.send(msg)
        } catch (e: Exception) {
            Log.e(TAG, "Error sending message to service: $message", e)
        }
    }

    // -------------------------------------------------------------
    // channel to main dart to resend to foreground

    private val channel =
            BasicMessageChannel<String>(
                            flutterEngine.dartExecutor.binaryMessenger,
                            MainDartToKotlinForegroundChannel,
                            StringCodec.INSTANCE
                    )
                    .apply { setMessageHandler(::dartMainMessageHandler) }

    private fun dartMainMessageHandler(message: String?, reply: BasicMessageChannel.Reply<String>) {
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

    private fun sendToDartMain(message: String) {
        try {
            channel.send(message)
        } catch (e: Exception) {
            Log.e(TAG, "Error sending message to Main isolate of Dart: $message", e)
        }
    }

    // -------------------------------------------------------------
    // control channel to main dart

    private val controlChannel =
            BasicMessageChannel<String>(
                            flutterEngine.dartExecutor.binaryMessenger,
                            MainDartToForegroundControlsChannel,
                            StringCodec.INSTANCE
                    )
                    .apply { setMessageHandler(::controlDartMessageHandler) }

    private fun controlDartMessageHandler(
            message: String?,
            reply: BasicMessageChannel.Reply<String>
    ) {
        when (message) {
            "startForeground" -> {
                Log.d(TAG, "controlChannel received: startForeground")
                // safe for repeated calls
                bindToForegroundService()
                reply.reply(NoResponse)
            }
            "doesForegroundExist" -> {
                reply.reply(if (isForegroundExist()) "true" else "false")
            }
            "disposeForeground" -> {
                Log.d(TAG, "controlChannel received: disposeForeground")
                cleanup()
                reply.reply(NoResponse)
            }
            null -> reply.reply(NoResponse)
            else -> reply.reply(NoResponse)
        }
    }

    // -------------------------------------------------------------

    fun cleanup() {
        // no need to send destruction signal to service, cause only one
        // binding should be with foreground service - so onDestroy will be called

        try {
            synchronized(channelLock) {
                channelScope?.cancel()
                channelScope = null
            }

            synchronized(connectionLock) {
                if (foregroundMessengerSend != null || isBindingToForegroundService) {
                    GlobalApplication.context.unbindService(foregroundConnectDisposeActions)
                }
                foregroundMessengerSend = null
                isBindingToForegroundService = false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error during cleanup", e)
        } finally {
            // ensure that set to correct values
            synchronized(channelLock) { channelScope = null }
            synchronized(connectionLock) {
                foregroundMessengerSend = null
                isBindingToForegroundService = false
            }
        }
    }
}
