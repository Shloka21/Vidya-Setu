package com.example.vidyasetu

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class AppBlockerAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AppBlockerAccess"
        var isRunning = false
        var blockedPackages: List<String> = emptyList()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (!isRunning || blockedPackages.isEmpty()) return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            if (blockedPackages.contains(packageName) && packageName != "com.example.vidyasetu") {
                Log.d(TAG, "Blocking app: $packageName")
                blockApp()
            }
        }
    }

    private fun blockApp() {
        // Launch VidyaSetu to the /focusBlocked route
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        intent?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            // We can pass data to tell the app to show the blocked screen
            putExtra("route", "/focusBlocked")
        }
        startActivity(intent)
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service Internupted")
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Service Connected")
    }
}
