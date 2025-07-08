package com.wavepaths.player.foreground.types.enums

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

private val isPausedStates =
        setOf<NetworkSessionState>(NetworkSessionState.ENDED, NetworkSessionState.PAUSE)

@Serializable
enum class NetworkSessionState {
    @SerialName("planned") PLANNED,
    @SerialName("prelude") PRELUDE,
    @SerialName("mainPhase") MAIN_PHASE,
    @SerialName("postlude") POSTLUDE,
    @SerialName("ended") ENDED,
    @SerialName("pause") PAUSE;

    val isPlayingState: Boolean
        get() {
            return !isPausedStates.contains(this)
        }
}
