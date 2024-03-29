package com.clevertap.clevertap_signedcall_flutter.plugin

import android.content.Context
import com.clevertap.clevertap_signedcall_flutter.Constants
import com.clevertap.clevertap_signedcall_flutter.handlers.CallEventStreamHandler
import com.clevertap.clevertap_signedcall_flutter.handlers.MissedCallActionEventStreamHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class SignedCallFlutterPluginRegistrant : FlutterPlugin {
    /**
     * The MethodChannel that will used to establish the communication between Flutter and Android
     *
     * This local reference serves to register the plugin with the Flutter Engine and unregister it
     * when the Flutter Engine is detached from the Activity
     */
    private var methodChannel: MethodChannel? = null
    private lateinit var methodCallHandler: MethodChannel.MethodCallHandler

    /**
     * The EventChannel that will used to create pipeline of a data stream from Android to Flutter
     *
     * This local reference serves to create the pipeline and set the streamHandler
     *
     */
    private var callEventChannel: EventChannel? = null
    private var missedCallActionClickEventChannel: EventChannel? = null

    var context: Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        setupPlugin(flutterPluginBinding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        callEventChannel?.setStreamHandler(null)
        callEventChannel = null
        missedCallActionClickEventChannel?.setStreamHandler(null)
        missedCallActionClickEventChannel = null
    }

    private fun setupPlugin(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "${Constants.CHANNEL_NAME}/methods")
        methodCallHandler = SignedCallFlutterMethodCallHandler(context, methodChannel)
        methodChannel!!.setMethodCallHandler(methodCallHandler)

        callEventChannel =
            EventChannel(binding.binaryMessenger, "${Constants.CHANNEL_NAME}/events/call_event")
        missedCallActionClickEventChannel = EventChannel(
            binding.binaryMessenger,
            "${Constants.CHANNEL_NAME}/events/missed_call_action_click"
        )

        callEventChannel?.setStreamHandler(CallEventStreamHandler)
        missedCallActionClickEventChannel?.setStreamHandler(MissedCallActionEventStreamHandler)
    }
}