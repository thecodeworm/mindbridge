package com.mindbridge.mindbridge

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth:
// with a plain FlutterActivity the biometric prompt cannot be shown, so the
// app lock could never be enabled on Android.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Lets Dart turn FLAG_SECURE on while the app lock is enabled, which
        // blanks the recent-apps thumbnail and blocks screenshots of journal
        // entries. Off when the lock is off, so ordinary users can still
        // screenshot their own mood chart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mindbridge.mindbridge/privacy")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val secure = call.argument<Boolean>("secure") ?: false
                        if (secure) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
