package com.example.farmestates_ai_dashbaord

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationManagerCompat

/** One first-launch request, completed only after Android returns the choice. */
class AndroidNotificationPermission(private val activity: Activity) {
    companion object { const val REQUEST_CODE = 901 }
    private val waiting = mutableListOf<(Boolean) -> Unit>()
    private val prefs get() = activity.getSharedPreferences("message_notifications", Context.MODE_PRIVATE)

    fun request(complete: (Boolean) -> Unit) {
        if (waiting.isNotEmpty()) {
            waiting.add(complete)
            return
        }
        if (Build.VERSION.SDK_INT < 33 ||
            activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED ||
            prefs.getBoolean("asked", false)) {
            complete(enabled())
            return
        }
        waiting.add(complete)
        try {
            activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_CODE)
        } catch (_: Exception) {
            finish(false)
        }
    }

    fun onResult(requestCode: Int, grantResults: IntArray) {
        if (requestCode != REQUEST_CODE) return
        // Swiping away is not a choice; a future launch can offer it again.
        if (grantResults.isNotEmpty()) prefs.edit().putBoolean("asked", true).apply()
        finish(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED &&
            enabled())
    }

    fun dispose() = finish(false)

    private fun enabled() = (Build.VERSION.SDK_INT < 33 ||
        activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) &&
        NotificationManagerCompat.from(activity).areNotificationsEnabled()

    private fun finish(enabled: Boolean) {
        val callbacks = waiting.toList()
        waiting.clear()
        callbacks.forEach { it(enabled) }
    }
}
