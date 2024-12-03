package com.example.photoo

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.photoo/screen"
    private var wakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "scheduleScreenOnOff" -> {
                    val onTime = call.argument<Long>("onTime")
                    val offTime = call.argument<Long>("offTime")
                    scheduleScreenOnOff(onTime, offTime)
                    result.success("Scheduled")
                }
                "keepScreenOn" -> {
                    keepScreenOn()
                    result.success("Screen will stay on")
                }
                "releaseScreenOn" -> {
                    onDestroy();
                    result.success("Releasing wakeLock")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleScreenOnOff(onTime: Long?, offTime: Long?) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val onIntent = Intent(this, ScreenOnReceiver::class.java)
        val onPendingIntent =
                PendingIntent.getBroadcast(this, 0, onIntent, PendingIntent.FLAG_IMMUTABLE)
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, onTime!!, onPendingIntent)

        val offIntent = Intent(this, ScreenOffReceiver::class.java)
        val offPendingIntent =
                PendingIntent.getBroadcast(this, 1, offIntent, PendingIntent.FLAG_IMMUTABLE)
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, offTime!!, offPendingIntent)
    }

    // Method to keep the screen on indefinitely
    private fun keepScreenOn() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

        // Acquire a WakeLock to keep the screen on
        wakeLock =
                powerManager.newWakeLock(
                        PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                        "ScreenScheduler:WakeLock"
                )
        wakeLock?.acquire(10 * 60 * 1000L) // Keep screen on for 10 minutes (you can adjust this)
    }

    // Make sure to release the wake lock when not needed
    override fun onDestroy() {
        super.onDestroy()
        wakeLock?.release() // Release wake lock when activity is destroyed to avoid leaks
    }
}
