package com.wavepaths.player.core

import android.app.Application

class GlobalApplication : Application() {
    companion object {
        lateinit var context: GlobalApplication
            private set
    }

    override fun onCreate() {
        super.onCreate()
        context = this
    }
}
