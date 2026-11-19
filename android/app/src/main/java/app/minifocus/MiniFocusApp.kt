package app.minifocus

import android.app.Application

/** Application entry point; owns the shared [AppContainer]. */
class MiniFocusApp : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
    }
}
