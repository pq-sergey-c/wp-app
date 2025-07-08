package com.wavepaths.player.foreground.utils.methodsDartMain

import com.wavepaths.player.foreground.types.enums.ForegroundServiceMethod
import kotlinx.serialization.json.Json

private val simplySerializable =
        setOf<ForegroundServiceMethod>(
                ForegroundServiceMethod.START,
                ForegroundServiceMethod.START_SESSION_EARLY,
                ForegroundServiceMethod.BROADCAST_USER_ADVANCE_FROM_PRELUDE,
                ForegroundServiceMethod.RESUME,
                ForegroundServiceMethod.PAUSE,
                ForegroundServiceMethod.DISPOSE,
        )

// some methods require additional data - for them null is return
fun serializeDartMethod(method: ForegroundServiceMethod): String? {
    if (!simplySerializable.contains(method)) return null
    return Json.encodeToString(mapOf("type" to method))
}
