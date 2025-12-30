// File: android/app/src/main/kotlin/com/app/secureconnect/PhoneStateReceiver.kt

package com.app.secureconnect

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

class PhoneStateReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "PhoneStateReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "📞 Broadcast received: ${intent.action}")
        
        try {
            if (intent.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
                val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
                val phoneNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
                
                Log.d(TAG, "📲 Phone state: $state, Number: $phoneNumber")
                
                when (state) {
                    TelephonyManager.EXTRA_STATE_RINGING -> {
                        if (!phoneNumber.isNullOrEmpty()) {
                            Log.d(TAG, "🔔 INCOMING CALL: $phoneNumber")
                            launchAppForCall(context, phoneNumber)
                        }
                    }
                    TelephonyManager.EXTRA_STATE_IDLE -> {
                        Log.d(TAG, "📴 Call ended")
                    }
                    TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                        Log.d(TAG, "📞 Call answered/outgoing")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error in PhoneStateReceiver: ${e.message}", e)
        }
    }
    
    private fun launchAppForCall(context: Context, phoneNumber: String) {
        try {
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                launchIntent.putExtra("incoming_call", phoneNumber)
                launchIntent.putExtra("from_native", true)
                context.startActivity(launchIntent)
                Log.d(TAG, "✅ App launched for call: $phoneNumber")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to launch app: ${e.message}", e)
        }
    }
}