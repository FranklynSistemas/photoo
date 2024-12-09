import android.annotation.SuppressLint
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.photoo/screen"
    private var wakeLock: PowerManager.WakeLock? = null

    @RequiresApi(Build.VERSION_CODES.M)
    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
                    releaseWakeLock()
                    result.success("Releasing wakeLock")
                }
                else -> result.notImplemented()
            }
        }
    }

    @SuppressLint("ScheduleExactAlarm")
    @RequiresApi(Build.VERSION_CODES.M)
    private fun scheduleScreenOnOff(onTime: Long?, offTime: Long?) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        Log.d("scheduleScreenOnOff", "Setting up Intent brad cast")
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
    fun keepScreenOn() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (wakeLock == null || !wakeLock!!.isHeld) {
            wakeLock =
                powerManager.newWakeLock(
                    PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                    "ScreenScheduler:WakeLock"
                )
            wakeLock?.acquire()
        }
    }

    // Method to release the WakeLock
    fun releaseWakeLock() {
        if (wakeLock != null && wakeLock!!.isHeld) {
            wakeLock?.release()
            wakeLock = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        releaseWakeLock()
    }
}

// BroadcastReceiver to turn on the screen
class ScreenOnReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("ScreenOnReceiver", "Keeping on screen")
        val activity = context as? MainActivity
        activity?.keepScreenOn()
    }
}

// BroadcastReceiver to turn off the screen
class ScreenOffReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("ScreenOffReceiver", "Releasing screen")
        val activity = context as? MainActivity
        activity?.releaseWakeLock()
    }
}