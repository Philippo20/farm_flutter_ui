package com.example.farmestates_ai_dashbaord

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/** Data-only pushes allow recipient checks before anything reaches the lock screen. */
class FarmPushService : FirebaseMessagingService() {
    companion object {
        @Volatile var foreground = false
        fun delivered(context: Context): Set<String> = context.getSharedPreferences("farm_push", Context.MODE_PRIVATE)
            .getStringSet("delivered", emptySet())?.toSet() ?: emptySet()
    }
    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        val prefs = getSharedPreferences("farm_push", MODE_PRIVATE)
        val recipient = data["recipientId"] ?: return
        val event = data["eventId"] ?: return
        val peer = data["peerId"] ?: return
        if (recipient != prefs.getString("recipient", null) || foreground) return
        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        synchronized(FarmPushService::class.java) {
            val seen = delivered(this)
            if (event in seen) return
            val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            val silent = data["silent"] == "true"
            val channel = if (silent) "farm_updates_silent" else if (peer.startsWith("__inbox__:")) "farm_updates" else "team_messages"
            if (Build.VERSION.SDK_INT >= 26) {
                manager.createNotificationChannel(NotificationChannel(channel,
                    if (silent) "Silent farm updates" else if (channel == "team_messages") "Team messages" else "Farm updates",
                    if (silent) NotificationManager.IMPORTANCE_LOW else NotificationManager.IMPORTANCE_HIGH
                ).apply { if (silent) { setSound(null, null); enableVibration(false) } })
            }
            val tap = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                action = "message:$recipient:$peer"
                putExtra("peerId", peer); putExtra("recipientId", recipient)
            }
            val pending = PendingIntent.getActivity(this, peer.hashCode(), tap,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val builder = if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, channel) else Notification.Builder(this)
            manager.notify(peer, 0, builder.setSmallIcon(R.drawable.ic_message_notification)
                .setContentTitle(if (channel == "team_messages") "New team message" else "Farm Estates update")
                .setContentText("Open Farm Estates to view the notification.")
                .setVisibility(Notification.VISIBILITY_PRIVATE).setAutoCancel(true).setContentIntent(pending).build())
            // Bounded persistent deduplication also prevents a repeat from the Flutter poller.
            prefs.edit().putStringSet("delivered", (seen.takeLastSafe(199) + event).toSet()).apply()
        }
    }
    private fun Set<String>.takeLastSafe(count: Int) = toList().takeLast(count)
}
