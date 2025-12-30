// File: android/app/src/main/kotlin/com/app/secureconnect/MainActivity.kt

package com.app.secureconnect

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
        private const val CHANNEL = "com.secureconnect/call_handler"
    }
    
    private var methodChannel: MethodChannel? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        
        Log.d(TAG, "✅ Flutter engine configured")
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "📱 MainActivity onCreate")
        
        handleIncomingCallIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "📲 MainActivity onNewIntent")
        setIntent(intent)
        
        handleIncomingCallIntent(intent)
    }
    
    private fun handleIncomingCallIntent(intent: Intent?) {
        try {
            if (intent != null) {
                val phoneNumber = intent.getStringExtra("incoming_call")
                val fromNative = intent.getBooleanExtra("from_native", false)
                
                if (phoneNumber != null && fromNative) {
                    Log.d(TAG, "📞 Call from native: $phoneNumber")
                    
                    // Native already showed basic screen, tell Flutter to update it
                    android.os.Handler(mainLooper).postDelayed({
                        notifyFlutterToUpdateCallScreen(phoneNumber)
                    }, 500)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error handling intent: ${e.message}", e)
        }
    }
    
    private fun notifyFlutterToUpdateCallScreen(phoneNumber: String) {
        try {
            methodChannel?.invokeMethod("handleIncomingCall", mapOf(
                "phoneNumber" to phoneNumber,
                "timestamp" to System.currentTimeMillis()
            ))
            
            Log.d(TAG, "✅ Notified Flutter to update call screen")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to notify Flutter: ${e.message}", e)
        }
    }
}