package com.bnd.bnd_lg360

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.bnd.bnd_lg360/network"
    private lateinit var cameraNetworkManager: CameraNetworkManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        cameraNetworkManager = CameraNetworkManager(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "bindToCameraWifi" -> {
                    cameraNetworkManager.bindToCameraWifi(
                        onBoundSuccess = {
                            runOnUiThread { 
                                result.success(true) 
                            }
                        },
                        onError = { error ->
                            runOnUiThread { 
                                result.error("NETWORK_ERROR", error, null) 
                            }
                        }
                    )
                }
                "releaseNetwork" -> {
                    cameraNetworkManager.unbind()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        if (::cameraNetworkManager.isInitialized) {
            cameraNetworkManager.unbind()
        }
        super.onDestroy()
    }
}
