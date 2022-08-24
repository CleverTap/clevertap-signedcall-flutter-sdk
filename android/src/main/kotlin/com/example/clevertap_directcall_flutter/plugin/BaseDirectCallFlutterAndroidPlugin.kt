package com.example.clevertap_directcall_flutter.plugin

import androidx.annotation.NonNull
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Defines all the operations that needs to be performed via Direct Call Android SDK
 */
interface BaseDirectCallFlutterAndroidPlugin {
    /**
     * Defines implementation to initialize the Direct Call Android SDK
     */
    fun initDirectCallSdk(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result)

    /**
     * Defines implementation to initiate a VoIP call
     */
    fun initiateVoipCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result)

    /**
     * Defines implementation to logout the Direct Call SDK session
     */
    fun logout()
}