package com.example.clevertap_signedcall_flutter.isolate

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.clevertap.android.signedcall.models.SCCallStatusDetails
import com.example.clevertap_signedcall_flutter.SCAppContextHolder
import com.example.clevertap_signedcall_flutter.extensions.toMap
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterShellArgs
import io.flutter.embedding.engine.dart.DartExecutor.DartCallback
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.view.FlutterCallbackInformation
import java.util.concurrent.atomic.AtomicBoolean

/**
 * A background executor which handles initializing a background isolate running a
 * callback dispatcher, used to invoke Dart callbacks in background/killed state.
 */
class CleverTapBackgroundIsolateExecutor(private val callStatus: SCCallStatusDetails) : MethodCallHandler {

    companion object {
        private const val TAG = "CTBGIsolateExecutor"
    }

    private val context: Context = SCAppContextHolder.getApplicationContext()!!
    private val isCallbackDispatcherReady = AtomicBoolean(false)
    private var backgroundFlutterEngine: FlutterEngine? = null
    private lateinit var backgroundChannel: MethodChannel

    /**
     * Returns true if the onKilledStateNotificationClicked handler is registered in Dart.
     */
    fun isDartBackgroundHandlerRegistered(): Boolean {
        return getPluginCallbackHandle() != 0L
    }

    /**
     * Returns true when the background isolate is not started to handle background messages.
     */
    private fun isNotRunning(): Boolean {
        return !isCallbackDispatcherReady.get()
    }

    /**
     * Starts running a background Dart isolate within a new [FlutterEngine] using a previously
     * used entrypoint.
     */
    fun startBackgroundIsolate() {
        if (isNotRunning()) {
            Log.i(TAG, "startBackgroundIsolate!")
            val callbackHandle = getPluginCallbackHandle()
            if (callbackHandle != 0L) {
                startBackgroundIsolate(callbackHandle, null)
            }
        } else {
            executeDartCallbackInBackgroundIsolate(callStatus)
        }
    }

    /**
     * Starts running a background Dart isolate within a new [FlutterEngine] using a previously
     * used entrypoint.
     *
     * Preconditions:
     * The given [callbackHandle] must correspond to a registered Dart callback. If the
     * handle does not resolve to a Dart callback then this method does nothing.
     */
    private fun startBackgroundIsolate(callbackHandle: Long, shellArgs: FlutterShellArgs?) {
        if (backgroundFlutterEngine != null) {
            Log.e(TAG, "Background isolate already started.")
            return
        }

        val loader = FlutterLoader()
        val mainHandler = Handler(Looper.getMainLooper())
        val myRunnable = Runnable {
            // startInitialization() must be called on the main thread.
            loader.startInitialization(context)

            loader.ensureInitializationCompleteAsync(context, null, mainHandler) {
                val appBundlePath = loader.findAppBundlePath()
                val assets = context.assets
                if (isNotRunning()) {
                    if (shellArgs != null) {
                        Log.i(
                            TAG, "Creating background FlutterEngine instance, with args: ${
                                shellArgs.toArray().contentToString()
                            }"
                        )
                        backgroundFlutterEngine = FlutterEngine(context, shellArgs.toArray())
                    } else {
                        Log.i(TAG, "Creating background FlutterEngine instance.")
                        backgroundFlutterEngine = FlutterEngine(context)
                    }
                    // We need to create an instance of `FlutterEngine` before looking up the
                    // callback. If we don't, the callback cache won't be initialized and the
                    // lookup will fail.
                    val flutterCallback = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
                    val executor = backgroundFlutterEngine!!.dartExecutor
                    initializeMethodChannel(executor)
                    val dartCallback = DartCallback(assets, appBundlePath, flutterCallback)
                    executor.executeDartCallback(dartCallback)
                }
            }
        }
        mainHandler.post(myRunnable)
    }

    private fun initializeMethodChannel(isolate: BinaryMessenger) {
        backgroundChannel = MethodChannel(isolate, "clevertap_plugin/background_isolate_channel")
        backgroundChannel.setMethodCallHandler(this)
    }

    /**
     * Executes the desired Dart callback in a background Dart isolate.
     *
     * The given [callStatus] should contain a [Long] extra called
     * "userCallbackHandle", which corresponds to a callback registered with the Dart VM.
     */
    private fun executeDartCallbackInBackgroundIsolate(callStatus: SCCallStatusDetails) {
        if (backgroundFlutterEngine == null) {
            Log.i(
                TAG,
                "A background message could not be handled in Dart as no onBackgroundMessage handler has been registered."
            )
            return
        }

        try {
            Log.i(TAG, "method call for onCallEventInKilledState")

            //val notificationClickedPayload = CleverTapTypeUtils.MapUtil.toJSONObject(messageMap)
            backgroundChannel.invokeMethod(
                "onCallEventInKilledState", mapOf(
                    "userCallbackHandle" to getUserCallbackHandle(),
                    "payload" to callStatus.toMap()
                )
            )
            Log.i(TAG, "method call for onCallEventInKilledState successful: " + callStatus.toMap())

        } catch (e: Exception) {
            Log.e(TAG, "Failed to invoke the Dart callback. ${e.localizedMessage}")
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val method = call.method
        try {
            when (method) {
                "CleverTapCallbackDispatcher#initialized" -> {
                    onInitialized()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("error", "CleverTapBackgroundIsolateExecutor's error: ${e.message}", null)
        }
    }

    /**
     * Called once the Dart isolate(i.e. callbackDispatcher) has finished initializing.
     */
    private fun onInitialized() {
        Log.i(TAG, "CleverTapCallbackDispatcher is initialized to receive a user's DartCallback request!")
        isCallbackDispatcherReady.set(true)
        executeDartCallbackInBackgroundIsolate(callStatus)
    }

    /**
     * Get the users registered Dart callback handle for background messaging. Returns 0 if not set.
     */
    private fun getUserCallbackHandle(): Long {
        return IsolateHandlePreferences.getUserCallbackHandle(context)
    }

    /**
     * Get the registered Dart callback handle for the messaging plugin. Returns 0 if not set.
     */
    private fun getPluginCallbackHandle(): Long {
        return IsolateHandlePreferences.getCallbackDispatcherHandle(context)
    }
}
