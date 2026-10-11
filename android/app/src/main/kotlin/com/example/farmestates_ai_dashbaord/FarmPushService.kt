package com.example.farmestates_ai_dashbaord

import android.content.Context
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
        if (!FarmNotifications.isRecipient(this, recipient) || foreground) return
        synchronized(FarmPushService::class.java) {
            val seen = delivered(this)
            if (event in seen) return
            val silent = data["silent"] == "true"
            if (!FarmNotifications.show(this, recipient, peer, data["title"] ?: "Farm Estates",
                    data["body"] ?: "Open Farm Estates to view the notification.", event,
                    message.sentTime.takeIf { it > 0 } ?: System.currentTimeMillis(), silent)) return
            // Bounded persistent deduplication also prevents a repeat from the Flutter poller.
            prefs.edit().putStringSet("delivered", (seen.takeLastSafe(199) + event).toSet()).apply()
        }
    }
    private fun Set<String>.takeLastSafe(count: Int) = toList().takeLast(count)
}
