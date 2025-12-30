package com.app.secureconnect

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.util.Log

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        deleteOldChannels()
        createNotificationChannels()
    }
    
    private fun deleteOldChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            try {
                notificationManager.deleteNotificationChannel("Incoming Call")
                notificationManager.deleteNotificationChannel("Missed Call")
                notificationManager.deleteNotificationChannel("com.hiennv.flutter_callkit_incoming.incoming_call")
                notificationManager.deleteNotificationChannel("com.hiennv.flutter_callkit_incoming.missed_call")
                Log.d("MyApplication", "Deleted old notification channels")
            } catch (e: Exception) {
                Log.e("MyApplication", "Error deleting channels: ${e.message}")
            }
        }
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // 🔥 Incoming call channel - NO SOUND (use system ringtone only)
            val incomingChannel = NotificationChannel(
                "incoming_call_channel",
                "SecureConnect",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Incoming call notifications"
                // 🔥 Disable notification sound - let system handle ringtone
                setSound(null, null)
                enableVibration(false)  // Let system handle vibration too
                setBypassDnd(true)
                setShowBadge(false)
            }
            
            // Missed call channel
            val missedChannel = NotificationChannel(
                "missed_call_channel",
                "Missed Calls",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Missed call notifications"
                setSound(null, null)
            }
            
            notificationManager.createNotificationChannel(incomingChannel)
            notificationManager.createNotificationChannel(missedChannel)
            
            Log.d("MyApplication", "✅ Created silent notification channels")
        }
    }
}