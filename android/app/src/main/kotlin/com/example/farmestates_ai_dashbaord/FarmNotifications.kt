package com.example.farmestates_ai_dashbaord

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.Person
import androidx.core.app.RemoteInput
import org.json.JSONArray
import org.json.JSONObject

/** Shared rendering for foreground polls, background FCM and direct-reply results. */
object FarmNotifications {
    const val REPLY = "farmestates.notification.REPLY"
    const val RETRY = "farmestates.notification.RETRY"
    const val REPLY_TEXT = "reply_text"
    private fun prefs(context: Context) = context.getSharedPreferences("farm_notifications", Context.MODE_PRIVATE)
    private fun key(recipient: String, peer: String) = "$recipient:$peer"

    fun isRecipient(context: Context, recipient: String): Boolean {
        val session = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return recipient.isNotBlank() &&
            context.getSharedPreferences("farm_push", Context.MODE_PRIVATE).getString("recipient", null) == recipient &&
            session.getBoolean("flutter.is_logged_in", false) && session.getString("flutter.user_id", null) == recipient
    }

    @Synchronized
    fun incomingIds(context: Context, recipient: String, peer: String): JSONArray {
        val ids = JSONArray()
        val history = load(context, recipient, peer).optJSONArray("history") ?: return ids
        for (i in 0 until history.length()) {
            val row = history.getJSONObject(i)
            val id = row.optString("id").removePrefix("message:")
            if (!row.optBoolean("outgoing") && id.matches(Regex("[A-Za-z0-9_-]{1,36}"))) ids.put(id)
        }
        return ids
    }

    @Synchronized
    fun clear(context: Context, peer: String? = null) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (peer == null) {
            manager.cancelAll()
            prefs(context).edit().clear().apply()
        } else {
            manager.cancel(peer, 0)
            val recipient = context.getSharedPreferences("farm_push", Context.MODE_PRIVATE).getString("recipient", "") ?: ""
            prefs(context).edit().remove(key(recipient, peer)).apply()
        }
    }

    @Synchronized
    fun show(context: Context, recipient: String, peer: String, title: String, body: String,
             messageId: String = "", timestamp: Long = System.currentTimeMillis(), silent: Boolean = false): Boolean {
        if (!isRecipient(context, recipient) || peer.isBlank()) return false
        val state = load(context, recipient, peer)
        state.put("title", title.ifBlank { if (peer.startsWith("__inbox__:")) "Farm Estates update" else "Team member" })
            .put("body", body.ifBlank { "Open Farm Estates to view the notification." }).put("silent", silent)
        if (!peer.startsWith("__inbox__:")) {
            val history = state.optJSONArray("history") ?: JSONArray()
            val id = messageId.ifBlank { "$timestamp:$body" }
            if ((0 until history.length()).none { history.getJSONObject(it).optString("id") == id }) {
                history.put(JSONObject().put("id", id).put("text", body).put("time", timestamp).put("outgoing", false))
            }
            state.put("history", bounded(history))
        }
        save(context, recipient, peer, state)
        return render(context, recipient, peer, state)
    }

    @Synchronized
    fun replyState(context: Context, recipient: String, peer: String, text: String, requestId: String,
                   status: String, sent: Boolean = false, retry: Boolean = false) {
        if (!isRecipient(context, recipient)) return
        // An opened/read conversation must not be resurrected by a late worker.
        if (!prefs(context).contains(key(recipient, peer))) return
        val state = load(context, recipient, peer)
        if (sent) {
            val history = state.optJSONArray("history") ?: JSONArray()
            if ((0 until history.length()).none { history.getJSONObject(it).optString("id") == requestId }) {
                history.put(JSONObject().put("id", requestId).put("text", text)
                    .put("time", System.currentTimeMillis()).put("outgoing", true))
            }
            state.put("history", bounded(history))
            save(context, recipient, peer, state)
        }
        render(context, recipient, peer, state, text, requestId, status, retry)
    }

    private fun load(context: Context, recipient: String, peer: String): JSONObject =
        runCatching { JSONObject(prefs(context).getString(key(recipient, peer), "{}") ?: "{}") }.getOrDefault(JSONObject())

    private fun bounded(history: JSONArray): JSONArray {
        val result = JSONArray()
        for (i in maxOf(0, history.length() - 12) until history.length()) result.put(history.get(i))
        return result
    }

    private fun save(context: Context, recipient: String, peer: String, state: JSONObject) {
        val storage = prefs(context)
        val entry = key(recipient, peer)
        val editor = storage.edit().putString(entry, state.toString())
        // Bound persisted previews as well as the history in each conversation.
        storage.all.keys.filter { it != entry }.drop(49).forEach { editor.remove(it) }
        editor.apply()
    }

    private fun render(context: Context, recipient: String, peer: String, state: JSONObject,
                       reply: String? = null, requestId: String? = null, status: String? = null,
                       retry: Boolean = false): Boolean {
        if (Build.VERSION.SDK_INT >= 33 && context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return false
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val chat = !peer.startsWith("__inbox__:")
        val silent = state.optBoolean("silent")
        val channel = if (silent) "farm_updates_silent" else if (chat) "team_messages" else "farm_updates"
        if (Build.VERSION.SDK_INT >= 26) {
            manager.createNotificationChannel(NotificationChannel(channel,
                if (silent) "Silent farm updates" else if (chat) "Team messages" else "Farm updates",
                if (silent) NotificationManager.IMPORTANCE_LOW else if (chat) NotificationManager.IMPORTANCE_HIGH else NotificationManager.IMPORTANCE_DEFAULT
            ).apply { if (silent) { setSound(null, null); enableVibration(false) } })
        }
        val title = state.optString("title", "Farm Estates")
        val body = state.optString("body", "Open Farm Estates to view the notification.")
        val tap = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            data = Uri.parse("farmestates-notification://open/${Uri.encode(recipient)}/${Uri.encode(peer)}")
            putExtra("peerId", peer); putExtra("recipientId", recipient)
        }
        val pending = PendingIntent.getActivity(context, 0, tap, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder = NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_message_notification).setContentTitle(title).setContentText(body)
            .setCategory(if (chat) NotificationCompat.CATEGORY_MESSAGE else NotificationCompat.CATEGORY_EVENT)
            .setPriority(if (silent) NotificationCompat.PRIORITY_LOW else NotificationCompat.PRIORITY_HIGH)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE).setAutoCancel(true).setContentIntent(pending)
            .setOnlyAlertOnce(status != null).setSubText(status)
            .setPublicVersion(NotificationCompat.Builder(context, channel).setSmallIcon(R.drawable.ic_message_notification)
                .setContentTitle("Farm Estates").setContentText(if (chat) "New team message" else "New farm update").build())
        if (chat) {
            val sender = Person.Builder().setName(title).setKey(peer).build()
            val style = NotificationCompat.MessagingStyle(Person.Builder().setName("You").setKey(recipient).build())
            val history = state.optJSONArray("history") ?: JSONArray()
            for (i in 0 until history.length()) {
                val item = history.getJSONObject(i)
                style.addMessage(item.optString("text"), item.optLong("time"), if (item.optBoolean("outgoing")) null else sender)
            }
            builder.setStyle(style)
            if (Build.VERSION.SDK_INT >= 24) {
                val replyIntent = Intent(context, NotificationReplyReceiver::class.java).apply {
                    action = REPLY
                    data = Uri.parse("farmestates-notification://reply/${Uri.encode(recipient)}/${Uri.encode(peer)}")
                    putExtra("recipientId", recipient); putExtra("peerId", peer)
                    putExtra("generation", context.getSharedPreferences("farm_push", Context.MODE_PRIVATE).getLong("generation", 0))
                }
                val flags = PendingIntent.FLAG_UPDATE_CURRENT or if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0
                val replyPending = PendingIntent.getBroadcast(context, 0, replyIntent, flags)
                val action = NotificationCompat.Action.Builder(android.R.drawable.ic_menu_send, "Reply", replyPending)
                    .addRemoteInput(RemoteInput.Builder(REPLY_TEXT).setLabel("Write a reply").build())
                    .setSemanticAction(NotificationCompat.Action.SEMANTIC_ACTION_REPLY).setShowsUserInterface(false)
                    .setAuthenticationRequired(true).build()
                builder.addAction(action)
                if (reply != null) builder.setRemoteInputHistory(arrayOf(reply))
            }
            if (retry && reply != null && requestId != null) {
                val retryIntent = Intent(context, NotificationReplyReceiver::class.java).apply {
                    action = RETRY
                    data = Uri.parse("farmestates-notification://retry/$requestId")
                    putExtra("recipientId", recipient); putExtra("peerId", peer)
                    putExtra("text", reply); putExtra("requestId", requestId)
                    putExtra("generation", context.getSharedPreferences("farm_push", Context.MODE_PRIVATE).getLong("generation", 0))
                }
                builder.addAction(NotificationCompat.Action.Builder(android.R.drawable.ic_popup_sync, "Retry",
                    PendingIntent.getBroadcast(context, 0, retryIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
                    .setShowsUserInterface(false).setAuthenticationRequired(true).build())
            }
        } else builder.setStyle(NotificationCompat.BigTextStyle().bigText(body))
        manager.notify(peer, 0, builder.build())
        return true
    }
}
