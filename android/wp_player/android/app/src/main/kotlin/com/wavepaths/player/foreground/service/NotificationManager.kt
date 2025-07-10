package com.wavepaths.player.foreground.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.media.app.NotificationCompat as MediaNotificationCompat
import com.wavepaths.player.foreground.types.callbacksDartForeground.NetworkTick
import com.wavepaths.player.foreground.types.enums.ForegroundServiceCallback
import com.wavepaths.player.foreground.types.enums.ForegroundServiceMethod
import com.wavepaths.player.foreground.types.methodsDartMain.DartMainInitMethod
import com.wavepaths.player.foreground.utils.callbacksDartForeground.parseSetPlaybackTimeForegroundCallback
import com.wavepaths.player.foreground.utils.callbacksDartForeground.parseSetSessionDurationForegroundCallback
import com.wavepaths.player.foreground.utils.generateAlbumCover.generateAlbumCover
import com.wavepaths.player.foreground.utils.methodsDartMain.serializeDartMethod
import com.wavepaths.player.foreground.utils.validateMessageAndGetType
import java.lang.ref.WeakReference
import kotlin.time.Duration
import kotlin.time.DurationUnit
import kotlin.time.toDuration
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

private const val CHANNEL_ID = "Wavepath_Player"
private const val CHANNEL_NAME = "Player notification" // readable by user
private const val NOTIFICATION_ID = 1 // don't set to 0

private const val TAG = "ForegroundNotificationManager"

private val isAndroid8OrMore = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O

private val _noTrackName = ""
private val _noArtistName = ""

class ForegroundNotificationManager(val foregroundService: ForegroundService) {
    private val refForegroundService = WeakReference(foregroundService)
    private val updateNotificationScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private val updateNotificationLock = Any() // TODO: change all Lock()s to Mutex()es

    fun run() {
        registerNotificationChannel()
        val notification = makeSimpleNotification()
        if (notification != null) {
            refForegroundService.get()?.startForeground(NOTIFICATION_ID, notification)
        }
    }

    fun stop() {
        refForegroundService.get()?.stopForeground(Service.STOP_FOREGROUND_REMOVE)
    }

    fun wiretapMainDart(message: String) {
        val typeString = validateMessageAndGetType(message) ?: return
        val type = ForegroundServiceMethod.fromString(typeString) ?: return

        if (type != ForegroundServiceMethod.INIT) return
        when (type) {
            ForegroundServiceMethod.INIT -> processInitMessage(message)
            else -> return
        }
    }

    fun wiretapForeground(message: String) {
        val typeString = validateMessageAndGetType(message) ?: return
        val type = ForegroundServiceCallback.fromString(typeString) ?: return

        when (type) {
            ForegroundServiceCallback.SET_SESSION_DURATION ->
                    processSetSessionDurationMessage(message)
            ForegroundServiceCallback.SET_PLAYBACK_TIME -> processSetPlaybackTimeMessage(message)
            ForegroundServiceCallback.PROCESS_NETWORK_TICK ->
                    processProcessNetworkTickMessage(message)
            else -> return
        }
    }

    // ---------------------------------------------------------------------
    // construction - helpers

    private var mediaSession: MediaSessionCompat? = null

    private fun registerNotificationChannel() {
        if (!isAndroid8OrMore) return
        val context = refForegroundService.get() ?: return

        val channel =
                NotificationChannel(CHANNEL_ID, CHANNEL_NAME, NotificationManager.IMPORTANCE_LOW)

        val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                        ?: return

        notificationManager.createNotificationChannel(channel)
    }

    private fun ensureMediaSessionIsMade() {
        if (mediaSession == null) {
            val context = refForegroundService.get() ?: return
            mediaSession =
                    MediaSessionCompat(context, "WPPlayerSession").apply {
                        isActive = true
                        setCallback(mediaSessionCallback, Handler(Looper.getMainLooper()))
                    }
            updatePlaybackState()
            updateMediaData()
        }
    }

    private val mediaSessionCallback =
            object : MediaSessionCompat.Callback() {
                override fun onPlay() = processResumeEvent()
                override fun onPause() = processPauseEvent()
            }

    // ---------------------------------------------------------------------
    // construction - control/update notification

    private var isPlaying: Boolean = true
    private var sessionDuration: Duration = 0.toDuration(DurationUnit.MILLISECONDS)
    private var playbackTimeDuration: Duration = 0.toDuration(DurationUnit.MILLISECONDS)
    private var trackName: String? = _noTrackName
    private var artistName: String = _noArtistName
    private var dartMainInitMethod: DartMainInitMethod? = null

    fun updatePlaybackState() {
        val possibleActions = PlaybackStateCompat.ACTION_PLAY or PlaybackStateCompat.ACTION_PAUSE
        val state =
                if (isPlaying) PlaybackStateCompat.STATE_PLAYING
                else PlaybackStateCompat.STATE_PAUSED

        val playbackState =
                PlaybackStateCompat.Builder()
                        .setActions(possibleActions)
                        .setState(state, playbackTimeDuration.inWholeMilliseconds, 1.0f)
                        .build()

        mediaSession?.setPlaybackState(playbackState)
    }

    fun updateMediaData() {
        val metadata =
                MediaMetadataCompat.Builder()
                        .apply {
                            if (trackName != null) {
                                putString(MediaMetadataCompat.METADATA_KEY_TITLE, trackName)
                            }
                            putString(MediaMetadataCompat.METADATA_KEY_ARTIST, artistName)
                            putLong(
                                    MediaMetadataCompat.METADATA_KEY_DURATION,
                                    sessionDuration.inWholeMilliseconds
                            )
                            putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, getAlbumCover())
                        }
                        .build()

        mediaSession?.setMetadata(metadata)
    }

    private fun redrawNotification() {
        updateNotificationScope.launch {
            synchronized(updateNotificationLock) {
                ensureMediaSessionIsMade()
                val notification = makeBasicNotification()
                if (notification == null) return@launch

                val notificationManager =
                        refForegroundService.get()?.getSystemService(Context.NOTIFICATION_SERVICE)
                (notificationManager as? NotificationManager)?.notify(NOTIFICATION_ID, notification)
            }
        }
    }

    // ---------------------------------------------------------------------
    // construction - notifications
    private var albumCover: Bitmap? = null

    private fun makeSimpleNotification(): Notification? {
        val context = refForegroundService.get() ?: return null

        return NotificationCompat.Builder(context, CHANNEL_ID)
                .apply {
                    setContentText("Service is starting...")
                    if (!isAndroid8OrMore) setPriority(NotificationCompat.PRIORITY_LOW)
                    setSmallIcon(android.R.drawable.ic_media_play)
                    setContentTitle("WP Player")
                    setOngoing(true)
                    setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
                }
                .build()
    }

    private fun makeBasicNotification(): Notification? {
        val context = refForegroundService.get() ?: return null

        val style =
                MediaNotificationCompat.MediaStyle().also {
                    it.setMediaSession(mediaSession?.sessionToken)
                }

        return NotificationCompat.Builder(context, CHANNEL_ID)
                .apply {
                    setSmallIcon(android.R.drawable.ic_media_play)
                    setLargeIcon(getAlbumCover())
                    setContentTitle("WP Player")
                    setSubText("is playing")
                    setOngoing(true)
                    setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_DEFERRED)
                    setStyle(style)
                }
                .build()
    }

    private fun getAlbumCover(): Bitmap {
        albumCover?.also {
            return it
        }

        val initMethod = dartMainInitMethod
        if (initMethod == null) return generateAlbumCover(null, seed = "seed")

        return generateAlbumCover(
                        Pair(initMethod.atmosphereColors, initMethod.emotionalIntensity),
                        seed = initMethod.sessionId
                )
                .also { albumCover = it }
    }

    // ---------------------------------------------------------------------
    // listen

    private fun processInitMessage(message: String) {
        val initMessage = DartMainInitMethod.fromJson(message)
        if (initMessage == null) {
            Log.e(TAG, "Failed to parse init message: $message")
            return
        }

        dartMainInitMethod = initMessage
        artistName = initMessage.artist
        trackName = initMessage.sessionName
        updateMediaData()
        redrawNotification() // somewhy trackName doesn't work otherwise
    }

    private fun processSetSessionDurationMessage(message: String) {
        sessionDuration = parseSetSessionDurationForegroundCallback(message) ?: return
        updateMediaData()
    }

    private fun processSetPlaybackTimeMessage(message: String) {
        playbackTimeDuration = parseSetPlaybackTimeForegroundCallback(message) ?: return
        updatePlaybackState()
    }

    private fun processProcessNetworkTickMessage(message: String) {
        val networkTick = NetworkTick.fromJson(message) ?: return
        val isPlayingState = networkTick.sessionState.isPlayingState

        if (isPlaying == isPlayingState) return

        isPlaying = isPlayingState
        updatePlaybackState()
    }

    // ---------------------------------------------------------------------
    // actions

    private fun processPauseEvent() {
        val message = serializeDartMethod(ForegroundServiceMethod.PAUSE)
        if (message == null) {
            Log.e(TAG, "Failed to send pause event")
            return
        }
        refForegroundService.get()?.sendToDartForeground(message)
    }

    private fun processResumeEvent() {
        val message = serializeDartMethod(ForegroundServiceMethod.RESUME)
        if (message == null) {
            Log.e(TAG, "Failed to send resume event")
            return
        }
        refForegroundService.get()?.sendToDartForeground(message)
    }
}
