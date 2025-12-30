// File: android/app/src/main/kotlin/com/app/secureconnect/CallHandlerWorker.kt

package com.app.secureconnect

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * WorkManager worker for background heartbeat
 * (Not used for call handling - native BroadcastReceiver handles that)
 */
class CallHandlerWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {
    
    companion object {
        private const val TAG = "CallHandlerWorker"
    }
    
    override fun doWork(): Result {
        Log.d(TAG, "✅ Background heartbeat")
        return Result.success()
    }
}