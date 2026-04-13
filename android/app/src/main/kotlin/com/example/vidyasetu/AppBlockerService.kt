package com.example.vidyasetu

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.app.usage.UsageStatsManager
import android.app.usage.UsageEvents
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat

class AppBlockerService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var blockedPackages: List<String> = emptyList()
    private var isRunning = false
    private val CHECK_INTERVAL = 1000L // Check every second
    private val CHANNEL_ID = "focus_mode_blocker"
    private val NOTIFICATION_ID = 9999

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "START" -> {
                blockedPackages = intent.getStringArrayListExtra("blocked_packages") ?: emptyList()
                startForeground(NOTIFICATION_ID, buildNotification())
                isRunning = true
                startMonitoring()
            }
            "STOP" -> {
                isRunning = false
                handler.removeCallbacksAndMessages(null)
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Mode",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitoring blocked apps during focus mode"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🛡️ Focus Mode Active")
            .setContentText("${blockedPackages.size} apps blocked. Stay focused!")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun startMonitoring() {
        handler.post(object : Runnable {
            override fun run() {
                if (!isRunning) return
                checkForegroundApp()
                handler.postDelayed(this, CHECK_INTERVAL)
            }
        })
    }

    private fun checkForegroundApp() {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return

        val endTime = System.currentTimeMillis()
        val beginTime = endTime - 2000

        val usageEvents = usageStatsManager.queryEvents(beginTime, endTime)
        var foregroundPackage: String? = null

        while (usageEvents.hasNextEvent()) {
            val event = UsageEvents.Event()
            usageEvents.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                foregroundPackage = event.packageName
            }
        }

        if (foregroundPackage != null && blockedPackages.contains(foregroundPackage)) {
            // Blocked app detected! Bring VidyaSetu back to foreground
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            startActivity(intent)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
