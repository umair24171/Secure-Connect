// File: android/app/src/main/kotlin/com/app/secureconnect/BootReceiver.kt

package com.app.secureconnect

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Ensures PhoneStateReceiver stays active after device reboot
 * No special initialization needed - Android automatically re-registers receivers
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "🔄 Boot event received: ${intent.action}")
        
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d(TAG, "✅ PhoneStateReceiver will auto-activate")
                // Android automatically re-enables our PhoneStateReceiver
                // No manual initialization needed!
            }
        }
    }
}