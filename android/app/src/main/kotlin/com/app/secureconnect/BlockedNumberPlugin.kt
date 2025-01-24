package com.app.secureconnect

import android.content.ContentValues
import android.os.Build
import android.provider.BlockedNumberContract
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import android.content.Context

class BlockedNumberPlugin : FlutterPlugin {
    private lateinit var channel: MethodChannel
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(
            binding.binaryMessenger, 
            "com.app.secureconnect.contactblocker"
        )
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "blockNumber" -> {
                    val number = call.argument<String>("phoneNumber")
                    number?.let {
                        val blocked = blockNumberNatively(it)
                        result.success(blocked)
                    } ?: result.error("INVALID_NUMBER", "Number required", null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    private fun blockNumberNatively(phoneNumber: String): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                val values = ContentValues().apply {
                    put(BlockedNumberContract.BlockedNumbers.COLUMN_ORIGINAL_NUMBER, phoneNumber)
                }
                context?.contentResolver?.insert(BlockedNumberContract.BlockedNumbers.CONTENT_URI, values) != null
            } catch (e: Exception) {
                false
            }
        } else false
    }
}