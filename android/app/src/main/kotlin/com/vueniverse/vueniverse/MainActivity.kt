package com.vueniverse.vueniverse

import com.vueniverse.vueniverse.platform.PlatformSecurityApi
import com.vueniverse.vueniverse.platform.PlatformSecurityApiImpl
import com.vueniverse.vueniverse.sources.SourceApi
import com.vueniverse.vueniverse.sources.SourceApiImpl
import com.vueniverse.vueniverse.notifications.NotificationApi
import com.vueniverse.vueniverse.notifications.NotificationApiImpl
import com.vueniverse.vueniverse.medgemma.MedGemmaRuntime
import com.vueniverse.vueniverse.modeldownload.ModelDownloadApi
import com.vueniverse.vueniverse.modeldownload.ModelDownloadApiImpl
import com.vueniverse.vueniverse.modelruntime.ModelRuntimeApi
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterFragmentActivity() {
    private var sourceApi: SourceApiImpl? = null
    private var modelRuntime: MedGemmaRuntime? = null
    private var notificationApi: NotificationApiImpl? = null
    private var modelDownloadApi: ModelDownloadApiImpl? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PlatformSecurityApi.setUp(
            flutterEngine.dartExecutor.binaryMessenger,
            PlatformSecurityApiImpl(applicationContext),
        )
        sourceApi = SourceApiImpl(this).also {
            SourceApi.setUp(flutterEngine.dartExecutor.binaryMessenger, it)
        }
        notificationApi = NotificationApiImpl(this).also {
            NotificationApi.setUp(flutterEngine.dartExecutor.binaryMessenger, it)
        }
        modelRuntime = MedGemmaRuntime(filesDir).also {
            ModelRuntimeApi.setUp(flutterEngine.dartExecutor.binaryMessenger, it)
        }
        modelDownloadApi = ModelDownloadApiImpl(applicationContext).also {
            ModelDownloadApi.setUp(flutterEngine.dartExecutor.binaryMessenger, it)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        notificationApi?.onRequestPermissionsResult(requestCode, grantResults)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        SourceApi.setUp(flutterEngine.dartExecutor.binaryMessenger, null)
        NotificationApi.setUp(flutterEngine.dartExecutor.binaryMessenger, null)
        ModelRuntimeApi.setUp(flutterEngine.dartExecutor.binaryMessenger, null)
        ModelDownloadApi.setUp(flutterEngine.dartExecutor.binaryMessenger, null)
        sourceApi?.dispose()
        sourceApi = null
        notificationApi?.dispose()
        notificationApi = null
        modelRuntime?.close()
        modelRuntime = null
        modelDownloadApi?.dispose()
        modelDownloadApi = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
