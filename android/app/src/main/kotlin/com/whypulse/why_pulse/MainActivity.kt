package com.whypulse.why_pulse

import com.whypulse.why_pulse.platform.PlatformSecurityApi
import com.whypulse.why_pulse.platform.PlatformSecurityApiImpl
import com.whypulse.why_pulse.sources.SourceApi
import com.whypulse.why_pulse.sources.SourceApiImpl
import com.whypulse.why_pulse.notifications.NotificationApi
import com.whypulse.why_pulse.notifications.NotificationApiImpl
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterFragmentActivity() {
    private var sourceApi: SourceApiImpl? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PlatformSecurityApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            PlatformSecurityApiImpl(applicationContext),
        )
        sourceApi = SourceApiImpl(this).also {
            SourceApi.setUp(flutterEngine.dartExecutor.binaryMessenger, it)
        }
        NotificationApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            NotificationApiImpl(this),
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        SourceApi.setUp(flutterEngine.dartExecutor.binaryMessenger, null)
        NotificationApi.setUp(flutterEngine.dartExecutor.binaryMessenger, null)
        sourceApi?.dispose()
        sourceApi = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
