package com.example.photoo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

class ScreenOffReceiverOld : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLockTag = "ScreenScheduler:WakeLock"
        var wakeLock: PowerManager.WakeLock? = null

        try {
            // Acquire the WakeLock
            wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, wakeLockTag)
            wakeLock.acquire(10 * 60 * 1000L /* 10 minutes */)

            Log.d("ScreenOffReceiver", "WakeLock acquired for screen off.")

            // Perform any required logic for screen off
            // For example, turning off the screen programmatically

        } catch (e: Exception) {
            Log.e("ScreenOffReceiver", "Error during WakeLock handling: ${e.message}", e)
        } finally {
            // Ensure WakeLock is released properly
            if (wakeLock != null && wakeLock.isHeld) {
                wakeLock.release()
                Log.d("ScreenOffReceiver", "WakeLock released.")
            } else {
                Log.w("ScreenOffReceiver", "WakeLock was not held, so it could not be released.")
            }
        }
    }
}