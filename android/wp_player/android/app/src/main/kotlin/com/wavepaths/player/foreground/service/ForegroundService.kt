package com.wavepaths.player.foreground.service

import android.app.Service
import android.content.Intent
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Message
import android.os.Messenger
import android.util.Log
import com.wavepaths.player.foreground.ForegroundDartManager
import java.lang.ref.WeakReference
import java.util.concurrent.atomic.AtomicBoolean

private const val TAG = "ForegroundService"

private const val NoResponse: String = ""

// Coupled with ForegroundDartManager - both can initiate destruction of other
class ForegroundService : Service() {
    private val serviceThread = HandlerThread("ForegroundWavepathsThread").apply { start() }

    private val foregroundDartManagerLock = Any()
    private lateinit var foregroundDartManager: ForegroundDartManager
    private var refForegroundDartManager: WeakReference<ForegroundDartManager>? = null

    // -------------------------------------------------------------
    // Messaging with Main Kotlin

    private lateinit var messengerListener: Messenger
    @Volatile private var messengerToMainKotlinSend: Messenger? = null

    inner class MainKotlinMessageHandlerListenerClass : Handler(serviceThread.looper) {
        override fun handleMessage(msg: Message) {
            messengerToMainKotlinSend = msg.replyTo
            val message: String? = msg.obj as? String
            if (message == null || message == NoResponse) return

            try {
                notification.wiretapMainDart(message)
                sendToDartForeground(message)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send reply", e)
            }
        }
    }

    private fun sendToDartMain(message: String) {
        if (isStopped.get()) return

        if (messengerToMainKotlinSend == null) {
            Log.e(
                    TAG,
                    "messengerToMainKotlinSend is null - might failed to send message (possible race condition fix)"
            )
        }
        messengerToMainKotlinSend?.send(Message.obtain(null, 0, message))
    }

    // -------------------------------------------------------------
    // Messaging with Foreground Dart

    fun handleMessageFromForeground(message: String) {
        notification.wiretapForeground(message)
        sendToDartMain(message)
    }

    fun sendToDartForeground(message: String) {
        if (isStopped.get()) return
        refForegroundDartManager?.get()?.sendToDartForeground(message)
    }

    // -------------------------------------------------------------

    private val makeDestroyLock = Any() // already destroyed - edge cases
    private lateinit var notification: ForegroundNotificationManager
    private var isStarted = AtomicBoolean(false)

    override fun onBind(intent: Intent): IBinder = messengerListener.binder

    override fun onUnbind(intent: Intent): Boolean {
        synchronized(makeDestroyLock) {
            stopForegroundService()
            return false
        }
    }

    override fun onDestroy() {
        synchronized(makeDestroyLock) {
            synchronized(foregroundDartManagerLock) {
                if (::foregroundDartManager.isInitialized) foregroundDartManager.cleanup()
            }
            serviceThread.quitSafely()
            stopForeground(Service.STOP_FOREGROUND_REMOVE)

            super.onDestroy()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        synchronized(makeDestroyLock) {
            if (isStopped.get()) return STOP_FOREGROUND_REMOVE

            val acquired = isStarted.compareAndSet(false, true)
            if (!acquired) return START_STICKY

            messengerListener = Messenger(MainKotlinMessageHandlerListenerClass())
            notification = ForegroundNotificationManager(this).apply { run() }
            synchronized(foregroundDartManagerLock) {
                if (::foregroundDartManager.isInitialized) return STOP_FOREGROUND_REMOVE
                foregroundDartManager = ForegroundDartManager(this)
                refForegroundDartManager = WeakReference(foregroundDartManager)
            }
        }
        return START_STICKY
    }

    // -------------------------------------------------------------

    private var isStopped = AtomicBoolean(false)

    fun stopForegroundService() {
        val acquired = isStopped.compareAndSet(false, true)
        if (!acquired) return

        notification.stop()
        stopSelf()
    }
}
